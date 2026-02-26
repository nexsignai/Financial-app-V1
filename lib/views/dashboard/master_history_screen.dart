// lib/views/dashboard/master_history_screen.dart
// Unified History View: global list with filters, search, priority sorting.

import 'package:flutter/material.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';
import '../exchange/exchange_detail_edit_screen.dart';
import '../remittance/remittance_detail_edit_screen.dart';
import '../tour/tour_detail_edit_screen.dart';

class MasterHistoryScreen extends StatefulWidget {
  const MasterHistoryScreen({super.key});

  @override
  State<MasterHistoryScreen> createState() => _MasterHistoryScreenState();
}

class _MasterHistoryScreenState extends State<MasterHistoryScreen> {
  final _searchController = TextEditingController();
  HistoryItemType? _serviceFilter;
  bool? _statusFilter; // true = needs attention only, false = completed, null = all
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    HistoryStore.initSampleData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UnifiedHistoryItem> get _filteredList => HistoryStore.instance.getUnifiedHistory(
        serviceFilter: _serviceFilter,
        needsAttentionOnly: _statusFilter,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        searchQuery: _searchController.text,
      );

  void _openDetail(UnifiedHistoryItem item) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _detailScreenFor(item),
      ),
    );
    if (updated == true && mounted) setState(() {});
  }

  Widget _detailScreenFor(UnifiedHistoryItem item) {
    switch (item.type) {
      case HistoryItemType.exchange:
        return ExchangeDetailEditScreen(entry: item.exchange!);
      case HistoryItemType.remittance:
        return RemittanceDetailEditScreen(entry: item.remittance!);
      case HistoryItemType.tour:
        return TourDetailEditScreen(entry: item.tour!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search all transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _serviceFilter == null,
                  onSelected: () => setState(() => _serviceFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Money Changer',
                  selected: _serviceFilter == HistoryItemType.exchange,
                  onSelected: () =>
                      setState(() => _serviceFilter = HistoryItemType.exchange),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Remittance',
                  selected: _serviceFilter == HistoryItemType.remittance,
                  onSelected: () =>
                      setState(() => _serviceFilter = HistoryItemType.remittance),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tour',
                  selected: _serviceFilter == HistoryItemType.tour,
                  onSelected: () =>
                      setState(() => _serviceFilter = HistoryItemType.tour),
                ),
                const SizedBox(width: 16),
                _FilterChip(
                  label: 'Needs attention',
                  selected: _statusFilter == true,
                  onSelected: () => setState(() => _statusFilter = _statusFilter == true ? null : true),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Date range',
                  selected: _dateFrom != null || _dateTo != null,
                  onSelected: () => _pickDateRange(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredList.isEmpty
                ? const Center(child: Text('No transactions match filters.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final item = _filteredList[index];
                      return _UnifiedHistoryTile(
                        item: item,
                        onTap: () => _openDetail(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final from = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? from,
      firstDate: from,
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    final dateFrom = from;
    final dateTo = to;
    if (!mounted) return;
    // ignore: use_build_context_synchronously - we only update state; mounted already checked
    setState(() {
      _dateFrom = dateFrom;
      _dateTo = dateTo;
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _UnifiedHistoryTile extends StatelessWidget {
  final UnifiedHistoryItem item;
  final VoidCallback onTap;

  const _UnifiedHistoryTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPriority = item.needsAttention;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isPriority ? Colors.red.withValues(alpha: 0.06) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: isPriority ? Colors.red : _colorForType(item.type),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(item),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isPriority ? Colors.red[900] : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.formatDateTimePrecise(item.dateTime)} • ${_subtitleFor(item)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isPriority)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Attention',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(UnifiedHistoryItem item) {
    if (item.exchange != null) {
      final e = item.exchange!;
      return '${e.mode.toUpperCase()} ${e.foreignAmount.toStringAsFixed(0)} ${e.currency}';
    }
    if (item.remittance != null) {
      return item.remittance!.customerName;
    }
    if (item.tour != null) {
      return item.tour!.description;
    }
    return '';
  }

  String _subtitleFor(UnifiedHistoryItem item) {
    if (item.exchange != null) return 'Money Changer';
    if (item.remittance != null) {
      return 'Remittance • ${item.remittance!.isPaid ? "Paid" : "Unpaid"}';
    }
    if (item.tour != null) {
      return 'Tour • ${item.tour!.isClear ? "Clear" : "Unclear"}';
    }
    return '';
  }

  Color _colorForType(HistoryItemType type) {
    switch (type) {
      case HistoryItemType.exchange:
        return Colors.blue;
      case HistoryItemType.remittance:
        return Colors.green;
      case HistoryItemType.tour:
        return Colors.orange;
    }
  }
}
