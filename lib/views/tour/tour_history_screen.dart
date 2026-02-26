// lib/views/tour/tour_history_screen.dart
// Priority sort: Unclear at top (red), then Clear. Tap to view/edit.

import 'package:flutter/material.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';
import 'tour_detail_edit_screen.dart';

class TourHistoryScreen extends StatefulWidget {
  const TourHistoryScreen({super.key});

  @override
  State<TourHistoryScreen> createState() => _TourHistoryScreenState();
}

class _TourHistoryScreenState extends State<TourHistoryScreen> {
  @override
  void initState() {
    super.initState();
    HistoryStore.initSampleData();
  }

  @override
  Widget build(BuildContext context) {
    final list = HistoryStore.instance.getSortedTourHistory();
    if (list.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tour & Travel History')),
        body: const Center(child: Text('No tour entries yet.')),
      );
    }
    final attention = list.where((e) => !e.isClear).toList();
    final completed = list.where((e) => e.isClear).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour & Travel History'),
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
                    'Needs attention (Unclear)',
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
                'Completed (Clear)',
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

  Widget _buildCard(MockTourEntry e, {required bool isPriority}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isPriority ? Colors.red.withValues(alpha: 0.06) : null,
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TourDetailEditScreen(entry: e),
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
                backgroundColor: e.isClear
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                child: Icon(
                  e.isClear ? Icons.check_circle : Icons.pending,
                  color: e.isClear ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.description,
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
                      '${e.driver} • Charge: ${AppFormatters.formatCurrency(e.chargeAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatCurrency(e.profitAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
                  const Text('Profit', style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: e.isClear
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.isClear ? 'Clear' : 'Unclear',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: e.isClear
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
