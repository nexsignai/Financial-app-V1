// lib/views/exchange/add_custom_currency_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../providers/rate_store.dart';

class AddCustomCurrencyScreen extends StatefulWidget {
  const AddCustomCurrencyScreen({super.key});

  @override
  State<AddCustomCurrencyScreen> createState() => _AddCustomCurrencyScreenState();
}

class _AddCustomCurrencyScreenState extends State<AddCustomCurrencyScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _buyRateController = TextEditingController();
  final _sellRateController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _amountController.dispose();
    _buyRateController.dispose();
    _sellRateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty) {
      _showSnack('Enter currency name');
      return;
    }
    if (code.isEmpty) {
      _showSnack('Enter currency code (e.g. XYZ, GOLD)');
      return;
    }
    Decimal amount;
    Decimal buyRate;
    Decimal sellRate;
    try {
      amount = Decimal.parse(_amountController.text.isEmpty ? '0' : _amountController.text);
      buyRate = Decimal.parse(_buyRateController.text.isEmpty ? '0' : _buyRateController.text);
      sellRate = Decimal.parse(_sellRateController.text.isEmpty ? '0' : _sellRateController.text);
    } catch (_) {
      _showSnack('Enter valid numbers for amount and rates');
      return;
    }
    if (amount <= Decimal.zero) {
      _showSnack('Amount must be greater than 0');
      return;
    }
    if (buyRate <= Decimal.zero || sellRate <= Decimal.zero) {
      _showSnack('Buy and sell rates must be greater than 0');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await RateStore.instance.addCustomRate(
        code: code,
        name: name,
        initialAmount: amount,
        buyRate: buyRate,
        sellRate: sellRate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom currency added. It can be sold later from Money Changer.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Custom Currency'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add a currency not in the default list. Set name, code, initial amount (inventory), and buy/sell rates in MYR. The amount will be available to sell later from Money Changer.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Currency name',
                hintText: 'e.g. Gold 1g, Custom Token',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Currency code',
                hintText: 'e.g. GOLD, XYZ (unique, no spaces)',
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
                LengthLimitingTextInputFormatter(12),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Initial amount (inventory)',
                hintText: 'Available to be sold later',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _buyRateController,
              decoration: const InputDecoration(
                labelText: 'Buy rate (MYR per unit)',
                hintText: 'e.g. 4.50',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sellRateController,
              decoration: const InputDecoration(
                labelText: 'Sell rate (MYR per unit)',
                hintText: 'e.g. 4.70',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add currency'),
            ),
          ],
        ),
      ),
    );
  }
}
