// lib/views/exchange/bulk_rate_update_screen.dart
// Centralized table to update all currency Buy/Sell rates at once.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/rate_store.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class BulkRateUpdateScreen extends StatefulWidget {
  const BulkRateUpdateScreen({super.key});

  @override
  State<BulkRateUpdateScreen> createState() => _BulkRateUpdateScreenState();
}

class _BulkRateUpdateScreenState extends State<BulkRateUpdateScreen> {
  late List<_RateRow> _rows;

  @override
  void initState() {
    super.initState();
    final rates = RateStore.instance.getRates();
    _rows = rates
        .map((r) => _RateRow(
              code: r.code,
              name: r.name,
              flagEmoji: r.flagEmoji,
              buy: TextEditingController(
                  text: AppFormatters.formatRate(r.displayBuyRate, r.code)),
              sell: TextEditingController(
                  text: AppFormatters.formatRate(r.displaySellRate, r.code)),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.buy.dispose();
      r.sell.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update all rates?'),
        content: const Text(
          'Are you sure you want to save? This will update buy/sell rates for all currencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final map = <String, ({Decimal buy, Decimal sell})>{};
    for (final r in _rows) {
      final buy = Decimal.tryParse(r.buy.text) ?? Decimal.zero;
      final sell = Decimal.tryParse(r.sell.text) ?? Decimal.zero;
      map[r.code] = (buy: buy, sell: sell);
    }
    RateStore.instance.setRates(map);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rates updated.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Rate Update'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save all',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Update Buy and Sell rates for all currencies. Changes apply across the app.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Currency')),
                    DataColumn(label: Text('Buy rate')),
                    DataColumn(label: Text('Sell rate')),
                  ],
                  rows: _rows.map((r) => DataRow(cells: [
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.flagEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('${r.code}\n${r.name}', style: const TextStyle(fontSize: 12)),
                      ],
                    )),
                    DataCell(Builder(
                      builder: (ctx) {
                        final decimals = AppConstants.rateDecimalsFor(r.code);
                        return SizedBox(
                          width: 120,
                          child: TextField(
                            controller: r.buy,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('^\\d*\\.?\\d{0,$decimals}\$')),
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                        );
                      },
                    )),
                    DataCell(Builder(
                      builder: (ctx) {
                        final decimals = AppConstants.rateDecimalsFor(r.code);
                        return SizedBox(
                          width: 120,
                          child: TextField(
                            controller: r.sell,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp('^\\d*\\.?\\d{0,$decimals}\$')),
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                        );
                      },
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateRow {
  final String code;
  final String name;
  final String flagEmoji;
  final TextEditingController buy;
  final TextEditingController sell;

  _RateRow({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.buy,
    required this.sell,
  });
}
