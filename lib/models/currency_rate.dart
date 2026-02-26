import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';

class CurrencyRate {
  final String code;
  final String name;
  final String flagEmoji;
  final Decimal realRate;
  final Decimal displayBuyRate;
  final Decimal displaySellRate;
  final bool isManualOverride;
  final DateTime lastUpdated;
  final Decimal averageCost;
  final Decimal currentInventory;
  final String? lastSoldDate;

  CurrencyRate({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.realRate,
    required this.displayBuyRate,
    required this.displaySellRate,
    required this.isManualOverride,
    required this.lastUpdated,
    required this.averageCost,
    required this.currentInventory,
    this.lastSoldDate,
  });

  // Factory constructor from Firestore
  factory CurrencyRate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CurrencyRate(
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      flagEmoji: data['flagEmoji'] ?? '',
      realRate: Decimal.parse(data['realRate'].toString()),
      displayBuyRate: Decimal.parse(data['displayBuyRate'].toString()),
      displaySellRate: Decimal.parse(data['displaySellRate'].toString()),
      isManualOverride: data['isManualOverride'] ?? false,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      averageCost: Decimal.parse(data['averageCost']?.toString() ?? '0'),
      currentInventory: Decimal.parse(data['currentInventory']?.toString() ?? '0'),
      lastSoldDate: data['lastSoldDate'],
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'flagEmoji': flagEmoji,
      'realRate': realRate.toDouble(),
      'displayBuyRate': displayBuyRate.toDouble(),
      'displaySellRate': displaySellRate.toDouble(),
      'isManualOverride': isManualOverride,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'averageCost': averageCost.toDouble(),
      'currentInventory': currentInventory.toDouble(),
      'lastSoldDate': lastSoldDate,
    };
  }

  // CopyWith for immutable updates
  CurrencyRate copyWith({
    String? code,
    String? name,
    String? flagEmoji,
    Decimal? realRate,
    Decimal? displayBuyRate,
    Decimal? displaySellRate,
    bool? isManualOverride,
    DateTime? lastUpdated,
    Decimal? averageCost,
    Decimal? currentInventory,
    String? lastSoldDate,
  }) {
    return CurrencyRate(
      code: code ?? this.code,
      name: name ?? this.name,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      realRate: realRate ?? this.realRate,
      displayBuyRate: displayBuyRate ?? this.displayBuyRate,
      displaySellRate: displaySellRate ?? this.displaySellRate,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      averageCost: averageCost ?? this.averageCost,
      currentInventory: currentInventory ?? this.currentInventory,
      lastSoldDate: lastSoldDate ?? this.lastSoldDate,
    );
  }
}
