// lib/views/tour/tour_detail_edit_screen.dart
// View + Edit with confirmation. Updates totals on save.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';

class TourDetailEditScreen extends StatefulWidget {
  final MockTourEntry entry;

  const TourDetailEditScreen({super.key, required this.entry});

  @override
  State<TourDetailEditScreen> createState() => _TourDetailEditScreenState();
}

class _TourDetailEditScreenState extends State<TourDetailEditScreen> {
  late MockTourEntry _entry;
  bool _editMode = false;
  late TextEditingController _descController;
  late TextEditingController _chargeController;
  late TextEditingController _profitController;
  late String _driver;
  late bool _isClear;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _descController = TextEditingController(text: _entry.description);
    _chargeController = TextEditingController(text: _entry.chargeAmount.toStringAsFixed(2));
    _profitController = TextEditingController(text: _entry.profitAmount.toStringAsFixed(2));
    _driver = _entry.driver;
    _isClear = _entry.isClear;
  }

  @override
  void dispose() {
    _descController.dispose();
    _chargeController.dispose();
    _profitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text(
          'Are you sure you want to save? This will update your totals and cash flow.',
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
    final chargeAmount = Decimal.tryParse(_chargeController.text) ?? _entry.chargeAmount;
    final profitAmount = Decimal.tryParse(_profitController.text) ?? _entry.profitAmount;
    final updated = _entry.copyWith(
      description: _descController.text,
      driver: _driver,
      chargeAmount: chargeAmount,
      profitAmount: profitAmount,
      isClear: _isClear,
    );
    HistoryStore.instance.updateTour(updated);
    if (mounted) {
      setState(() => _entry = updated);
      _editMode = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved. Totals updated.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete tour?'),
        content: const Text(
          'This transaction will be removed from history. Profit breakdown and cash flow will update. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    HistoryStore.instance.deleteTour(_entry.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted.'), backgroundColor: Colors.orange),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Tour' : 'Tour Details'),
        actions: [
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editMode = true),
              tooltip: 'Edit',
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: 'Save',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _editMode ? _buildEditForm() : _buildView(),
      ),
    );
  }

  Widget _buildView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('Date & time', AppFormatters.formatDateTimePrecise(_entry.dateTime)),
                _DetailRow('Description', _entry.description),
                _DetailRow('Driver', _entry.driver),
                _DetailRow('Charge amount', AppFormatters.formatCurrency(_entry.chargeAmount)),
                _DetailRow('Profit amount', AppFormatters.formatCurrency(_entry.profitAmount)),
                _DetailRow(
                  'Status',
                  _entry.isClear ? 'Clear' : 'Unclear',
                  valueColor: _entry.isClear ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _deleteTransaction,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete transaction'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _descController,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _driver,
          decoration: const InputDecoration(labelText: 'Driver'),
          items: AppConstants.drivers
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) => setState(() => _driver = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chargeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Charge amount',
            suffixText: 'MYR',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _profitController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Profit amount',
            suffixText: 'MYR',
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Clear')),
            ButtonSegment(value: false, label: Text('Unclear')),
          ],
          selected: {_isClear},
          onSelectionChanged: (s) => setState(() => _isClear = s.first),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
