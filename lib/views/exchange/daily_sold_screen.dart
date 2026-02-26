// lib/views/exchange/daily_sold_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/mock_data.dart';
import '../../providers/history_store.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class DailySoldScreen extends StatefulWidget {
  final MockCurrencyRate rate;

  const DailySoldScreen({super.key, required this.rate});

  @override
  State<DailySoldScreen> createState() => _DailySoldScreenState();
}

class _DailySoldScreenState extends State<DailySoldScreen> {
  final _bulkRateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bulkRateController.dispose();
    super.dispose();
  }

  Future<void> _executeSold() async {
    if (_bulkRateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter bulk selling rate')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Daily Sold'),
        content: Text(
          'Are you sure you want to execute daily sold for ${widget.rate.code}?\n\n'
          'This will calculate profit and reset inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bulkRate = Decimal.parse(_bulkRateController.text);
      final profit = (bulkRate - widget.rate.averageCost) * widget.rate.currentInventory;

      // Simulate saving and push profit to cash flow
      await Future.delayed(const Duration(milliseconds: 800));
      HistoryStore.instance.addDailySoldProfit(profit);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Daily Sold Complete!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Currency: ${widget.rate.code}'),
                Text('Volume Sold: ${widget.rate.currentInventory.toStringAsFixed(2)}'),
                Text('Average Cost: ${AppFormatters.formatRate(widget.rate.averageCost, widget.rate.code)}'),
                Text('Selling Rate: ${AppFormatters.formatRate(bulkRate, widget.rate.code)}'),
                const Divider(),
                Text(
                  'Profit: MYR ${profit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Sold - ${widget.rate.code}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Inventory',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.rate.currentInventory.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.rate.code,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                Text(
                  'Average Cost: ${AppFormatters.formatRate(widget.rate.averageCost, widget.rate.code)} MYR',
                  style: const TextStyle(fontSize: 14),
                ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Builder(
              builder: (context) {
                final decimals =
                    AppConstants.rateDecimalsFor(widget.rate.code);
                return TextField(
                  controller: _bulkRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp('^\\d*\\.?\\d{0,$decimals}\$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Bulk Selling Rate',
                    hintText: 'Enter rate to wholesaler',
                    prefixIcon: Icon(Icons.sell),
                    suffixText: 'MYR',
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _executeSold,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Execute Daily Sold',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will calculate profit and reset inventory to 0. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
