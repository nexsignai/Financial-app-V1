import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../models/exchange_transaction.dart';
import '../models/daily_closing.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate MYR amount from foreign amount
  /// mode: 'buy' or 'sell'
  Decimal calculateMYRFromForeign({
    required Decimal foreignAmount,
    required Decimal rate,
    required ExchangeMode mode,
  }) {
    // Buy mode: We give MYR, get foreign
    // Sell mode: We receive MYR, give foreign
    return foreignAmount * rate;
  }

  /// Calculate foreign amount from MYR
  Decimal calculateForeignFromMYR({
    required Decimal myrAmount,
    required Decimal rate,
    required ExchangeMode mode,
  }) {
    return (myrAmount / rate).toDecimal();
  }

  /// Create a new exchange transaction
  Future<String> createTransaction({
    required String currency,
    required ExchangeMode mode,
    required Decimal foreignAmount,
    required Decimal myrAmount,
    required Decimal rateUsed,
    required String adminId,
    String? notes,
  }) async {
    try {
      // Generate transaction ID
      final timestamp = DateTime.now();
      final docRef = await _firestore.collection('exchange_transactions').add({
        'timestamp': Timestamp.fromDate(timestamp),
        'currency': currency,
        'mode': mode == ExchangeMode.buy ? 'buy' : 'sell',
        'foreignAmount': foreignAmount.toDouble(),
        'myrAmount': myrAmount.toDouble(),
        'rateUsed': rateUsed.toDouble(),
        'adminId': adminId,
        'notes': notes,
        'isIncludedInSold': false,
        'soldClosingId': null,
      });

      // Update inventory and average cost
      await _updateInventory(
        currency: currency,
        foreignAmount: foreignAmount,
        rateUsed: rateUsed,
        mode: mode,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Update inventory and average cost after a transaction
  Future<void> _updateInventory({
    required String currency,
    required Decimal foreignAmount,
    required Decimal rateUsed,
    required ExchangeMode mode,
  }) async {
    final docRef = _firestore.collection('currency_rates').doc(currency);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('Currency rate not found');
      }
      
      final currentData = snapshot.data()!;
      final currentInventory = Decimal.parse(
        currentData['currentInventory']?.toString() ?? '0',
      );
      final currentAvgCost = Decimal.parse(
        currentData['averageCost']?.toString() ?? '0',
      );

      Decimal newInventory;
      Decimal newAvgCost;

      if (mode == ExchangeMode.buy) {
        // Buying: Increase inventory and recalculate average cost
        newInventory = currentInventory + foreignAmount;
        
        // Weighted average cost formula:
        // newAvg = (oldInventory * oldAvg + newAmount * newRate) / newInventory
        final totalCost = (currentInventory * currentAvgCost) + 
                         (foreignAmount * rateUsed);
        newAvgCost = newInventory > Decimal.zero 
            ? (totalCost / newInventory).toDecimal()
            : Decimal.zero;
      } else {
        // Selling: Decrease inventory, keep average cost same
        newInventory = currentInventory - foreignAmount;
        newAvgCost = currentAvgCost;
        
        if (newInventory < Decimal.zero) {
          throw Exception('Insufficient inventory');
        }
      }

      transaction.update(docRef, {
        'currentInventory': newInventory.toDouble(),
        'averageCost': newAvgCost.toDouble(),
      });
    });
  }

  /// Execute Daily Sold operation
  Future<DailyClosing> executeDailySold({
    required String currency,
    required Decimal bulkSellingRate,
    required String adminId,
  }) async {
    try {
      // Get current currency data
      final currencyDoc = await _firestore
          .collection('currency_rates')
          .doc(currency)
          .get();
      
      if (!currencyDoc.exists) {
        throw Exception('Currency not found');
      }
      
      final currencyData = currencyDoc.data()!;
      final totalVolumeSold = Decimal.parse(
        currencyData['currentInventory'].toString(),
      );
      final averageBuyingRate = Decimal.parse(
        currencyData['averageCost'].toString(),
      );
      
      // Calculate profit
      final profit = (bulkSellingRate - averageBuyingRate) * totalVolumeSold;
      
      // Determine period
      final now = DateTime.now();
      final lastSoldDate = currencyData['lastSoldDate'];
      final periodStart = lastSoldDate != null
          ? DateTime.parse(lastSoldDate).add(const Duration(hours: 17))
          : now.subtract(const Duration(days: 1));
      
      // Get all transactions in this period
      final transactions = await _firestore
          .collection('exchange_transactions')
          .where('currency', isEqualTo: currency)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('isIncludedInSold', isEqualTo: false)
          .get();
      
      final transactionIds = transactions.docs.map((doc) => doc.id).toList();
      
      // Create daily closing record
      final closingId = 'closing_${currency}_${now.toString().split(' ')[0]}';
      final dailyClosing = DailyClosing(
        id: closingId,
        currency: currency,
        date: now.toString().split(' ')[0],
        soldTime: now,
        bulkSellingRate: bulkSellingRate,
        averageBuyingRate: averageBuyingRate,
        totalVolumeSold: totalVolumeSold,
        profit: profit,
        periodStart: periodStart,
        periodEnd: now,
        transactionIds: transactionIds,
        adminId: adminId,
      );
      
      // Save to Firestore
      await _firestore
          .collection('daily_closings')
          .doc(closingId)
          .set(dailyClosing.toFirestore());
      
      // Update all transactions to mark as included
      final batch = _firestore.batch();
      for (final txnId in transactionIds) {
        batch.update(
          _firestore.collection('exchange_transactions').doc(txnId),
          {
            'isIncludedInSold': true,
            'soldClosingId': closingId,
          },
        );
      }
      await batch.commit();
      
      // Reset currency inventory and update last sold date
      await _firestore.collection('currency_rates').doc(currency).update({
        'currentInventory': 0,
        'averageCost': 0,
        'lastSoldDate': now.toString().split(' ')[0],
      });
      
      return dailyClosing;
    } catch (e) {
      throw Exception('Failed to execute daily sold: $e');
    }
  }

  /// Get unsold transactions for a currency
  Stream<List<ExchangeTransaction>> getUnsoldTransactions(String currency) {
    return _firestore
        .collection('exchange_transactions')
        .where('currency', isEqualTo: currency)
        .where('isIncludedInSold', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExchangeTransaction.fromFirestore(doc))
            .toList());
  }

  /// Get transaction history
  Stream<List<ExchangeTransaction>> getTransactionHistory({
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection('exchange_transactions');
    
    if (currency != null) {
      query = query.where('currency', isEqualTo: currency);
    }
    
    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    return query
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExchangeTransaction.fromFirestore(doc))
            .toList());
  }
}
