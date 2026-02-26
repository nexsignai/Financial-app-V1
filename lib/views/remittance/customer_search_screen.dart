// lib/views/remittance/customer_search_screen.dart

import 'package:flutter/material.dart';
import '../../providers/mock_data.dart';
import 'remittance_transaction_screen.dart';
import 'remittance_history_screen.dart';
import 'remittance_rate_screen.dart';
import 'add_customer_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _searchController = TextEditingController();
  List<MockCustomer> _customers = [];
  List<MockCustomer> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _customers = MockDataProvider.getCustomers();
      _filteredCustomers = _customers;
      _isLoading = false;
    });
  }

  void _filterCustomers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCustomers = _customers;
      });
    } else {
      setState(() {
        _filteredCustomers = _customers
            .where((customer) => customer.matchesSearch(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RemittanceRateScreen(),
                ),
              );
            },
            tooltip: 'Rate Management',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RemittanceHistoryScreen(),
                ),
              );
            },
            tooltip: 'Remittance History',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Name, phone, or account number',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterCustomers,
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(
                        child: Text('No customers found'),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(customer.name[0].toUpperCase()),
                            ),
                            title: Text(customer.name),
                            subtitle: Text(
                              '${customer.phone}\n${customer.bankName} - ${customer.accountNumber}',
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RemittanceTransactionScreen(
                                    customer: customer,
                                  ),
                                ),
                              ).then((_) => _loadCustomers());
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCustomerScreen(),
            ),
          ).then((_) => _loadCustomers());
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
