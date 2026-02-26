import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';

enum TourStatus { clear, unclear }

class TourTransaction {
  final String id;
  final DateTime timestamp;
  final String description;
  final Decimal chargeAmount;
  final Decimal profitAmount;
  final String driver;
  final TourStatus status;
  final DateTime statusChangedAt;
  final String adminId;

  TourTransaction({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.chargeAmount,
    required this.profitAmount,
    required this.driver,
    required this.status,
    required this.statusChangedAt,
    required this.adminId,
  });

  factory TourTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TourTransaction(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      description: data['description'],
      chargeAmount: Decimal.parse(data['chargeAmount'].toString()),
      profitAmount: Decimal.parse(data['profitAmount'].toString()),
      driver: data['driver'],
      status: data['status'] == 'clear' ? TourStatus.clear : TourStatus.unclear,
      statusChangedAt: (data['statusChangedAt'] as Timestamp).toDate(),
      adminId: data['adminId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'chargeAmount': chargeAmount.toDouble(),
      'profitAmount': profitAmount.toDouble(),
      'driver': driver,
      'status': status == TourStatus.clear ? 'clear' : 'unclear',
      'statusChangedAt': Timestamp.fromDate(statusChangedAt),
      'adminId': adminId,
    };
  }

  TourTransaction copyWith({
    String? id,
    DateTime? timestamp,
    String? description,
    Decimal? chargeAmount,
    Decimal? profitAmount,
    String? driver,
    TourStatus? status,
    DateTime? statusChangedAt,
    String? adminId,
  }) {
    return TourTransaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      chargeAmount: chargeAmount ?? this.chargeAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      driver: driver ?? this.driver,
      status: status ?? this.status,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      adminId: adminId ?? this.adminId,
    );
  }

  bool get isClear => status == TourStatus.clear;
  bool get isUnclear => status == TourStatus.unclear;
}
