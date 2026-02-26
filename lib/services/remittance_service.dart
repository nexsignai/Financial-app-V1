import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../models/remittance_transaction.dart';
import '../models/customer.dart';

class RemittanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate foreign amount from MYR with round-up logic
  Decimal calculateForeignWithRoundUp({
    required Decimal myrAmount,
    required Decimal rate,
  }) {
    // Calculate raw amount
    final rawAmount = myrAmount * rate;
    
    // Round UP to nearest 100
    final roundedValue = (rawAmount.toDouble() / 100).ceil() * 100;
    
    return Decimal.parse(roundedValue.toString());
  }

  /// Calculate MYR from foreign amount
  Decimal calculateMYRFromForeign({
    required Decimal foreignAmount,
    required Decimal rate,
  }) {
    return (foreignAmount / rate).toDecimal();
  }

  /// Generate clipboard text for easy copying
  String generateClipboardText({
    required Customer customer,
    required Decimal amount,
  }) {
    return '${customer.name} ${customer.bankName} '
           '${customer.accountNumber} ${amount.toStringAsFixed(0)} + 10000';
  }

  /// Create remittance transaction
  Future<String> createTransaction({
    required Customer customer,
    required Decimal myrAmount,
    required Decimal foreignAmount,
    required Decimal rateUsed,
    required RemittanceStatus status,
    required String adminId,
    Decimal? feeAmount,
  }) async {
    try {
      final timestamp = DateTime.now();
      final clipboardText = generateClipboardText(
        customer: customer,
        amount: foreignAmount,
      );

      final docRef = await _firestore.collection('remittance_transactions').add({
        'timestamp': Timestamp.fromDate(timestamp),
        'customerId': customer.id,
        'customerName': customer.name,
        'destinationCountry': customer.country,
        'myrAmount': myrAmount.toDouble(),
        'foreignAmount': foreignAmount.toDouble(),
        'currency': customer.currencyCode,
        'rateUsed': rateUsed.toDouble(),
        'status': status == RemittanceStatus.paid ? 'paid' : 'unpaid',
        'statusChangedAt': Timestamp.fromDate(timestamp),
        'clipboardText': clipboardText,
        'adminId': adminId,
        'feeAmount': (feeAmount ?? Decimal.zero).toDouble(),
      });

      // Update customer's last transaction date
      await _firestore.collection('customers').doc(customer.id).update({
        'lastTransactionDate': Timestamp.fromDate(timestamp),
        'totalTransactions': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create remittance transaction: $e');
    }
  }

  /// Update transaction status (Unpaid -> Paid)
  Future<void> updateTransactionStatus({
    required String transactionId,
    required RemittanceStatus newStatus,
  }) async {
    try {
      await _firestore
          .collection('remittance_transactions')
          .doc(transactionId)
          .update({
        'status': newStatus == RemittanceStatus.paid ? 'paid' : 'unpaid',
        'statusChangedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update transaction status: $e');
    }
  }

  /// Get pending (unpaid) transactions
  Stream<List<RemittanceTransaction>> getPendingTransactions() {
    return _firestore
        .collection('remittance_transactions')
        .where('status', isEqualTo: 'unpaid')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RemittanceTransaction.fromFirestore(doc))
            .toList());
  }

  /// Get transaction history
  Stream<List<RemittanceTransaction>> getTransactionHistory({
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    RemittanceStatus? status,
  }) {
    Query query = _firestore.collection('remittance_transactions');

    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    if (status != null) {
      query = query.where('status',
          isEqualTo: status == RemittanceStatus.paid ? 'paid' : 'unpaid');
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
            .map((doc) => RemittanceTransaction.fromFirestore(doc))
            .toList());
  }

  /// Create or update customer
  Future<String> saveCustomer({
    String? id,
    required String name,
    required String phone,
    required String bankName,
    required String accountNumber,
    String? ifscCode,
    required String country,
  }) async {
    try {
      final timestamp = DateTime.now();

      if (id == null) {
        // Create new customer
        final docRef = await _firestore.collection('customers').add({
          'name': name,
          'phone': phone,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
          'country': country,
          'createdAt': Timestamp.fromDate(timestamp),
          'lastTransactionDate': null,
          'totalTransactions': 0,
        });
        return docRef.id;
      } else {
        // Update existing customer
        await _firestore.collection('customers').doc(id).update({
          'name': name,
          'phone': phone,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
          'country': country,
        });
        return id;
      }
    } catch (e) {
      throw Exception('Failed to save customer: $e');
    }
  }

  /// Search customers (fuzzy search)
  Stream<List<Customer>> searchCustomers(String query) {
    if (query.isEmpty) {
      return _firestore
          .collection('customers')
          .orderBy('lastTransactionDate', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Customer.fromFirestore(doc))
              .toList());
    }

    // For fuzzy search, we get all customers and filter in memory
    // In production, consider using Algolia or similar for better search
    return _firestore
        .collection('customers')
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final customers = snapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();

      return customers
          .where((customer) => customer.matchesSearch(query))
          .toList();
    });
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final doc = await _firestore
          .collection('customers')
          .doc(customerId)
          .get();

      if (doc.exists) {
        return Customer.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }
}
