// lib/views/exchange/exchange_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/mock_data.dart';
import '../../providers/history_store.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

enum ExchangeMode { buy, sell }

class ExchangeTransactionScreen extends StatefulWidget {
  final MockCurrencyRate rate;

  const ExchangeTransactionScreen({super.key, required this.rate});

  @override
  State<ExchangeTransactionScreen> createState() => _ExchangeTransactionScreenState();
}

class _ExchangeTransactionScreenState extends State<ExchangeTransactionScreen> {
  ExchangeMode _mode = ExchangeMode.buy;
  final _foreignController = TextEditingController();
  final _myrController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _rateController.text =
        AppFormatters.formatRate(widget.rate.displayBuyRate, widget.rate.code);
  }

  @override
  void dispose() {
    _foreignController.dispose();
    _myrController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculate(String changedField) {
    if (_isCalculating) return;
    
    setState(() {
      _isCalculating = true;
    });

    try {
      final rate = Decimal.parse(_rateController.text.isEmpty ? '0' : _rateController.text);

      if (changedField == 'foreign' && _foreignController.text.isNotEmpty) {
        final foreign = Decimal.parse(_foreignController.text);
        final myr = foreign * rate;
        _myrController.text = myr.toStringAsFixed(2);
      } else if (changedField == 'myr' && _myrController.text.isNotEmpty) {
        final myr = Decimal.parse(_myrController.text);
        final foreign = rate > Decimal.zero ? (myr / rate).toDecimal() : Decimal.zero;
        _foreignController.text = foreign.toStringAsFixed(2);
      }
    } catch (e) {
      // Invalid input
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<void> _createTransaction() async {
    if (_foreignController.text.isEmpty || _myrController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amounts')),
      );
      return;
    }

    final foreignAmount = Decimal.parse(_foreignController.text);
    final myrAmount = Decimal.parse(_myrController.text);
    final rateUsed = Decimal.parse(_rateController.text.isEmpty ? '1' : _rateController.text);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      HistoryStore.instance.addExchange(
        MockExchangeEntry(
          id: 'ex_${DateTime.now().millisecondsSinceEpoch}',
          dateTime: DateTime.now(),
          currency: widget.rate.code,
          mode: _mode == ExchangeMode.buy ? 'buy' : 'sell',
          foreignAmount: foreignAmount,
          myrAmount: myrAmount,
          rateUsed: rateUsed,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction created: ${_mode == ExchangeMode.buy ? "Bought" : "Sold"} '
            '${_foreignController.text} ${widget.rate.code}. View in History.',
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
        title: Text('${widget.rate.code} Exchange'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Toggle
            SegmentedButton<ExchangeMode>(
              segments: const [
                ButtonSegment(
                  value: ExchangeMode.buy,
                  label: Text('Buy'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: ExchangeMode.sell,
                  label: Text('Sell'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (Set<ExchangeMode> newSelection) {
                setState(() {
                  _mode = newSelection.first;
                  _rateController.text = _mode == ExchangeMode.buy
                      ? AppFormatters.formatRate(
                          widget.rate.displayBuyRate, widget.rate.code)
                      : AppFormatters.formatRate(
                          widget.rate.displaySellRate, widget.rate.code);
                  _calculate('foreign');
                });
              },
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _mode == ExchangeMode.buy ? Colors.green[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _mode == ExchangeMode.buy ? Colors.green : Colors.blue,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _mode == ExchangeMode.buy ? Colors.green[700] : Colors.blue[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _mode == ExchangeMode.buy
                          ? 'We pay MYR and receive ${widget.rate.code}'
                          : 'We pay ${widget.rate.code} and receive MYR',
                      style: TextStyle(
                        fontSize: 12,
                        color: _mode == ExchangeMode.buy ? Colors.green[900] : Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Foreign Amount
            TextField(
              controller: _foreignController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: '${widget.rate.code} Amount',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: widget.rate.code,
              ),
              onChanged: (_) => _calculate('foreign'),
            ),
            const SizedBox(height: 16),

            // Swap Icon
            Center(
              child: Icon(
                Icons.swap_vert,
                size: 32,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // MYR Amount
            TextField(
              controller: _myrController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'MYR Amount',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'MYR',
              ),
              onChanged: (_) => _calculate('myr'),
            ),
            const SizedBox(height: 20),

            // Divider
            const Divider(),
            const SizedBox(height: 20),

            // Rate Field (Editable!) — IDR allows 6 decimals
            Builder(
              builder: (context) {
                final decimals =
                    AppConstants.rateDecimalsFor(widget.rate.code);
                return TextField(
                  controller: _rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp('^\\d*\\.?\\d{0,$decimals}\$')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Exchange Rate (Editable)',
                    prefixIcon: const Icon(Icons.trending_up),
                    helperText: 'You can edit this for VIP customers',
                    filled: true,
                    fillColor: Colors.amber[50],
                  ),
                  onChanged: (_) => _calculate('foreign'),
                );
              },
            ),
            const SizedBox(height: 20),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'e.g., VIP customer, special rate',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _createTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
