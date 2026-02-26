// lib/views/exchange/exchange_history_screen.dart
// Money Changer history: chronological, tap to view/edit details.

import 'package:flutter/material.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';
import 'exchange_detail_edit_screen.dart';

class ExchangeHistoryScreen extends StatefulWidget {
  const ExchangeHistoryScreen({super.key});

  @override
  State<ExchangeHistoryScreen> createState() => _ExchangeHistoryScreenState();
}

class _ExchangeHistoryScreenState extends State<ExchangeHistoryScreen> {
  @override
  void initState() {
    super.initState();
    HistoryStore.initSampleData();
  }

  @override
  Widget build(BuildContext context) {
    final list = HistoryStore.instance.getSortedExchangeHistory();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Changer History'),
      ),
      body: list.isEmpty
          ? const Center(child: Text('No exchange transactions yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final e = list[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: e.mode == 'sell'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      child: Icon(
                        e.mode == 'sell'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: e.mode == 'sell' ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Text(
                      '${e.mode.toUpperCase()} ${e.foreignAmount.toStringAsFixed(0)} ${e.currency}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${AppFormatters.formatDateTimePrecise(e.dateTime)}\n'
                      'Rate: ${AppFormatters.formatRate(e.rateUsed, e.currency)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.formatCurrency(e.myrAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: e.mode == 'sell'
                                ? Colors.green[700]
                                : Colors.blue[700],
                          ),
                        ),
                        Text(
                          e.mode == 'sell' ? 'Received' : 'Paid',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExchangeDetailEditScreen(entry: e),
                        ),
                      );
                      if (updated == true && mounted) setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}
