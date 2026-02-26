// lib/views/tour/tour_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';
import '../../utils/constants.dart';
import '../../providers/history_store.dart';
import 'tour_history_screen.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final _descriptionController = TextEditingController();
  final _chargeController = TextEditingController();
  final _profitController = TextEditingController();
  String _selectedDriver = AppConstants.drivers[0];
  bool _isClear = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _chargeController.dispose();
    _profitController.dispose();
    super.dispose();
  }

  Future<void> _createTour() async {
    if (_descriptionController.text.isEmpty ||
        _chargeController.text.isEmpty ||
        _profitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final chargeAmount = Decimal.parse(_chargeController.text);
    final profitAmount = Decimal.parse(_profitController.text);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      HistoryStore.instance.addTour(
        MockTourEntry(
          id: 'tour_${DateTime.now().millisecondsSinceEpoch}',
          dateTime: DateTime.now(),
          description: _descriptionController.text,
          driver: _selectedDriver,
          chargeAmount: chargeAmount,
          profitAmount: profitAmount,
          isClear: _isClear,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tour created: ${_descriptionController.text} '
            '(${_isClear ? "Clear" : "Unclear"}). View in History.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _descriptionController.clear();
      _chargeController.clear();
      _profitController.clear();
      setState(() {
        _selectedDriver = AppConstants.drivers[0];
        _isClear = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour & Travel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TourHistoryScreen(),
                ),
              );
            },
            tooltip: 'Tour History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only the Profit Amount affects cash flow, not the Charge Amount.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Airport transfer to KLIA',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedDriver,
              decoration: const InputDecoration(
                labelText: 'Driver',
                prefixIcon: Icon(Icons.person),
              ),
              items: AppConstants.drivers.map((driver) {
                return DropdownMenuItem(
                  value: driver,
                  child: Text(driver),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDriver = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _chargeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Charge Amount (Record Only)',
                hintText: 'Total charged to customer',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'MYR',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _profitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Profit Amount (Goes to Cash Flow)',
                hintText: 'Net profit from this tour',
                prefixIcon: const Icon(Icons.trending_up),
                suffixText: 'MYR',
                filled: true,
                fillColor: Colors.green[50],
              ),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tour Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Clear'),
                          icon: Icon(Icons.check_circle, color: Colors.green),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Unclear'),
                          icon: Icon(Icons.pending, color: Colors.orange),
                        ),
                      ],
                      selected: {_isClear},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isClear = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _createTour,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Create Tour Entry',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
