import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../models/cash_flow.dart';

class CashFlowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate and update daily cash flow
  Future<CashFlow> calculateDailyCashFlow(String date) async {
    try {
      final startOfDay = DateTime.parse('$date 00:00:00');
      final endOfDay = DateTime.parse('$date 23:59:59');

      // Get previous day's closing cash
      final previousDate = startOfDay.subtract(const Duration(days: 1));
      final previousDateStr = previousDate.toString().split(' ')[0];
      final previousCashFlow = await getCashFlow(previousDateStr);
      
      final openingCash = previousCashFlow?.cashInHand ?? Decimal.zero;

      // Calculate total IN
      Decimal totalIn = Decimal.zero;
      
      // Exchange SELL transactions (we receive MYR)
      final exchangeSellSnapshot = await _firestore
          .collection('exchange_transactions')
          .where('mode', isEqualTo: 'sell')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      for (final doc in exchangeSellSnapshot.docs) {
        final data = doc.data();
        totalIn += Decimal.parse(data['myrAmount'].toString());
      }

      // Tour charge amounts (for cleared tours)
      final toursSnapshot = await _firestore
          .collection('tour_transactions')
          .where('status', isEqualTo: 'clear')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      for (final doc in toursSnapshot.docs) {
        final data = doc.data();
        totalIn += Decimal.parse(data['chargeAmount'].toString());
      }

      // Calculate total OUT
      Decimal totalOut = Decimal.zero;
      
      // Exchange BUY transactions (we pay MYR)
      final exchangeBuySnapshot = await _firestore
          .collection('exchange_transactions')
          .where('mode', isEqualTo: 'buy')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      for (final doc in exchangeBuySnapshot.docs) {
        final data = doc.data();
        totalOut += Decimal.parse(data['myrAmount'].toString());
      }

      // Paid remittances (we pay MYR)
      final remittanceSnapshot = await _firestore
          .collection('remittance_transactions')
          .where('status', isEqualTo: 'paid')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      for (final doc in remittanceSnapshot.docs) {
        final data = doc.data();
        totalOut += Decimal.parse(data['myrAmount'].toString());
      }

      // Calculate closing cash (before bank in)
      final closingCash = openingCash + totalIn - totalOut;

      // Get bank in amount for the day
      final existingCashFlow = await getCashFlow(date);
      final bankInAmount = existingCashFlow?.bankInAmount ?? Decimal.zero;
      final cashInHand = closingCash - bankInAmount;

      // Calculate profit breakdown
      final profitBreakdown = await _calculateProfitBreakdown(
        startOfDay,
        endOfDay,
      );

      final netProfit = profitBreakdown.total;

      // Create/update cash flow record
      final cashFlow = CashFlow(
        date: date,
        openingCash: openingCash,
        totalIn: totalIn,
        totalOut: totalOut,
        closingCash: closingCash,
        cashInHand: cashInHand,
        bankInAmount: bankInAmount,
        netProfit: netProfit,
        profitBreakdown: profitBreakdown,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('cash_flow')
          .doc('daily_$date')
          .set(cashFlow.toFirestore());

      return cashFlow;
    } catch (e) {
      throw Exception('Failed to calculate cash flow: $e');
    }
  }

  /// Calculate profit breakdown for a period
  Future<ProfitBreakdown> _calculateProfitBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    Decimal exchangeProfit = Decimal.zero;
    Decimal remittanceFees = Decimal.zero;
    Decimal tourProfit = Decimal.zero;

    // Exchange profit from daily closings
    final closingsSnapshot = await _firestore
        .collection('daily_closings')
        .where('soldTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('soldTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    
    for (final doc in closingsSnapshot.docs) {
      final data = doc.data();
      exchangeProfit += Decimal.parse(data['profit'].toString());
    }

    // Remittance fees
    final remittanceSnapshot = await _firestore
        .collection('remittance_transactions')
        .where('status', isEqualTo: 'paid')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    
    for (final doc in remittanceSnapshot.docs) {
      final data = doc.data();
      remittanceFees += Decimal.parse(data['feeAmount']?.toString() ?? '0');
    }

    // Tour profit (ONLY profitAmount, NOT chargeAmount)
    final toursSnapshot = await _firestore
        .collection('tour_transactions')
        .where('status', isEqualTo: 'clear')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    
    for (final doc in toursSnapshot.docs) {
      final data = doc.data();
      tourProfit += Decimal.parse(data['profitAmount'].toString());
    }

    return ProfitBreakdown(
      exchangeProfit: exchangeProfit,
      remittanceFees: remittanceFees,
      tourProfit: tourProfit,
    );
  }

  /// Record bank in (money moved from drawer to bank)
  Future<void> recordBankIn({
    required String date,
    required Decimal amount,
  }) async {
    try {
      // Get current cash flow
      final cashFlow = await getCashFlow(date);
      
      if (cashFlow == null) {
        throw Exception('Cash flow record not found for $date');
      }

      final currentBankIn = cashFlow.bankInAmount;
      final newBankIn = currentBankIn + amount;
      final newCashInHand = cashFlow.closingCash - newBankIn;

      if (newCashInHand < Decimal.zero) {
        throw Exception('Insufficient cash in hand');
      }

      await _firestore.collection('cash_flow').doc('daily_$date').update({
        'bankInAmount': newBankIn.toDouble(),
        'cashInHand': newCashInHand.toDouble(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to record bank in: $e');
    }
  }

  /// Get cash flow for a specific date
  Future<CashFlow?> getCashFlow(String date) async {
    try {
      final doc = await _firestore
          .collection('cash_flow')
          .doc('daily_$date')
          .get();
      
      if (doc.exists) {
        return CashFlow.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get cash flow: $e');
    }
  }

  /// Get cash flow stream for a date
  Stream<CashFlow?> getCashFlowStream(String date) {
    return _firestore
        .collection('cash_flow')
        .doc('daily_$date')
        .snapshots()
        .map((doc) => doc.exists ? CashFlow.fromFirestore(doc) : null);
  }

  /// Get cash flow history
  Stream<List<CashFlow>> getCashFlowHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection('cash_flow');

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: startDate.toString().split(' ')[0]);
    }

    if (endDate != null) {
      query = query.where('date',
          isLessThanOrEqualTo: endDate.toString().split(' ')[0]);
    }

    return query
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CashFlow.fromFirestore(doc))
            .toList());
  }

  /// Get current cash in hand (today's cash flow)
  Future<Decimal> getCurrentCashInHand() async {
    final today = DateTime.now().toString().split(' ')[0];
    final cashFlow = await getCashFlow(today);
    return cashFlow?.cashInHand ?? Decimal.zero;
  }
}
