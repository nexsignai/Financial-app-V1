// lib/views/remittance/remittance_detail_edit_screen.dart
// View + Copy All + Edit with confirmation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/history_store.dart';
import '../../utils/formatters.dart';

class RemittanceDetailEditScreen extends StatefulWidget {
  final MockRemittanceEntry entry;

  const RemittanceDetailEditScreen({super.key, required this.entry});

  @override
  State<RemittanceDetailEditScreen> createState() =>
      _RemittanceDetailEditScreenState();
}

class _RemittanceDetailEditScreenState extends State<RemittanceDetailEditScreen> {
  late MockRemittanceEntry _entry;
  bool _editMode = false;
  late TextEditingController _myrController;
  late TextEditingController _foreignController;
  late TextEditingController _feeController;
  late TextEditingController _exchangeRateController;
  late TextEditingController _fixedRateController;
  late bool _isPaid;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _myrController = TextEditingController(text: _entry.myrAmount.toStringAsFixed(2));
    _foreignController = TextEditingController(text: _entry.foreignAmount.toStringAsFixed(0));
    _feeController = TextEditingController(text: _entry.feeAmount.toStringAsFixed(2));
    _exchangeRateController = TextEditingController(text: _entry.exchangeRate.toString());
    _fixedRateController = TextEditingController(text: _entry.fixedRate.toString());
    _isPaid = _entry.isPaid;
  }

  @override
  void dispose() {
    _myrController.dispose();
    _foreignController.dispose();
    _feeController.dispose();
    _exchangeRateController.dispose();
    _fixedRateController.dispose();
    super.dispose();
  }

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: _entry.copyAllText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied all details to clipboard')),
    );
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete remittance?'),
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
    HistoryStore.instance.deleteRemittance(_entry.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted.'), backgroundColor: Colors.orange),
      );
      Navigator.pop(context, true);
    }
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
    final myrAmount = Decimal.tryParse(_myrController.text) ?? _entry.myrAmount;
    final foreignAmount = Decimal.tryParse(_foreignController.text) ?? _entry.foreignAmount;
    final feeAmount = Decimal.tryParse(_feeController.text) ?? _entry.feeAmount;
    final exchangeRate = Decimal.tryParse(_exchangeRateController.text) ?? _entry.exchangeRate;
    final fixedRate = Decimal.tryParse(_fixedRateController.text) ?? _entry.fixedRate;
    // Rates = MYR per 1 unit foreign. Cost = Cost rate × Foreign. Profit = (Customer - Cost) × Foreign.
    final costAmount = fixedRate > Decimal.zero
        ? (fixedRate * foreignAmount)
        : _entry.costAmount;
    final profitProduct = (exchangeRate - fixedRate) * foreignAmount;
    final profitAmount = profitProduct is Decimal ? profitProduct : Decimal.parse(profitProduct.toString());
    final updated = _entry.copyWith(
      myrAmount: myrAmount,
      foreignAmount: foreignAmount,
      feeAmount: feeAmount,
      isPaid: _isPaid,
      exchangeRate: exchangeRate,
      fixedRate: fixedRate,
      costAmount: costAmount,
      profitAmount: profitAmount,
    );
    HistoryStore.instance.updateRemittance(updated);
    if (mounted) {
      setState(() => _entry = updated);
      _editMode = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved. Totals updated.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Remittance' : 'Remittance Details'),
        actions: [
          if (!_editMode) ...[
            IconButton(
              icon: const Icon(Icons.copy_all),
              onPressed: _copyAll,
              tooltip: 'Copy All',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editMode = true),
              tooltip: 'Edit',
            ),
          ] else
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
                _DetailRow('Customer', _entry.customerName),
                if (_entry.phone.isNotEmpty) _DetailRow('Phone', _entry.phone),
                if (_entry.bankName.isNotEmpty) _DetailRow('Bank', _entry.bankName),
                if (_entry.accountNumber.isNotEmpty) _DetailRow('Account', _entry.accountNumber),
                _DetailRow('MYR amount', AppFormatters.formatCurrency(_entry.myrAmount)),
                _DetailRow('Foreign amount', '${_entry.foreignAmount.toStringAsFixed(0)} ${_entry.currency}'),
                _DetailRow('Customer rate', _entry.exchangeRate.toString()),
                _DetailRow('Cost rate', _entry.fixedRate.toString()),
                _DetailRow('RM deduction (cost)', AppFormatters.formatCurrency(_entry.costAmount)),
                _DetailRow('Profit', AppFormatters.formatCurrency(_entry.profitAmount),
                    valueColor: _entry.profitAmount >= Decimal.zero ? Colors.green : Colors.red),
                _DetailRow('Fee', AppFormatters.formatCurrency(_entry.feeAmount)),
                _DetailRow(
                  'Status',
                  _entry.isPaid ? 'Paid' : 'Unpaid',
                  valueColor: _entry.isPaid ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _copyAll,
          icon: const Icon(Icons.copy_all),
          label: const Text('Copy All (banking & contact info)'),
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
          controller: _myrController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(labelText: 'MYR amount', suffixText: 'MYR'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _foreignController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Foreign amount',
            suffixText: _entry.currency,
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final decimals = _entry.currency == 'IDR' ? 6 : 4;
            return TextField(
              controller: _exchangeRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('^\\d*\\.?\\d{0,$decimals}\$')),
              ],
              decoration: const InputDecoration(
                labelText: 'Customer rate',
                suffixText: 'per MYR',
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final decimals = _entry.currency == 'IDR' ? 6 : 4;
            return TextField(
              controller: _fixedRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('^\\d*\\.?\\d{0,$decimals}\$')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cost rate',
                suffixText: 'per MYR',
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _feeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(labelText: 'Fee amount', suffixText: 'MYR'),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Paid')),
            ButtonSegment(value: false, label: Text('Unpaid')),
          ],
          selected: {_isPaid},
          onSelectionChanged: (s) => setState(() => _isPaid = s.first),
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
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
