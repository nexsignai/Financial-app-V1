// lib/views/remittance/remittance_rate_screen.dart
// Rate Management: Today's rate for India and Indonesia. Becomes default for new transactions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/remittance_rate_store.dart';

class RemittanceRateScreen extends StatefulWidget {
  const RemittanceRateScreen({super.key});

  @override
  State<RemittanceRateScreen> createState() => _RemittanceRateScreenState();
}

class _RemittanceRateScreenState extends State<RemittanceRateScreen> {
  final _indiaCustomerController = TextEditingController();
  final _indiaCostController = TextEditingController();
  final _indonesiaCustomerController = TextEditingController();
  final _indonesiaCostController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _indiaCustomerController.dispose();
    _indiaCostController.dispose();
    _indonesiaCustomerController.dispose();
    _indonesiaCostController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoading = true);
    await RemittanceRateStore.instance.reload();
    final store = RemittanceRateStore.instance;
    _indiaCustomerController.text = store.indiaCustomerRate.toString();
    _indiaCostController.text = store.indiaCostRate.toString();
    _indonesiaCustomerController.text = store.indonesiaCustomerRate.toString();
    _indonesiaCostController.text = store.indonesiaCostRate.toString();
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final indiaCust = Decimal.tryParse(_indiaCustomerController.text);
    final indiaCost = Decimal.tryParse(_indiaCostController.text);
    final indoCust = Decimal.tryParse(_indonesiaCustomerController.text);
    final indoCost = Decimal.tryParse(_indonesiaCostController.text);
    if (indiaCust == null || indiaCost == null || indoCust == null || indoCost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid rates for both countries')),
      );
      return;
    }
    setState(() => _isSaving = true);
    await RemittanceRateStore.instance.setIndiaRates(customer: indiaCust, cost: indiaCost);
    await RemittanceRateStore.instance.setIndonesiaRates(customer: indoCust, cost: indoCost);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rates saved. They will apply to all new remittance transactions.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Management'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
            tooltip: 'Save rates',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Today's rates are used as defaults for new remittance transactions. Update anytime.",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _RateSection(
              title: 'India (INR)',
              flag: '🇮🇳',
              customerController: _indiaCustomerController,
              costController: _indiaCostController,
              isIdr: false,
            ),
            const SizedBox(height: 24),
            _RateSection(
              title: 'Indonesia (IDR)',
              flag: '🇮🇩',
              customerController: _indonesiaCustomerController,
              costController: _indonesiaCostController,
              isIdr: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Save All Rates'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateSection extends StatelessWidget {
  final String title;
  final String flag;
  final TextEditingController customerController;
  final TextEditingController costController;
  final bool isIdr;

  const _RateSection({
    required this.title,
    required this.flag,
    required this.customerController,
    required this.costController,
    required this.isIdr,
  });

  @override
  Widget build(BuildContext context) {
    final rateDecimals = isIdr ? 6 : 4;
    final rateRegex = RegExp('^\\d*\\.?\\d{0,$rateDecimals}\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(rateRegex),
              ],
              decoration: const InputDecoration(
                labelText: 'Customer rate (MYR per 1 unit)',
                hintText: 'e.g. 0.043 INR, 0.000230 IDR',
                suffixText: 'MYR',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(rateRegex),
              ],
              decoration: const InputDecoration(
                labelText: 'Cost rate (MYR per 1 unit)',
                hintText: 'Used for RM deduction and profit',
                suffixText: 'MYR',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
