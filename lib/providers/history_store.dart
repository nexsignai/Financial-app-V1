// lib/providers/history_store.dart
// Single source of truth for history. Cash flow and profit breakdown computed from these lists.
// Extends ChangeNotifier so Cash Flow and Profit Breakdown screens update dynamically after each transaction.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decimal/decimal.dart';

import '../config/supabase_config.dart';
import '../services/supabase_history_service.dart';

enum HistoryItemType { exchange, remittance, tour }

/// One item in the unified (master) history list.
class UnifiedHistoryItem {
  final HistoryItemType type;
  final String id;
  final DateTime dateTime;
  final MockExchangeEntry? exchange;
  final MockRemittanceEntry? remittance;
  final MockTourEntry? tour;

  UnifiedHistoryItem._({
    required this.type,
    required this.id,
    required this.dateTime,
    this.exchange,
    this.remittance,
    this.tour,
  });

  factory UnifiedHistoryItem.fromExchange(MockExchangeEntry e) {
    return UnifiedHistoryItem._(
      type: HistoryItemType.exchange,
      id: e.id,
      dateTime: e.dateTime,
      exchange: e,
    );
  }

  factory UnifiedHistoryItem.fromRemittance(MockRemittanceEntry e) {
    return UnifiedHistoryItem._(
      type: HistoryItemType.remittance,
      id: e.id,
      dateTime: e.dateTime,
      remittance: e,
    );
  }

  factory UnifiedHistoryItem.fromTour(MockTourEntry e) {
    return UnifiedHistoryItem._(
      type: HistoryItemType.tour,
      id: e.id,
      dateTime: e.dateTime,
      tour: e,
    );
  }

  bool get needsAttention {
    if (remittance != null) return !remittance!.isPaid;
    if (tour != null) return !tour!.isClear;
    return false;
  }

  String get searchableText {
    if (exchange != null) {
      final e = exchange!;
      return '${e.currency} ${e.mode} ${e.foreignAmount} ${e.myrAmount}';
    }
    if (remittance != null) {
      final r = remittance!;
      return '${r.customerName} ${r.currency} ${r.myrAmount} ${r.foreignAmount} ${r.bankName} ${r.accountNumber}';
    }
    if (tour != null) {
      final t = tour!;
      return '${t.description} ${t.driver} ${t.chargeAmount} ${t.profitAmount}';
    }
    return '';
  }
}

/// Single source of truth for history. Cash flow is computed from these lists.
/// Notifies listeners on every add/update/toggle so Cash Flow and Profit Breakdown update dynamically.
class HistoryStore extends ChangeNotifier {
  HistoryStore._();
  static final HistoryStore _instance = HistoryStore._();
  static HistoryStore get instance => _instance;

  final List<MockExchangeEntry> exchangeHistory = [];
  final List<MockRemittanceEntry> remittanceHistory = [];
  final List<MockTourEntry> tourHistory = [];
  /// Daily sold profit entries (Money Changer) — feed into cash flow.
  final List<DailySoldProfitEntry> dailySoldProfits = [];

  void addDailySoldProfit(Decimal amount) {
    final entry = DailySoldProfitEntry(
      id: 'ds_${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.now(),
      amount: amount,
    );
    dailySoldProfits.insert(0, entry);
    notifyListeners();
    if (isSupabaseConfigured) {
      SupabaseHistoryService.saveDailySoldProfit(entry);
    }
  }

  static void initSampleData() {
    if (isSupabaseConfigured) return; // Use Supabase data; load via loadFromSupabase() at startup.
    final s = instance;
    if (s.exchangeHistory.isNotEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    s.exchangeHistory.addAll([
      MockExchangeEntry(
        id: 'ex1',
        dateTime: today.subtract(const Duration(hours: 2)),
        currency: 'USD_BIG',
        mode: 'sell',
        foreignAmount: Decimal.parse('1000'),
        myrAmount: Decimal.parse('4600'),
        rateUsed: Decimal.parse('4.60'),
      ),
      MockExchangeEntry(
        id: 'ex2',
        dateTime: today.subtract(const Duration(hours: 4)),
        currency: 'SGD',
        mode: 'buy',
        foreignAmount: Decimal.parse('500'),
        myrAmount: Decimal.parse('1625'),
        rateUsed: Decimal.parse('3.25'),
      ),
      MockExchangeEntry(
        id: 'ex3',
        dateTime: today.subtract(const Duration(days: 1)),
        currency: 'GBP',
        mode: 'sell',
        foreignAmount: Decimal.parse('200'),
        myrAmount: Decimal.parse('1160'),
        rateUsed: Decimal.parse('5.80'),
      ),
    ]);

    s.remittanceHistory.addAll([
      MockRemittanceEntry(
        id: 'rem1',
        dateTime: today.subtract(const Duration(hours: 1)),
        customerName: 'Rajesh Kumar',
        phone: '+60123456789',
        bankName: 'ICICI Bank',
        accountNumber: '123456789012',
        myrAmount: Decimal.parse('5000'),
        foreignAmount: Decimal.parse('116279.07'),
        currency: 'INR',
        feeAmount: Decimal.parse('50'),
        isPaid: true,
        exchangeRate: Decimal.parse('0.043'),
        fixedRate: Decimal.parse('0.042'),
        costAmount: Decimal.parse('4883.72'),
        profitAmount: Decimal.parse('116.28'),
      ),
      MockRemittanceEntry(
        id: 'rem2',
        dateTime: today.subtract(const Duration(hours: 3)),
        customerName: 'Budi Santoso',
        phone: '+60187654321',
        bankName: 'Bank Mandiri',
        accountNumber: '1234567890',
        myrAmount: Decimal.parse('3000'),
        foreignAmount: Decimal.parse('13043478.26'),
        currency: 'IDR',
        feeAmount: Decimal.parse('30'),
        isPaid: false,
        exchangeRate: Decimal.parse('0.000230'),
        fixedRate: Decimal.parse('0.000229'),
        costAmount: Decimal.parse('2986.96'),
        profitAmount: Decimal.parse('13.04'),
      ),
      MockRemittanceEntry(
        id: 'rem3',
        dateTime: today.subtract(const Duration(days: 1)),
        customerName: 'Priya Sharma',
        phone: '+60198765432',
        bankName: 'HDFC Bank',
        accountNumber: '987654321098',
        myrAmount: Decimal.parse('2000'),
        foreignAmount: Decimal.parse('46511.63'),
        currency: 'INR',
        feeAmount: Decimal.parse('20'),
        isPaid: true,
        exchangeRate: Decimal.parse('0.043'),
        fixedRate: Decimal.parse('0.042'),
        costAmount: Decimal.parse('1953.49'),
        profitAmount: Decimal.parse('46.51'),
      ),
    ]);

    s.tourHistory.addAll([
      MockTourEntry(
        id: 'tour1',
        dateTime: today.subtract(const Duration(hours: 2)),
        description: 'Airport transfer to KLIA',
        driver: 'Mahen',
        chargeAmount: Decimal.parse('150'),
        profitAmount: Decimal.parse('80'),
        isClear: true,
      ),
      MockTourEntry(
        id: 'tour2',
        dateTime: today.subtract(const Duration(hours: 5)),
        description: 'City tour',
        driver: 'Others',
        chargeAmount: Decimal.parse('200'),
        profitAmount: Decimal.parse('100'),
        isClear: false,
      ),
      MockTourEntry(
        id: 'tour3',
        dateTime: today.subtract(const Duration(days: 1)),
        description: 'Hotel pickup',
        driver: 'Mahen',
        chargeAmount: Decimal.parse('80'),
        profitAmount: Decimal.parse('40'),
        isClear: true,
      ),
    ]);
    // Notify listeners that sample data (for demo) has been loaded.
    s.notifyListeners();
  }

  /// Load all history and opening cash from Supabase. Call at app startup when Supabase is configured.
  Future<void> loadFromSupabase() async {
    if (!isSupabaseConfigured) return;
    try {
      final rem = await SupabaseHistoryService.loadRemittance();
      final ex = await SupabaseHistoryService.loadExchange();
      final tour = await SupabaseHistoryService.loadTour();
      final ds = await SupabaseHistoryService.loadDailySoldProfits();
      final opening = await SupabaseHistoryService.loadOpeningCash();
      exchangeHistory
        ..clear()
        ..addAll(ex);
      remittanceHistory
        ..clear()
        ..addAll(rem);
      tourHistory
        ..clear()
        ..addAll(tour);
      dailySoldProfits
        ..clear()
        ..addAll(ds);
      _openingCash = opening;
      notifyListeners();
    } catch (_) {
      // Keep in-memory state on error (e.g. no tables yet)
    }
  }

  void toggleRemittancePaid(String id) {
    final i = remittanceHistory.indexWhere((e) => e.id == id);
    if (i >= 0) {
      final updated = remittanceHistory[i].copyWith(
        isPaid: !remittanceHistory[i].isPaid,
      );
      remittanceHistory[i] = updated;
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.saveRemittance(updated);
      }
    }
  }

  void toggleTourClear(String id) {
    final i = tourHistory.indexWhere((e) => e.id == id);
    if (i >= 0) {
      final updated = tourHistory[i].copyWith(
        isClear: !tourHistory[i].isClear,
      );
      tourHistory[i] = updated;
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.saveTour(updated);
      }
    }
  }

  void addExchange(MockExchangeEntry entry) {
    exchangeHistory.insert(0, entry);
    notifyListeners();
    if (isSupabaseConfigured) {
      SupabaseHistoryService.saveExchange(entry);
    }
  }

  void addRemittance(MockRemittanceEntry entry) {
    remittanceHistory.insert(0, entry);
    notifyListeners();
    if (isSupabaseConfigured) {
      SupabaseHistoryService.saveRemittance(entry);
    }
  }

  void addTour(MockTourEntry entry) {
    tourHistory.insert(0, entry);
    notifyListeners();
    if (isSupabaseConfigured) {
      SupabaseHistoryService.saveTour(entry);
    }
  }

  void updateExchange(MockExchangeEntry entry) {
    final i = exchangeHistory.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      exchangeHistory[i] = entry;
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.saveExchange(entry);
      }
    }
  }

  void updateRemittance(MockRemittanceEntry entry) {
    final i = remittanceHistory.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      remittanceHistory[i] = entry;
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.saveRemittance(entry);
      }
    }
  }

  void updateTour(MockTourEntry entry) {
    final i = tourHistory.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      tourHistory[i] = entry;
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.saveTour(entry);
      }
    }
  }

  /// Delete remittance transaction. Updates history, profit breakdown and cash flow.
  void deleteRemittance(String id) {
    final i = remittanceHistory.indexWhere((e) => e.id == id);
    if (i >= 0) {
      remittanceHistory.removeAt(i);
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.deleteRemittance(id);
      }
    }
  }

  /// Delete exchange transaction. Updates history, profit breakdown and cash flow.
  void deleteExchange(String id) {
    final i = exchangeHistory.indexWhere((e) => e.id == id);
    if (i >= 0) {
      exchangeHistory.removeAt(i);
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.deleteExchange(id);
      }
    }
  }

  /// Delete tour transaction. Updates history, profit breakdown and cash flow.
  void deleteTour(String id) {
    final i = tourHistory.indexWhere((e) => e.id == id);
    if (i >= 0) {
      tourHistory.removeAt(i);
      notifyListeners();
      if (isSupabaseConfigured) {
        SupabaseHistoryService.deleteTour(id);
      }
    }
  }

  /// Priority sort: needs-attention first, then by date descending.
  List<MockRemittanceEntry> getSortedRemittanceHistory() {
    final list = List<MockRemittanceEntry>.from(remittanceHistory);
    list.sort((a, b) {
      final aAttention = !a.isPaid;
      final bAttention = !b.isPaid;
      if (aAttention != bAttention) return aAttention ? -1 : 1;
      return b.dateTime.compareTo(a.dateTime);
    });
    return list;
  }

  List<MockTourEntry> getSortedTourHistory() {
    final list = List<MockTourEntry>.from(tourHistory);
    list.sort((a, b) {
      final aAttention = !a.isClear;
      final bAttention = !b.isClear;
      if (aAttention != bAttention) return aAttention ? -1 : 1;
      return b.dateTime.compareTo(a.dateTime);
    });
    return list;
  }

  List<MockExchangeEntry> getSortedExchangeHistory() {
    final list = List<MockExchangeEntry>.from(exchangeHistory);
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  /// Unified list for master view. Filter by type, status, date range, search.
  List<UnifiedHistoryItem> getUnifiedHistory({
    HistoryItemType? serviceFilter,
    bool? needsAttentionOnly,
    DateTime? dateFrom,
    DateTime? dateTo,
    String searchQuery = '',
  }) {
    final items = <UnifiedHistoryItem>[];
    if (serviceFilter == null || serviceFilter == HistoryItemType.exchange) {
      for (final e in exchangeHistory) {
        items.add(UnifiedHistoryItem.fromExchange(e));
      }
    }
    if (serviceFilter == null || serviceFilter == HistoryItemType.remittance) {
      for (final e in remittanceHistory) {
        items.add(UnifiedHistoryItem.fromRemittance(e));
      }
    }
    if (serviceFilter == null || serviceFilter == HistoryItemType.tour) {
      for (final e in tourHistory) {
        items.add(UnifiedHistoryItem.fromTour(e));
      }
    }
    items.sort((a, b) {
      final aAtt = a.needsAttention;
      final bAtt = b.needsAttention;
      if (aAtt != bAtt) return aAtt ? -1 : 1;
      return b.dateTime.compareTo(a.dateTime);
    });
    var filtered = items;
    if (needsAttentionOnly == true) {
      filtered = filtered.where((i) => i.needsAttention).toList();
    }
    if (dateFrom != null) {
      final from = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
      filtered =
          filtered.where((i) => i.dateTime.isAfter(from) || i.dateTime.isAtSameMomentAs(from)).toList();
    }
    if (dateTo != null) {
      final to = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
      filtered =
          filtered.where((i) => i.dateTime.isBefore(to) || i.dateTime.isAtSameMomentAs(to)).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((i) => i.searchableText.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  // --- Cash flow (today) ---
  static const String _keyOpeningCash = 'cash_flow_opening_cash';
  Decimal _openingCash = Decimal.parse('10000.00');

  Decimal get openingCash => _openingCash;

  /// Load opening cash from persistence (call from Cash Flow or app init). When Supabase is configured, use loadFromSupabase() instead.
  Future<void> loadOpeningCash() async {
    if (isSupabaseConfigured) return; // opening cash loaded in loadFromSupabase()
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyOpeningCash);
    if (s != null && s.isNotEmpty) {
      _openingCash = Decimal.parse(s);
      notifyListeners();
    }
  }

  /// Update opening cash and persist. Notifies listeners so Cash Flow updates.
  Future<void> setOpeningCash(Decimal value) async {
    if (value < Decimal.zero) return;
    _openingCash = value;
    notifyListeners();
    if (isSupabaseConfigured) {
      SupabaseHistoryService.saveOpeningCash(value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyOpeningCash, value.toString());
    }
  }

  static String todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Decimal get totalInFromExchange {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in exchangeHistory) {
      if (e.dateStr == today && e.mode == 'sell') sum += e.myrAmount;
    }
    return sum;
  }

  Decimal get totalOutFromExchange {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in exchangeHistory) {
      if (e.dateStr == today && e.mode == 'buy') sum += e.myrAmount;
    }
    return sum;
  }

  /// RM deduction = cost (fixed rate); not customer MYR.
  Decimal get totalOutFromRemittance {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in remittanceHistory) {
      if (e.dateStr == today && e.isPaid) sum += e.costAmount;
    }
    return sum;
  }

  Decimal get remittanceFeesTotal {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in remittanceHistory) {
      if (e.dateStr == today && e.isPaid) sum += e.feeAmount;
    }
    return sum;
  }

  Decimal get tourProfitTotal {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in tourHistory) {
      if (e.dateStr == today && e.isClear) sum += e.profitAmount;
    }
    return sum;
  }

  /// Today's daily sold profit (Money Changer bulk sell).
  Decimal get dailySoldProfitToday {
    final today = todayStr();
    Decimal sum = Decimal.zero;
    for (final e in dailySoldProfits) {
      if (e.dateStr == today) sum += e.amount;
    }
    return sum;
  }

  Decimal get exchangeProfitToday =>
      totalInFromExchange - totalOutFromExchange + dailySoldProfitToday;

  /// Total cash in today: exchange (sell MYR) + remittance (customer MYR for paid) + tour (charge for clear).
  Decimal get totalInFromRemittance {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in remittanceHistory) {
      if (e.dateStr == today && e.isPaid) sum += e.myrAmount;
    }
    return sum;
  }

  Decimal get totalInFromTour {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in tourHistory) {
      if (e.dateStr == today && e.isClear) sum += e.chargeAmount;
    }
    return sum;
  }

  /// Total In = exchange sell + remittance customer MYR (paid) + tour charge (clear).
  Decimal get totalIn =>
      totalInFromExchange + totalInFromRemittance + totalInFromTour;
  /// Total Out = exchange buy + remittance cost (RM deduction for paid).
  Decimal get totalOut => totalOutFromExchange + totalOutFromRemittance;
  Decimal get remittanceProfitToday {
    Decimal sum = Decimal.zero;
    final today = todayStr();
    for (final e in remittanceHistory) {
      if (e.dateStr == today && e.isPaid) sum += e.profitAmount;
    }
    return sum;
  }
  Decimal get netProfit =>
      exchangeProfitToday + remittanceFeesTotal + remittanceProfitToday + tourProfitTotal;

  // --- Daily Profit Breakdown (for unified table) ---

  /// Remittance profit for a given day (paid entries only). Real-time: each completed remittance adds here.
  Decimal getRemittanceProfitForDay(String dateStr) {
    Decimal sum = Decimal.zero;
    for (final e in remittanceHistory) {
      if (e.dateStr == dateStr && e.isPaid) sum += e.profitAmount;
    }
    return sum;
  }

  /// Money Changer profit for a given day (Daily Sold only). Delayed: added when user confirms Daily Sold.
  Decimal getMoneyChangerProfitForDay(String dateStr) {
    Decimal sum = Decimal.zero;
    for (final e in dailySoldProfits) {
      if (e.dateStr == dateStr) sum += e.amount;
    }
    return sum;
  }

  /// Tour profit for a given day (Paid/Clear entries only). Status-based: only when tour is marked Clear/Paid.
  Decimal getTourProfitForDay(String dateStr) {
    Decimal sum = Decimal.zero;
    for (final e in tourHistory) {
      if (e.dateStr == dateStr && e.isClear) sum += e.profitAmount;
    }
    return sum;
  }

  /// Daily cash flow: exchange in - out + remittance net (myr - cost) for paid + tour charge for clear.
  Decimal getCashFlowForDay(String dateStr) {
    Decimal exIn = Decimal.zero;
    Decimal exOut = Decimal.zero;
    for (final e in exchangeHistory) {
      if (e.dateStr != dateStr) continue;
      if (e.mode == 'sell') exIn += e.myrAmount;
      if (e.mode == 'buy') exOut += e.myrAmount;
    }
    Decimal remNet = Decimal.zero;
    for (final e in remittanceHistory) {
      if (e.dateStr == dateStr && e.isPaid) remNet += e.myrAmount - e.costAmount;
    }
    Decimal tourIn = Decimal.zero;
    for (final e in tourHistory) {
      if (e.dateStr == dateStr && e.isClear) tourIn += e.chargeAmount;
    }
    return exIn - exOut + remNet + tourIn;
  }

  /// All dates that have any data (exchange, remittance, tour, daily sold), newest first.
  List<String> getDistinctDates() {
    final set = <String>{};
    for (final e in exchangeHistory) set.add(e.dateStr);
    for (final e in remittanceHistory) set.add(e.dateStr);
    for (final e in tourHistory) set.add(e.dateStr);
    for (final e in dailySoldProfits) set.add(e.dateStr);
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}

// --- Entry models with full copyWith for editing ---

class MockExchangeEntry {
  final String id;
  final DateTime dateTime;
  final String currency;
  final String mode;
  final Decimal foreignAmount;
  final Decimal myrAmount;
  final Decimal rateUsed;

  MockExchangeEntry({
    required this.id,
    required this.dateTime,
    required this.currency,
    required this.mode,
    required this.foreignAmount,
    required this.myrAmount,
    required this.rateUsed,
  });

  String get dateStr =>
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

  MockExchangeEntry copyWith({
    DateTime? dateTime,
    String? currency,
    String? mode,
    Decimal? foreignAmount,
    Decimal? myrAmount,
    Decimal? rateUsed,
  }) {
    return MockExchangeEntry(
      id: id,
      dateTime: dateTime ?? this.dateTime,
      currency: currency ?? this.currency,
      mode: mode ?? this.mode,
      foreignAmount: foreignAmount ?? this.foreignAmount,
      myrAmount: myrAmount ?? this.myrAmount,
      rateUsed: rateUsed ?? this.rateUsed,
    );
  }
}

/// Daily sold profit (Money Changer) for cash flow.
class DailySoldProfitEntry {
  final String id;
  final DateTime dateTime;
  final Decimal amount;

  DailySoldProfitEntry({
    required this.id,
    required this.dateTime,
    required this.amount,
  });

  String get dateStr =>
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

class MockRemittanceEntry {
  final String id;
  final DateTime dateTime;
  final String customerName;
  final String phone;
  final String bankName;
  final String accountNumber;
  final Decimal myrAmount;
  final Decimal foreignAmount;
  final String currency;
  final Decimal feeAmount;
  final bool isPaid;
  /// Customer rate (foreign per MYR). myrAmount = foreignAmount / exchangeRate.
  final Decimal exchangeRate;
  /// Cost rate (foreign per MYR). costAmount = foreignAmount / fixedRate.
  final Decimal fixedRate;
  /// Actual cost in MYR (RM deduction).
  final Decimal costAmount;
  /// profit = myrAmount - costAmount.
  final Decimal profitAmount;

  MockRemittanceEntry({
    required this.id,
    required this.dateTime,
    required this.customerName,
    this.phone = '',
    this.bankName = '',
    this.accountNumber = '',
    required this.myrAmount,
    required this.foreignAmount,
    required this.currency,
    required this.feeAmount,
    required this.isPaid,
    required this.exchangeRate,
    required this.fixedRate,
    required this.costAmount,
    required this.profitAmount,
  });

  String get dateStr =>
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

  /// Copy-all text for clipboard: name, bank, account number, amount (foreign only). No labels, no phone, no MYR.
  String get copyAllText =>
      '$customerName\n$bankName\n$accountNumber\n$foreignAmount';

  MockRemittanceEntry copyWith({
    DateTime? dateTime,
    String? customerName,
    String? phone,
    String? bankName,
    String? accountNumber,
    Decimal? myrAmount,
    Decimal? foreignAmount,
    String? currency,
    Decimal? feeAmount,
    bool? isPaid,
    Decimal? exchangeRate,
    Decimal? fixedRate,
    Decimal? costAmount,
    Decimal? profitAmount,
  }) {
    return MockRemittanceEntry(
      id: id,
      dateTime: dateTime ?? this.dateTime,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      myrAmount: myrAmount ?? this.myrAmount,
      foreignAmount: foreignAmount ?? this.foreignAmount,
      currency: currency ?? this.currency,
      feeAmount: feeAmount ?? this.feeAmount,
      isPaid: isPaid ?? this.isPaid,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      fixedRate: fixedRate ?? this.fixedRate,
      costAmount: costAmount ?? this.costAmount,
      profitAmount: profitAmount ?? this.profitAmount,
    );
  }
}

class MockTourEntry {
  final String id;
  final DateTime dateTime;
  final String description;
  final String driver;
  final Decimal chargeAmount;
  final Decimal profitAmount;
  final bool isClear;

  MockTourEntry({
    required this.id,
    required this.dateTime,
    required this.description,
    required this.driver,
    required this.chargeAmount,
    required this.profitAmount,
    required this.isClear,
  });

  String get dateStr =>
      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

  MockTourEntry copyWith({
    DateTime? dateTime,
    String? description,
    String? driver,
    Decimal? chargeAmount,
    Decimal? profitAmount,
    bool? isClear,
  }) {
    return MockTourEntry(
      id: id,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      driver: driver ?? this.driver,
      chargeAmount: chargeAmount ?? this.chargeAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      isClear: isClear ?? this.isClear,
    );
  }
}
