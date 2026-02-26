// lib/views/exchange/exchange_detail_edit_screen.dart
// View + Edit with confirmation. Updates totals on save.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';

class ExchangeDetailEditScreen extends StatefulWidget {
  final MockExchangeEntry entry;

  const ExchangeDetailEditScreen({super.key, required this.entry});

  @override
  State<ExchangeDetailEditScreen> createState() =>
      _ExchangeDetailEditScreenState();
}

class _ExchangeDetailEditScreenState extends State<ExchangeDetailEditScreen> {
  late MockExchangeEntry _entry;
  bool _editMode = false;
  late TextEditingController _foreignController;
  late TextEditingController _myrController;
  late TextEditingController _rateController;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _foreignController = TextEditingController(text: _entry.foreignAmount.toStringAsFixed(2));
    _myrController = TextEditingController(text: _entry.myrAmount.toStringAsFixed(2));
    _rateController = TextEditingController(
        text: AppFormatters.formatRate(_entry.rateUsed, _entry.currency));
    _mode = _entry.mode;
  }

  @override
  void dispose() {
    _foreignController.dispose();
    _myrController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _recalculate() {
    try {
      final rate = Decimal.parse(_rateController.text);
      if (_mode == 'sell') {
        final foreign = Decimal.parse(_foreignController.text);
        _myrController.text = (foreign * rate).toStringAsFixed(2);
      } else {
        final myr = Decimal.parse(_myrController.text);
        if (rate > Decimal.zero) {
          final f = (myr / rate).toDecimal();
          _foreignController.text = f.toStringAsFixed(2);
        }
      }
    } catch (_) {}
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
    final foreignAmount = Decimal.tryParse(_foreignController.text) ?? _entry.foreignAmount;
    final myrAmount = Decimal.tryParse(_myrController.text) ?? _entry.myrAmount;
    final rateUsed = Decimal.tryParse(_rateController.text) ?? _entry.rateUsed;
    final updated = _entry.copyWith(
      mode: _mode,
      foreignAmount: foreignAmount,
      myrAmount: myrAmount,
      rateUsed: rateUsed,
    );
    HistoryStore.instance.updateExchange(updated);
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
        title: const Text('Delete exchange?'),
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
    HistoryStore.instance.deleteExchange(_entry.id);
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
        title: Text(_editMode ? 'Edit Exchange' : 'Exchange Details'),
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
                _DetailRow('Currency', _entry.currency),
                _DetailRow('Mode', _entry.mode.toUpperCase()),
                _DetailRow('Foreign amount', '${_entry.foreignAmount.toStringAsFixed(2)} ${_entry.currency}'),
                _DetailRow('MYR amount', AppFormatters.formatCurrency(_entry.myrAmount)),
                _DetailRow('Rate used', AppFormatters.formatRate(_entry.rateUsed, _entry.currency)),
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
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'buy', label: Text('Buy')),
            ButtonSegment(value: 'sell', label: Text('Sell')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) {
            setState(() {
              _mode = s.first;
              _recalculate();
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _foreignController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: '${_entry.currency} amount',
            suffixText: _entry.currency,
          ),
          onChanged: (_) => _recalculate(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _myrController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'MYR amount',
            suffixText: 'MYR',
          ),
          onChanged: (_) => _recalculate(),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final decimals = AppConstants.rateDecimalsFor(_entry.currency);
            return TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('^\\d*\\.?\\d{0,$decimals}\$')),
              ],
              decoration: const InputDecoration(labelText: 'Rate'),
              onChanged: (_) => _recalculate(),
            );
          },
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

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
