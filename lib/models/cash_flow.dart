import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';

class ProfitBreakdown {
  final Decimal exchangeProfit;
  final Decimal remittanceFees;
  final Decimal tourProfit;

  ProfitBreakdown({
    required this.exchangeProfit,
    required this.remittanceFees,
    required this.tourProfit,
  });

  Decimal get total => exchangeProfit + remittanceFees + tourProfit;

  factory ProfitBreakdown.fromMap(Map<String, dynamic> map) {
    return ProfitBreakdown(
      exchangeProfit: Decimal.parse(map['exchangeProfit']?.toString() ?? '0'),
      remittanceFees: Decimal.parse(map['remittanceFees']?.toString() ?? '0'),
      tourProfit: Decimal.parse(map['tourProfit']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exchangeProfit': exchangeProfit.toDouble(),
      'remittanceFees': remittanceFees.toDouble(),
      'tourProfit': tourProfit.toDouble(),
    };
  }
}

class CashFlow {
  final String date; // YYYY-MM-DD format
  final Decimal openingCash;
  final Decimal totalIn;
  final Decimal totalOut;
  final Decimal closingCash;
  final Decimal cashInHand;
  final Decimal bankInAmount;
  final Decimal netProfit;
  final ProfitBreakdown profitBreakdown;
  final DateTime lastUpdated;

  CashFlow({
    required this.date,
    required this.openingCash,
    required this.totalIn,
    required this.totalOut,
    required this.closingCash,
    required this.cashInHand,
    required this.bankInAmount,
    required this.netProfit,
    required this.profitBreakdown,
    required this.lastUpdated,
  });

  factory CashFlow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CashFlow(
      date: data['date'],
      openingCash: Decimal.parse(data['openingCash'].toString()),
      totalIn: Decimal.parse(data['totalIn'].toString()),
      totalOut: Decimal.parse(data['totalOut'].toString()),
      closingCash: Decimal.parse(data['closingCash'].toString()),
      cashInHand: Decimal.parse(data['cashInHand'].toString()),
      bankInAmount: Decimal.parse(data['bankInAmount']?.toString() ?? '0'),
      netProfit: Decimal.parse(data['netProfit'].toString()),
      profitBreakdown: ProfitBreakdown.fromMap(
        data['profitBreakdown'] as Map<String, dynamic>,
      ),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'openingCash': openingCash.toDouble(),
      'totalIn': totalIn.toDouble(),
      'totalOut': totalOut.toDouble(),
      'closingCash': closingCash.toDouble(),
      'cashInHand': cashInHand.toDouble(),
      'bankInAmount': bankInAmount.toDouble(),
      'netProfit': netProfit.toDouble(),
      'profitBreakdown': profitBreakdown.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  CashFlow copyWith({
    String? date,
    Decimal? openingCash,
    Decimal? totalIn,
    Decimal? totalOut,
    Decimal? closingCash,
    Decimal? cashInHand,
    Decimal? bankInAmount,
    Decimal? netProfit,
    ProfitBreakdown? profitBreakdown,
    DateTime? lastUpdated,
  }) {
    return CashFlow(
      date: date ?? this.date,
      openingCash: openingCash ?? this.openingCash,
      totalIn: totalIn ?? this.totalIn,
      totalOut: totalOut ?? this.totalOut,
      closingCash: closingCash ?? this.closingCash,
      cashInHand: cashInHand ?? this.cashInHand,
      bankInAmount: bankInAmount ?? this.bankInAmount,
      netProfit: netProfit ?? this.netProfit,
      profitBreakdown: profitBreakdown ?? this.profitBreakdown,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
