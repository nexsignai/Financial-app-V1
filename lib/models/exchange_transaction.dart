import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';

enum ExchangeMode { buy, sell }

class ExchangeTransaction {
  final String id;
  final DateTime timestamp;
  final String currency;
  final ExchangeMode mode;
  final Decimal foreignAmount;
  final Decimal myrAmount;
  final Decimal rateUsed;
  final String adminId;
  final String? notes;
  final bool isIncludedInSold;
  final String? soldClosingId;

  ExchangeTransaction({
    required this.id,
    required this.timestamp,
    required this.currency,
    required this.mode,
    required this.foreignAmount,
    required this.myrAmount,
    required this.rateUsed,
    required this.adminId,
    this.notes,
    this.isIncludedInSold = false,
    this.soldClosingId,
  });

  factory ExchangeTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ExchangeTransaction(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      currency: data['currency'],
      mode: data['mode'] == 'buy' ? ExchangeMode.buy : ExchangeMode.sell,
      foreignAmount: Decimal.parse(data['foreignAmount'].toString()),
      myrAmount: Decimal.parse(data['myrAmount'].toString()),
      rateUsed: Decimal.parse(data['rateUsed'].toString()),
      adminId: data['adminId'],
      notes: data['notes'],
      isIncludedInSold: data['isIncludedInSold'] ?? false,
      soldClosingId: data['soldClosingId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'currency': currency,
      'mode': mode == ExchangeMode.buy ? 'buy' : 'sell',
      'foreignAmount': foreignAmount.toDouble(),
      'myrAmount': myrAmount.toDouble(),
      'rateUsed': rateUsed.toDouble(),
      'adminId': adminId,
      'notes': notes,
      'isIncludedInSold': isIncludedInSold,
      'soldClosingId': soldClosingId,
    };
  }

  ExchangeTransaction copyWith({
    String? id,
    DateTime? timestamp,
    String? currency,
    ExchangeMode? mode,
    Decimal? foreignAmount,
    Decimal? myrAmount,
    Decimal? rateUsed,
    String? adminId,
    String? notes,
    bool? isIncludedInSold,
    String? soldClosingId,
  }) {
    return ExchangeTransaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      currency: currency ?? this.currency,
      mode: mode ?? this.mode,
      foreignAmount: foreignAmount ?? this.foreignAmount,
      myrAmount: myrAmount ?? this.myrAmount,
      rateUsed: rateUsed ?? this.rateUsed,
      adminId: adminId ?? this.adminId,
      notes: notes ?? this.notes,
      isIncludedInSold: isIncludedInSold ?? this.isIncludedInSold,
      soldClosingId: soldClosingId ?? this.soldClosingId,
    );
  }
}
