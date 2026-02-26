// lib/views/exchange/exchange_dashboard.dart

import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../providers/mock_data.dart';
import '../../providers/rate_store.dart';
import '../../utils/formatters.dart';
import 'exchange_transaction_screen.dart';
import 'exchange_history_screen.dart';
import 'daily_sold_screen.dart';
import 'daily_sold_selection_screen.dart';
import 'bulk_rate_update_screen.dart';
import 'add_custom_currency_screen.dart';

class ExchangeDashboard extends StatefulWidget {
  const ExchangeDashboard({super.key});

  @override
  State<ExchangeDashboard> createState() => _ExchangeDashboardState();
}

class _ExchangeDashboardState extends State<ExchangeDashboard> {
  List<MockCurrencyRate> _rates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() {
      _isLoading = true;
    });

    await RateStore.instance.loadCustomFromPrefs();
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() {
        _rates = RateStore.instance.getRates();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmRemoveCustom(String code, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove custom currency?'),
        content: Text('Remove "$name" ($code)? It will disappear from the list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await RateStore.instance.removeCustomRate(code);
      _loadRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Changer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddCustomCurrencyScreen()),
              );
              if (added == true) _loadRates();
            },
            tooltip: 'Add custom currency',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExchangeHistoryScreen(),
                ),
              ).then((_) => _loadRates());
            },
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.check_box),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailySoldSelectionScreen(),
                ),
              ).then((_) => _loadRates());
            },
            tooltip: 'Daily Sold Selection',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BulkRateUpdateScreen(),
                ),
              ).then((_) => _loadRates());
            },
            tooltip: 'Bulk rate update',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRates,
            tooltip: 'Refresh Rates',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRates,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _rates.length,
                itemBuilder: (context, index) {
                  final rate = _rates[index];
                  final isCustom = RateStore.instance.isCustomCode(rate.code);
                  return _CurrencyCard(
                    rate: rate,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExchangeTransactionScreen(rate: rate),
                        ),
                      ).then((_) => _loadRates());
                    },
                    onDailySold: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DailySoldScreen(rate: rate),
                        ),
                      ).then((_) => _loadRates());
                    },
                    onRemove: isCustom
                        ? () => _confirmRemoveCustom(rate.code, rate.name)
                        : null,
                  );
                },
              ),
            ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final MockCurrencyRate rate;
  final VoidCallback onTap;
  final VoidCallback onDailySold;
  final VoidCallback? onRemove;

  const _CurrencyCard({
    required this.rate,
    required this.onTap,
    required this.onDailySold,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: rate.currentInventory > Decimal.zero ? onDailySold : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flag and remove (for custom)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rate.flagEmoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                  if (onRemove != null) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Currency Code
              Text(
                rate.code,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              // Currency Name
              Text(
                rate.name,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Divider
              const Divider(),
              const SizedBox(height: 4),

              // Buy Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buy',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppFormatters.formatRate(rate.displayBuyRate, rate.code),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Sell Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sell',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppFormatters.formatRate(rate.displaySellRate, rate.code),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Inventory Indicator
              if (rate.currentInventory > Decimal.zero)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 12,
                        color: Colors.orange[900],
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          rate.currentInventory.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
