import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';

class DailyClosing {
  final String id;
  final String currency;
  final String date; // YYYY-MM-DD format
  final DateTime soldTime;
  final Decimal bulkSellingRate;
  final Decimal averageBuyingRate;
  final Decimal totalVolumeSold;
  final Decimal profit;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<String> transactionIds;
  final String adminId;

  DailyClosing({
    required this.id,
    required this.currency,
    required this.date,
    required this.soldTime,
    required this.bulkSellingRate,
    required this.averageBuyingRate,
    required this.totalVolumeSold,
    required this.profit,
    required this.periodStart,
    required this.periodEnd,
    required this.transactionIds,
    required this.adminId,
  });

  factory DailyClosing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DailyClosing(
      id: doc.id,
      currency: data['currency'],
      date: data['date'],
      soldTime: (data['soldTime'] as Timestamp).toDate(),
      bulkSellingRate: Decimal.parse(data['bulkSellingRate'].toString()),
      averageBuyingRate: Decimal.parse(data['averageBuyingRate'].toString()),
      totalVolumeSold: Decimal.parse(data['totalVolumeSold'].toString()),
      profit: Decimal.parse(data['profit'].toString()),
      periodStart: (data['periodStart'] as Timestamp).toDate(),
      periodEnd: (data['periodEnd'] as Timestamp).toDate(),
      transactionIds: List<String>.from(data['transactionIds'] ?? []),
      adminId: data['adminId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currency': currency,
      'date': date,
      'soldTime': Timestamp.fromDate(soldTime),
      'bulkSellingRate': bulkSellingRate.toDouble(),
      'averageBuyingRate': averageBuyingRate.toDouble(),
      'totalVolumeSold': totalVolumeSold.toDouble(),
      'profit': profit.toDouble(),
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'transactionIds': transactionIds,
      'adminId': adminId,
    };
  }

  DailyClosing copyWith({
    String? id,
    String? currency,
    String? date,
    DateTime? soldTime,
    Decimal? bulkSellingRate,
    Decimal? averageBuyingRate,
    Decimal? totalVolumeSold,
    Decimal? profit,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<String>? transactionIds,
    String? adminId,
  }) {
    return DailyClosing(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      soldTime: soldTime ?? this.soldTime,
      bulkSellingRate: bulkSellingRate ?? this.bulkSellingRate,
      averageBuyingRate: averageBuyingRate ?? this.averageBuyingRate,
      totalVolumeSold: totalVolumeSold ?? this.totalVolumeSold,
      profit: profit ?? this.profit,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      transactionIds: transactionIds ?? this.transactionIds,
      adminId: adminId ?? this.adminId,
    );
  }
}
