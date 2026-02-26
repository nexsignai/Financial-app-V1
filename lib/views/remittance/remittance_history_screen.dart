// lib/views/remittance/remittance_history_screen.dart
// Priority sort: Unpaid at top (red), then Paid. Tap to view/edit or toggle status.

import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';
import 'remittance_detail_edit_screen.dart';

class RemittanceHistoryScreen extends StatefulWidget {
  const RemittanceHistoryScreen({super.key});

  @override
  State<RemittanceHistoryScreen> createState() =>
      _RemittanceHistoryScreenState();
}

class _RemittanceHistoryScreenState extends State<RemittanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    HistoryStore.initSampleData();
  }

  @override
  Widget build(BuildContext context) {
    final list = HistoryStore.instance.getSortedRemittanceHistory();
    if (list.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Remittance History')),
        body: const Center(child: Text('No remittance transactions yet.')),
      );
    }
    final attention = list.where((e) => !e.isPaid).toList();
    final completed = list.where((e) => e.isPaid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remittance History'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (attention.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 18, color: Colors.red[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Needs attention (Unpaid)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ...attention.map((e) => _buildCard(e, isPriority: true)),
            const Divider(thickness: 2, height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Completed (Paid)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
            ...completed.map((e) => _buildCard(e, isPriority: false)),
          ] else ...[
            ...list.map((e) => _buildCard(e, isPriority: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(MockRemittanceEntry e, {required bool isPriority}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isPriority ? Colors.red.withValues(alpha: 0.06) : null,
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => RemittanceDetailEditScreen(entry: e),
            ),
          );
          if (updated == true && mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: e.isPaid
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                child: Icon(
                  e.isPaid ? Icons.check_circle : Icons.pending,
                  color: e.isPaid ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isPriority ? Colors.red[900] : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatDateTimePrecise(e.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${e.foreignAmount.toStringAsFixed(0)} ${e.currency} • Fee: ${AppFormatters.formatCurrency(e.feeAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profit: ${AppFormatters.formatCurrency(e.profitAmount >= Decimal.zero ? e.profitAmount : Decimal.parse((-e.profitAmount.toDouble()).toString()))}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatCurrency(e.myrAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: e.isPaid
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.isPaid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: e.isPaid
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view / edit',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
