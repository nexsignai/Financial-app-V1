import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String bankName;
  final String accountNumber;
  final String? ifscCode;
  final String country; // 'India' or 'Indonesia'
  final DateTime createdAt;
  final DateTime? lastTransactionDate;
  final int totalTransactions;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.bankName,
    required this.accountNumber,
    this.ifscCode,
    required this.country,
    required this.createdAt,
    this.lastTransactionDate,
    this.totalTransactions = 0,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Customer(
      id: doc.id,
      name: data['name'],
      phone: data['phone'],
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      ifscCode: data['ifscCode'],
      country: data['country'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastTransactionDate: data['lastTransactionDate'] != null
          ? (data['lastTransactionDate'] as Timestamp).toDate()
          : null,
      totalTransactions: data['totalTransactions'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTransactionDate': lastTransactionDate != null
          ? Timestamp.fromDate(lastTransactionDate!)
          : null,
      'totalTransactions': totalTransactions,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? country,
    DateTime? createdAt,
    DateTime? lastTransactionDate,
    int? totalTransactions,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      totalTransactions: totalTransactions ?? this.totalTransactions,
    );
  }

  // Get currency code based on country
  String get currencyCode {
    switch (country) {
      case 'India':
        return 'INR';
      case 'Indonesia':
        return 'IDR';
      default:
        return '';
    }
  }

  // Fuzzy search helper
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        phone.contains(query) ||
        accountNumber.contains(query);
  }
}
