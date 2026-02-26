// lib/views/remittance/remittance_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/mock_data.dart';
import '../../providers/history_store.dart';
import '../../providers/remittance_rate_store.dart';

class RemittanceTransactionScreen extends StatefulWidget {
  final MockCustomer customer;

  const RemittanceTransactionScreen({super.key, required this.customer});

  @override
  State<RemittanceTransactionScreen> createState() => _RemittanceTransactionScreenState();
}

class _RemittanceTransactionScreenState extends State<RemittanceTransactionScreen> {
  final _myrController = TextEditingController();
  final _foreignController = TextEditingController();
  final _customerRateController = TextEditingController();
  final _costRateController = TextEditingController();
  bool _isPaid = false;
  bool _isCalculating = false;
  bool _ratesLoaded = false;

  bool get _isIdr => widget.customer.currencyCode == 'IDR';

  /// Format decimal for display: at most 6 decimal places, trailing zeros removed.
  static String _formatMax6Decimals(Decimal d) {
    final s = d.toStringAsFixed(6);
    if (s.contains('.')) {
      final trimmed = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return trimmed;
    }
    return s;
  }

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    await RemittanceRateStore.instance.reload();
    final store = RemittanceRateStore.instance;
    if (widget.customer.country == 'India') {
      _customerRateController.text = store.indiaCustomerRate.toString();
      _costRateController.text = store.indiaCostRate.toString();
    } else {
      _customerRateController.text = store.indonesiaCustomerRate.toString();
      _costRateController.text = store.indonesiaCostRate.toString();
    }
    if (mounted) setState(() => _ratesLoaded = true);
  }

  @override
  void dispose() {
    _myrController.dispose();
    _foreignController.dispose();
    _customerRateController.dispose();
    _costRateController.dispose();
    super.dispose();
  }

  /// Bi-directional sync. Only update the other field when this one is the source (prevents infinite loops).
  /// Customer Rate = MYR per 1 unit foreign. MYR = Foreign × Customer Rate; Foreign = MYR / Customer Rate.
  /// No rounding: preserve full precision in stored values.
  void _onMyrChanged(String _) {
    if (_isCalculating) return;
    final customerRate = Decimal.tryParse(_customerRateController.text);
    if (customerRate == null || customerRate <= Decimal.zero) return;
    final myr = Decimal.tryParse(_myrController.text);
    if (myr == null || _myrController.text.isEmpty) return;
    _isCalculating = true;
    try {
      final foreign = (myr / customerRate).toDecimal();
      _foreignController.text = _formatMax6Decimals(foreign);
    } catch (_) {}
    _isCalculating = false;
    setState(() {});
  }

  void _onForeignChanged(String _) {
    if (_isCalculating) return;
    final customerRate = Decimal.tryParse(_customerRateController.text);
    if (customerRate == null || customerRate <= Decimal.zero) return;
    final foreign = Decimal.tryParse(_foreignController.text);
    if (foreign == null || _foreignController.text.isEmpty) return;
    _isCalculating = true;
    try {
      final myr = foreign * customerRate;
      _myrController.text = _formatMax6Decimals(myr);
    } catch (_) {}
    _isCalculating = false;
    setState(() {});
  }

  /// Profit = (Customer Rate - Cost Rate) × Foreign Amount. Cost = Cost Rate × Foreign Amount. No rounding.
  (Decimal costAmount, Decimal profitAmount) _computeCostAndProfit() {
    final foreign = Decimal.tryParse(_foreignController.text) ?? Decimal.zero;
    final customerRate = Decimal.tryParse(_customerRateController.text) ?? Decimal.zero;
    final costRate = Decimal.tryParse(_costRateController.text) ?? Decimal.zero;
    final cost = costRate > Decimal.zero ? (costRate * foreign) : Decimal.zero;
    final profit = (customerRate - costRate) * foreign;
    final profitDecimal = profit is Decimal ? profit : Decimal.parse(profit.toString());
    return (cost, profitDecimal);
  }

  void _copyToClipboard() {
    if (_foreignController.text.isEmpty) return;

    final clipboardText = '${widget.customer.name}\n${widget.customer.bankName}\n'
        '${widget.customer.accountNumber}\n${_foreignController.text}';

    Clipboard.setData(ClipboardData(text: clipboardText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createTransaction() async {
    if (_myrController.text.isEmpty || _foreignController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amounts')),
      );
      return;
    }

    final myrAmount = Decimal.parse(_myrController.text);
    final foreignAmount = Decimal.parse(_foreignController.text);
    final customerRate = Decimal.parse(
        _customerRateController.text.isEmpty ? '1' : _customerRateController.text);
    final costRate = Decimal.parse(
        _costRateController.text.isEmpty ? '1' : _costRateController.text);
    final costAmount = costRate > Decimal.zero
        ? (costRate * foreignAmount)
        : Decimal.zero;
    final profitAmount = (customerRate - costRate) * foreignAmount;
    final profitAmountDecimal = profitAmount is Decimal ? profitAmount : Decimal.parse(profitAmount.toString());
    final feeAmount = Decimal.zero;

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      HistoryStore.instance.addRemittance(
        MockRemittanceEntry(
          id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
          dateTime: DateTime.now(),
          customerName: widget.customer.name,
          phone: widget.customer.phone,
          bankName: widget.customer.bankName,
          accountNumber: widget.customer.accountNumber,
          myrAmount: myrAmount,
          foreignAmount: foreignAmount,
          currency: widget.customer.currencyCode,
          feeAmount: feeAmount,
          isPaid: _isPaid,
          exchangeRate: customerRate,
          fixedRate: costRate,
          costAmount: costAmount,
          profitAmount: profitAmountDecimal,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Remittance created: ${_foreignController.text} ${widget.customer.currencyCode} '
            '(${_isPaid ? "Paid" : "Unpaid"}). View in History.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remittance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(widget.customer.name[0]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.customer.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(widget.customer.phone),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Bank: ${widget.customer.bankName}'),
                    Text('Account: ${widget.customer.accountNumber}'),
                    if (widget.customer.ifscCode != null)
                      Text('IFSC: ${widget.customer.ifscCode}'),
                    Text('Country: ${widget.customer.country}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // MYR Amount — 2 decimals for INR; up to 6 for IDR (preserve precision, no rounding)
            TextField(
              controller: _myrController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('^\\d*\\.?\\d{0,${_isIdr ? 6 : 2}}\$')),
              ],
              decoration: const InputDecoration(
                labelText: 'MYR Amount',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'MYR',
              ),
              onChanged: _onMyrChanged,
            ),
            const SizedBox(height: 16),

            Center(
              child: Icon(
                Icons.swap_vert,
                size: 32,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Foreign Amount — up to 6 decimals
            TextField(
              controller: _foreignController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}$')),
              ],
              decoration: InputDecoration(
                labelText: '${widget.customer.currencyCode} Amount',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: widget.customer.currencyCode,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyToClipboard,
                  tooltip: 'Copy to clipboard',
                ),
              ),
              onChanged: _onForeignChanged,
            ),
            const SizedBox(height: 20),

            // Customer rate (for MYR ↔ Foreign conversion) & Cost rate (for RM deduction / profit)
            TextField(
              controller: _customerRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('^\\d*\\.?\\d{0,${_isIdr ? 6 : 4}}\$')),
              ],
              decoration: const InputDecoration(
                labelText: 'Customer rate (MYR per 1 unit)',
                hintText: 'e.g. 0.043 INR, 0.000230 IDR',
                prefixIcon: Icon(Icons.trending_up),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('^\\d*\\.?\\d{0,${_isIdr ? 6 : 4}}\$')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cost rate (MYR per 1 unit)',
                hintText: 'Used for RM deduction and profit',
                prefixIcon: Icon(Icons.savings),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_ratesLoaded) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final (cost, profit) = _computeCostAndProfit();
                  return Card(
                    color: Colors.amber[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM Deduction (cost): ${_formatMax6Decimals(cost)} MYR',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Instant Profit: ${_formatMax6Decimals(profit)} MYR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: profit >= Decimal.zero
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),

            // Status Toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Paid'),
                          icon: Icon(Icons.check_circle, color: Colors.green),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Unpaid'),
                          icon: Icon(Icons.pending, color: Colors.red),
                        ),
                      ],
                      selected: {_isPaid},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isPaid = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _createTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Create Remittance',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
