import 'package:flutter/material.dart';

import '../services/odoo_service.dart';
import 'customer_details_screen.dart';
import 'login_screen.dart';
import 'sales_orders_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({
    super.key,
    required this.customers,
    required this.odooService,
  });

  final List<dynamic> customers;
  final OdooService odooService;

  @override
  State<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState
    extends State<CustomerListScreen> {
  final TextEditingController searchController =
      TextEditingController();

  late List<dynamic> filteredCustomers;

  bool isInternalUser = false;

  @override
  void initState() {
    super.initState();

    filteredCustomers = List.from(widget.customers);

    searchController.addListener(searchCustomer);

    checkInternalUser();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> checkInternalUser() async {
    try {
      final result =
          await widget.odooService.isInternalUser();

      if (!mounted) return;

      setState(() {
        isInternalUser = result;
      });
    } catch (e) {
      print('Internal user check failed: $e');
    }
  }

  void searchCustomer() {
    final searchText =
        searchController.text.trim().toLowerCase();

    setState(() {
      filteredCustomers =
          widget.customers.where((customer) {
        final name =
            customer['name']
                ?.toString()
                .toLowerCase() ??
            '';

        return name.contains(searchText);
      }).toList();
    });
  }

  Future<void> refreshCustomers() async {
    try {
      final customers =
          await widget.odooService.getCustomers();

      widget.customers.clear();
      widget.customers.addAll(customers);

      searchCustomer();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Refresh failed: $e',
          ),
        ),
      );
    }
  }

  void openSalesOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesOrdersScreen(
          odooService: widget.odooService,
        ),
      ),
    );
  }

Future<void> logout() async {
  await widget.odooService.logout();

  if (!mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) =>
          const LoginScreen(),
    ),
    (route) => false,
  );
}

  String cleanValue(dynamic value) {
    if (value == null || value == false) {
      return '';
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Customers'),
        actions: [
          IconButton(
            onPressed: refreshCustomers,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),

          if (isInternalUser)
            IconButton(
              onPressed: openSalesOrders,
              icon: const Icon(
                Icons.receipt_long,
              ),
              tooltip: 'Sales Orders',
            ),

          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search customer',
                hintText: 'Enter customer name',
                prefixIcon: Icon(
                  Icons.search,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(
                    child: Text(
                      'No customers found',
                    ),
                  )
                : ListView.builder(
                    itemCount:
                        filteredCustomers.length,
                    itemBuilder:
                        (context, index) {
                      final customer =
                          filteredCustomers[index];

                      final name = cleanValue(
                        customer['name'],
                      );

                      final phone = cleanValue(
                        customer['phone'],
                      );

                      final city = cleanValue(
                        customer['city'],
                      );

                      final details = [
                        phone,
                        city,
                      ]
                          .where(
                            (value) =>
                                value.isNotEmpty,
                          )
                          .join(' • ');

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.person,
                          ),
                        ),
                        title: Text(
                          name.isEmpty
                              ? 'Unnamed customer'
                              : name,
                        ),
                        subtitle:
                            details.isEmpty
                                ? null
                                : Text(
                                    details,
                                  ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                        onTap: () async {
                          final updatedCustomer =
                              await Navigator.push<
                                  Map<String,
                                      dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerDetailsScreen(
                                customer: Map<
                                    String,
                                    dynamic>.from(
                                  customer,
                                ),
                                odooService: widget
                                    .odooService,
                              ),
                            ),
                          );

                          if (updatedCustomer ==
                              null) {
                            return;
                          }

                          final customerIndex =
                              widget.customers
                                  .indexWhere(
                            (item) =>
                                item['id'] ==
                                updatedCustomer[
                                    'id'],
                          );

                          if (customerIndex !=
                              -1) {
                            widget.customers[
                                    customerIndex] =
                                updatedCustomer;
                          }

                          searchCustomer();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}