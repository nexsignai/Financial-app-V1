// lib/views/reports/profit_breakdown_screen.dart
// Unified Profit Breakdown Table: daily history with Remittance, Money Changer, Tour profits and cash flow.

import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';

class ProfitBreakdownScreen extends StatefulWidget {
  const ProfitBreakdownScreen({super.key});

  @override
  State<ProfitBreakdownScreen> createState() => _ProfitBreakdownScreenState();
}

class _ProfitBreakdownScreenState extends State<ProfitBreakdownScreen> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    HistoryStore.initSampleData();
  }

  /// Display profit as positive (absolute value) and green.
  static Decimal _abs(Decimal d) =>
      d >= Decimal.zero ? d : Decimal.parse((-d.toDouble()).toString());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HistoryStore.instance,
      builder: (context, _) {
        final store = HistoryStore.instance;
        final dates = store.getDistinctDates();
        if (dates.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profit Breakdown')),
            body: const Center(
              child: Text('No transaction history yet. Add remittance, exchange, or tour entries.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profit Breakdown Table'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Daily history: Remittance (real-time), Money Changer (on Daily Sold), Tour (when Paid/Clear).',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ...dates.map((dateStr) => _DayCard(dateStr: dateStr)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dateStr;

  const _DayCard({required this.dateStr});

  static Decimal _abs(Decimal d) =>
      d >= Decimal.zero ? d : Decimal.parse((-d.toDouble()).toString());

  @override
  Widget build(BuildContext context) {
    final store = HistoryStore.instance;
    final rem = store.getRemittanceProfitForDay(dateStr);
    final mc = store.getMoneyChangerProfitForDay(dateStr);
    final tour = store.getTourProfitForDay(dateStr);
    final totalProfit = _abs(rem) + _abs(mc) + _abs(tour);
    final cashFlow = store.getCashFlowForDay(dateStr);

    final date = _parseDate(dateStr);
    final isToday = dateStr == HistoryStore.todayStr();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isToday ? 'Today' : AppFormatters.formatDate(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: const Text('Today'),
                      backgroundColor: Colors.green.shade100,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            _ProfitRow('Remittance Profit', rem, green: true),
            _ProfitRow('Money Changer Profit', mc, green: true),
            _ProfitRow('Tour Profit', tour, green: true),
            const Divider(height: 12),
            _ProfitRow('Total Daily Profit', totalProfit, bold: true),
            _ProfitRow('Daily Cash Flow', cashFlow, bold: true, color: cashFlow >= Decimal.zero ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

class _ProfitRow extends StatelessWidget {
  final String label;
  final Decimal amount;
  final bool green;
  final bool bold;
  final Color? color;

  const _ProfitRow(
    this.label,
    this.amount, {
    this.green = false,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayAmount = amount >= Decimal.zero ? amount : Decimal.parse((-amount.toDouble()).toString());
    final useColor = color ?? (green ? Colors.green.shade700 : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            AppFormatters.formatCurrency(displayAmount),
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'monospace',
              color: useColor,
            ),
          ),
        ],
      ),
    );
  }
}
