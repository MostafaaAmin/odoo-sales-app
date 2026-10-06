import 'package:flutter/material.dart';

import '../services/odoo_service.dart';
import 'sales_order_details_screen.dart';

class SalesOrdersScreen extends StatefulWidget {
  const SalesOrdersScreen({
    super.key,
    required this.odooService,
  });

  final OdooService odooService;

  @override
  State<SalesOrdersScreen> createState() =>
      _SalesOrdersScreenState();
}

class _SalesOrdersScreenState
    extends State<SalesOrdersScreen> {
  List<dynamic> orders = [];

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  String cleanValue(dynamic value) {
    if (value == null || value == false) {
      return '';
    }

    return value.toString();
  }

  Future<void> loadOrders() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result =
          await widget.odooService.getSaleOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String getCustomerName(dynamic partner) {
    if (partner is List &&
        partner.length > 1) {
      return cleanValue(partner[1]);
    }

    return '';
  }

  String getStatusLabel(String state) {
    switch (state) {
      case 'draft':
        return 'Quotation';

      case 'sent':
        return 'Quotation Sent';

      case 'sale':
        return 'Sales Order';

      case 'done':
        return 'Locked';

      case 'cancel':
        return 'Cancelled';

      default:
        return state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Orders',
        ),
        actions: [
          IconButton(
            onPressed:
                loading ? null : loadOrders,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          error!,
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        FilledButton(
                          onPressed: loadOrders,
                          child:
                              const Text(
                            'Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No sales orders found',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadOrders,
                      child: ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            orders.length,
                        itemBuilder:
                            (context, index) {
                          final order =
                              orders[index];

                          final orderNumber =
                              cleanValue(
                            order['name'],
                          );

                          final customer =
                              getCustomerName(
                            order[
                                'partner_id'],
                          );

                          final date =
                              cleanValue(
                            order[
                                'date_order'],
                          );

                          final state =
                              cleanValue(
                            order['state'],
                          );

                          final status =
                              getStatusLabel(
                            state,
                          );

                          return ListTile(
                            leading:
                                const Icon(
                              Icons.receipt_long,
                            ),
                            title: Text(
                              orderNumber
                                      .isEmpty
                                  ? 'Unnamed Order'
                                  : orderNumber,
                            ),
                            subtitle: Text(
                              [
                                customer,
                                date,
                              ]
                                  .where(
                                    (value) =>
                                        value
                                            .isNotEmpty,
                                  )
                                  .join(
                                    '\n',
                                  ),
                            ),
                            isThreeLine:
                                customer
                                        .isNotEmpty &&
                                    date.isNotEmpty,
                            trailing: Text(
                              status,
                              textAlign:
                                  TextAlign.right,
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          SalesOrderDetailsScreen(
                                    order: Map<
                                        String,
                                        dynamic>.from(
                                      order,
                                    ),
                                    odooService:
                                        widget
                                            .odooService,
                                  ),
                                ),
                              );

                              if (!mounted) {
                                return;
                              }

                              await loadOrders();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}