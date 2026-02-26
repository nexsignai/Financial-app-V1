import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../models/tour_transaction.dart';

class TourService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create tour transaction
  Future<String> createTransaction({
    required String description,
    required Decimal chargeAmount,
    required Decimal profitAmount,
    required String driver,
    required TourStatus status,
    required String adminId,
  }) async {
    try {
      final timestamp = DateTime.now();

      final docRef = await _firestore.collection('tour_transactions').add({
        'timestamp': Timestamp.fromDate(timestamp),
        'description': description,
        'chargeAmount': chargeAmount.toDouble(),
        'profitAmount': profitAmount.toDouble(),
        'driver': driver,
        'status': status == TourStatus.clear ? 'clear' : 'unclear',
        'statusChangedAt': Timestamp.fromDate(timestamp),
        'adminId': adminId,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create tour transaction: $e');
    }
  }

  /// Update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required TourStatus newStatus,
  }) async {
    try {
      await _firestore.collection('tour_transactions').doc(transactionId).update({
        'status': newStatus == TourStatus.clear ? 'clear' : 'unclear',
        'statusChangedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update tour status: $e');
    }
  }

  /// Get pending (unclear) tours
  Stream<List<TourTransaction>> getPendingTours() {
    return _firestore
        .collection('tour_transactions')
        .where('status', isEqualTo: 'unclear')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TourTransaction.fromFirestore(doc))
            .toList());
  }

  /// Get transaction history
  Stream<List<TourTransaction>> getTransactionHistory({
    TourStatus? status,
    String? driver,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection('tour_transactions');

    if (status != null) {
      query = query.where('status',
          isEqualTo: status == TourStatus.clear ? 'clear' : 'unclear');
    }

    if (driver != null) {
      query = query.where('driver', isEqualTo: driver);
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
            .map((doc) => TourTransaction.fromFirestore(doc))
            .toList());
  }

  /// Get tours by driver
  Stream<List<TourTransaction>> getToursByDriver(String driver) {
    return _firestore
        .collection('tour_transactions')
        .where('driver', isEqualTo: driver)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TourTransaction.fromFirestore(doc))
            .toList());
  }

  /// Calculate total profit for cleared tours in a date range
  Future<Decimal> calculateProfitForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('tour_transactions')
          .where('status', isEqualTo: 'clear')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Decimal totalProfit = Decimal.zero;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalProfit += Decimal.parse(data['profitAmount'].toString());
      }

      return totalProfit;
    } catch (e) {
      throw Exception('Failed to calculate tour profit: $e');
    }
  }
}
