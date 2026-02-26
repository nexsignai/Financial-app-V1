import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';

enum RemittanceStatus { paid, unpaid }

class RemittanceTransaction {
  final String id;
  final DateTime timestamp;
  final String customerId;
  final String customerName;
  final String destinationCountry;
  final Decimal myrAmount;
  final Decimal foreignAmount;
  final String currency;
  final Decimal rateUsed;
  final RemittanceStatus status;
  final DateTime statusChangedAt;
  final String clipboardText;
  final String adminId;
  final Decimal feeAmount;

  RemittanceTransaction({
    required this.id,
    required this.timestamp,
    required this.customerId,
    required this.customerName,
    required this.destinationCountry,
    required this.myrAmount,
    required this.foreignAmount,
    required this.currency,
    required this.rateUsed,
    required this.status,
    required this.statusChangedAt,
    required this.clipboardText,
    required this.adminId,
    Decimal? feeAmount,
  }) : feeAmount = feeAmount ?? Decimal.zero;

  factory RemittanceTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return RemittanceTransaction(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      customerId: data['customerId'],
      customerName: data['customerName'],
      destinationCountry: data['destinationCountry'],
      myrAmount: Decimal.parse(data['myrAmount'].toString()),
      foreignAmount: Decimal.parse(data['foreignAmount'].toString()),
      currency: data['currency'],
      rateUsed: Decimal.parse(data['rateUsed'].toString()),
      status: data['status'] == 'paid'
          ? RemittanceStatus.paid
          : RemittanceStatus.unpaid,
      statusChangedAt: (data['statusChangedAt'] as Timestamp).toDate(),
      clipboardText: data['clipboardText'],
      adminId: data['adminId'],
      feeAmount: Decimal.parse(data['feeAmount']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'customerId': customerId,
      'customerName': customerName,
      'destinationCountry': destinationCountry,
      'myrAmount': myrAmount.toDouble(),
      'foreignAmount': foreignAmount.toDouble(),
      'currency': currency,
      'rateUsed': rateUsed.toDouble(),
      'status': status == RemittanceStatus.paid ? 'paid' : 'unpaid',
      'statusChangedAt': Timestamp.fromDate(statusChangedAt),
      'clipboardText': clipboardText,
      'adminId': adminId,
      'feeAmount': feeAmount.toDouble(),
    };
  }

  RemittanceTransaction copyWith({
    String? id,
    DateTime? timestamp,
    String? customerId,
    String? customerName,
    String? destinationCountry,
    Decimal? myrAmount,
    Decimal? foreignAmount,
    String? currency,
    Decimal? rateUsed,
    RemittanceStatus? status,
    DateTime? statusChangedAt,
    String? clipboardText,
    String? adminId,
    Decimal? feeAmount,
  }) {
    return RemittanceTransaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      myrAmount: myrAmount ?? this.myrAmount,
      foreignAmount: foreignAmount ?? this.foreignAmount,
      currency: currency ?? this.currency,
      rateUsed: rateUsed ?? this.rateUsed,
      status: status ?? this.status,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      clipboardText: clipboardText ?? this.clipboardText,
      adminId: adminId ?? this.adminId,
      feeAmount: feeAmount ?? this.feeAmount,
    );
  }

  bool get isPaid => status == RemittanceStatus.paid;
  bool get isUnpaid => status == RemittanceStatus.unpaid;
}
