// lib/views/exchange/daily_sold_selection_screen.dart
// Standalone page: select which currencies to sell, enter rate per selected, group by rate, profit for selected only.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/mock_data.dart';
import '../../providers/rate_store.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';

class DailySoldSelectionScreen extends StatefulWidget {
  const DailySoldSelectionScreen({super.key});

  @override
  State<DailySoldSelectionScreen> createState() =>
      _DailySoldSelectionScreenState();
}

class _DailySoldSelectionScreenState extends State<DailySoldSelectionScreen> {
  List<MockCurrencyRate> _rates = [];
  final Map<String, bool> _selected = {};
  final Map<String, TextEditingController> _rateControllers = {};
  bool _isLoading = true;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadRates() {
    setState(() {
      _isLoading = true;
      _rates = RateStore.instance.getRates();
      _selected.clear();
      for (final r in _rateControllers.keys.toList()) {
        if (!_rates.any((x) => x.code == r)) {
          _rateControllers[r]?.dispose();
          _rateControllers.remove(r);
        }
      }
      for (final r in _rates) {
        _selected[r.code] = _selected[r.code] ?? false;
        _rateControllers[r.code] ??= TextEditingController();
        final dc = AppConstants.rateDecimalsFor(r.code);
        if (_rateControllers[r.code]!.text.isEmpty &&
            r.currentInventory > Decimal.zero) {
          _rateControllers[r.code]!.text =
              AppFormatters.formatRate(r.displaySellRate, r.code);
        }
      }
      _isLoading = false;
    });
  }

  List<MockCurrencyRate> get _selectedRates {
    return _rates
        .where((r) =>
            _selected[r.code] == true && r.currentInventory > Decimal.zero)
        .toList();
  }

  /// Group selected by entered rate (same rate -> same group).
  Map<String, List<MockCurrencyRate>> get _groupedByRate {
    final map = <String, List<MockCurrencyRate>>{};
    for (final r in _selectedRates) {
      final ctrl = _rateControllers[r.code];
      final rateStr = ctrl?.text.trim() ?? '';
      final key = rateStr.isEmpty ? 'no_rate' : rateStr;
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  Decimal get _totalProfit {
    Decimal sum = Decimal.zero;
    for (final r in _selectedRates) {
      final ctrl = _rateControllers[r.code];
      final sellRate = Decimal.tryParse(ctrl?.text ?? '') ?? Decimal.zero;
      final profit =
          (sellRate - r.averageCost) * r.currentInventory;
      sum += profit;
    }
    return sum;
  }

  bool get _allSelectedHaveRate {
    for (final r in _selectedRates) {
      final ctrl = _rateControllers[r.code];
      if (ctrl == null || ctrl.text.trim().isEmpty) return false;
      if (Decimal.tryParse(ctrl.text) == null) return false;
    }
    return true;
  }

  Future<void> _executeSold() async {
    if (_selectedRates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select at least one currency to sell')),
      );
      return;
    }
    if (!_allSelectedHaveRate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter selling rate for all selected currencies')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Daily Sold'),
        content: Text(
          'Execute daily sold for ${_selectedRates.length} selected currency/currencies?\n\n'
          'Total profit (selected only): MYR ${AppFormatters.formatCurrency(_totalProfit).replaceFirst('MYR ', '')}\n\n'
          'This will reset inventory for selected items only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isExecuting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      HistoryStore.instance.addDailySoldProfit(_totalProfit);
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Daily Sold Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profit (selected only): MYR ${_totalProfit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Inventory for selected currencies has been reset.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Sold Selection')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final withInventory =
        _rates.where((r) => r.currentInventory > Decimal.zero).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Sold Selection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRates,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Select currencies to include in daily sold. Enter rate only for selected. Profit is calculated for selected only.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: withInventory.length,
              itemBuilder: (context, index) {
                final r = withInventory[index];
                final isSelected = _selected[r.code] == true;
                final decimals = AppConstants.rateDecimalsFor(r.code);
                final regex = RegExp('^\\d*\\.?\\d{0,$decimals}\$');
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  _selected[r.code] = v ?? false;
                                  if (v == true &&
                                      (_rateControllers[r.code]?.text
                                              .trim()
                                              .isEmpty ??
                                          true)) {
                                    _rateControllers[r.code]?.text =
                                        AppFormatters.formatRate(
                                            r.displaySellRate, r.code);
                                  }
                                });
                              },
                            ),
                            Text(r.flagEmoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r.code} · ${r.name}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Inventory: ${r.currentInventory.toStringAsFixed(0)} · Avg cost: ${AppFormatters.formatRate(r.averageCost, r.code)}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _rateControllers[r.code],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(regex),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Sell rate (MYR)',
                              isDense: true,
                              suffixText: 'MYR',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Grouped by rate summary
          if (_groupedByRate.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grouped by rate',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  ..._groupedByRate.entries
                      .where((e) => e.key != 'no_rate')
                      .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${e.key} MYR: ${e.value.map((r) => r.code).join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Total profit & Execute
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: SafeArea(
              child: Column(
                children: [
                  if (_selectedRates.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Profit (selected): MYR ${_totalProfit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isExecuting || _selectedRates.isEmpty
                          ? null
                          : _executeSold,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isExecuting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Execute Daily Sold (selected only)',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
