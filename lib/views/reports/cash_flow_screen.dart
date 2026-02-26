// lib/views/reports/cash_flow_screen.dart
// Totals are computed from HistoryStore (exchange, remittance, tour history).
// Editing paid/unpaid or clear/unclear in history screens updates these figures.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../utils/formatters.dart';
import '../../providers/history_store.dart';
import 'profit_breakdown_screen.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  final _bankInController = TextEditingController();
  Decimal _bankInAmount = Decimal.zero;

  void _refreshFromStore() {
    HistoryStore.initSampleData();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    HistoryStore.initSampleData();
    HistoryStore.instance.loadOpeningCash();
  }

  Future<void> _editOpeningCash() async {
    final controller = TextEditingController(
      text: _openingCash.toStringAsFixed(2),
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Opening Cash'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Opening cash (MYR)',
            hintText: '0.00',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final text = controller.text;
    controller.dispose();
    if (result == true && mounted) {
      final value = Decimal.tryParse(text);
      if (value != null && value >= Decimal.zero) {
        await HistoryStore.instance.setOpeningCash(value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening cash set to ${AppFormatters.formatCurrency(value)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid amount'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Decimal get _openingCash => HistoryStore.instance.openingCash;
  Decimal get _totalIn => HistoryStore.instance.totalIn;
  Decimal get _totalOut => HistoryStore.instance.totalOut;
  Decimal get _closingCash => _openingCash + _totalIn - _totalOut;
  Decimal get _cashInHand => _closingCash - _bankInAmount;
  Decimal get _exchangeProfit => HistoryStore.instance.exchangeProfitToday;
  Decimal get _remittanceFees => HistoryStore.instance.remittanceFeesTotal;
  Decimal get _remittanceProfit => HistoryStore.instance.remittanceProfitToday;
  Decimal get _tourProfit => HistoryStore.instance.tourProfitTotal;
  Decimal get _netProfit => HistoryStore.instance.netProfit;

  @override
  void dispose() {
    _bankInController.dispose();
    super.dispose();
  }

  Future<void> _recordBankIn() async {
    if (_bankInController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    final amount = Decimal.parse(_bankInController.text);
    
    if (amount > _cashInHand) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient cash in hand'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _bankInAmount += amount;
    });

    _bankInController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bank In recorded: ${AppFormatters.formatCurrency(amount)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfitBreakdownScreen()),
              );
            },
            tooltip: 'Profit Breakdown Table',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFromStore,
            tooltip: 'Refresh from history',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: HistoryStore.instance,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Selector
                Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Today'),
                subtitle: Text(AppFormatters.formatDate(DateTime.now())),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () {
                  // TODO: Show date picker
                },
              ),
            ),
            const SizedBox(height: 16),

            // Cash Summary
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cash Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Opening Cash',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Tap to edit',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(_openingCash),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit_outlined, size: 22, color: Colors.blue[700]),
                        ],
                      ),
                      onTap: _editOpeningCash,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow('Total In', _totalIn, color: Colors.green),
                    _SummaryRow('Total Out', _totalOut, color: Colors.red),
                    const Divider(),
                    _SummaryRow('Closing Cash', _closingCash, bold: true),
                    _SummaryRow('Bank In', _bankInAmount, color: Colors.orange),
                    const Divider(thickness: 2),
                    _SummaryRow('Cash in Hand', _cashInHand, bold: true, large: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Profit Breakdown (today)
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profit Breakdown (Today)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfitBreakdownScreen()),
                            );
                          },
                          icon: const Icon(Icons.table_chart, size: 20),
                          label: const Text('Daily Table'),
                        ),
                      ],
                    ),
                    const Divider(),
                    _SummaryRow('Money Changer Profit', _exchangeProfit),
                    _SummaryRow('Remittance Profit', _remittanceProfit, color: Colors.green),
                    _SummaryRow('Remittance Fees', _remittanceFees),
                    _SummaryRow('Tour Profit', _tourProfit),
                    const Divider(thickness: 2),
                    _SummaryRow('Net Profit', _netProfit, bold: true, large: true, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bank In Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bank In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bankInController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Amount to Bank',
                              hintText: 'Enter amount',
                              prefixIcon: Icon(Icons.account_balance),
                              suffixText: 'MYR',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _recordBankIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(Icons.save),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available: ${AppFormatters.formatCurrency(_cashInHand)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final Decimal amount;
  final bool bold;
  final bool large;
  final Color? color;

  const _SummaryRow(
    this.label,
    this.amount, {
    this.bold = false,
    this.large = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
