import 'package:flutter/material.dart';

import '../services/odoo_service.dart';

class SalesOrderDetailsScreen extends StatefulWidget {
  const SalesOrderDetailsScreen({
    super.key,
    required this.order,
    required this.odooService,
  });

  final Map<String, dynamic> order;
  final OdooService odooService;

  @override
  State<SalesOrderDetailsScreen> createState() =>
      _SalesOrderDetailsScreenState();
}

class _SalesOrderDetailsScreenState
    extends State<SalesOrderDetailsScreen> {
  List<dynamic> lines = [];

  bool loading = true;
  bool confirming = false;

  String? error;

  @override
  void initState() {
    super.initState();
    loadLines();
  }

  int? getOrderId() {
    final value = widget.order['id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  Future<void> loadLines() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final orderId = getOrderId();

      if (orderId == null) {
        throw Exception(
          'Invalid sales order ID',
        );
      }

      final result =
          await widget.odooService
              .getSaleOrderLines(
        orderId,
      );

      if (!mounted) return;

      setState(() {
        lines = result;
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

  String relationName(dynamic value) {
    if (value is List &&
        value.length > 1) {
      return cleanValue(
        value[1],
      );
    }

    return '';
  }

  String cleanValue(dynamic value) {
    if (value == null ||
        value == false) {
      return '';
    }

    return value.toString();
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

  bool canConfirm() {
    final state =
        cleanValue(
          widget.order['state'],
        );

    return state == 'draft' ||
        state == 'sent';
  }

  Future<void> confirmOrder() async {
    final orderId = getOrderId();

    if (orderId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid sales order ID',
          ),
        ),
      );

      return;
    }

    setState(() {
      confirming = true;
    });

    try {
      await widget.odooService
          .confirmSaleOrder(
        orderId,
      );

      widget.order['state'] = 'sale';

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Sales order confirmed successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Confirm failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber =
        cleanValue(
          widget.order['name'],
        );

    final customer =
        relationName(
          widget.order['partner_id'],
        );

    final orderDate =
        cleanValue(
          widget.order['date_order'],
        );

    final state =
        cleanValue(
          widget.order['state'],
        );

    final amountTotal =
        cleanValue(
          widget.order['amount_total'],
        );

    final currency =
        relationName(
          widget.order['currency_id'],
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          orderNumber.isEmpty
              ? 'Sales Order'
              : orderNumber,
        ),
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
                        Text(
                          error!,
                          textAlign:
                              TextAlign.center,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        FilledButton(
                          onPressed: loadLines,
                          child:
                              const Text(
                            'Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  children: [
                    Text(
                      orderNumber.isEmpty
                          ? 'Sales Order'
                          : orderNumber,
                      style:
                          const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'Customer',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      customer.isEmpty
                          ? 'No customer'
                          : customer,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'Order Date',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      orderDate.isEmpty
                          ? 'No date available'
                          : orderDate,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      getStatusLabel(
                        state,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (lines.isEmpty)
                      const Text(
                        'No products found',
                      )
                    else
                      ...lines.map(
                        (line) {
                          final product =
                              relationName(
                            line[
                                'product_id'],
                          );

                          final description =
                              cleanValue(
                            line['name'],
                          );

                          final quantity =
                              cleanValue(
                            line[
                                'product_uom_qty'],
                          );

                          final unitPrice =
                              cleanValue(
                            line[
                                'price_unit'],
                          );

                          final subtotal =
                              cleanValue(
                            line[
                                'price_subtotal'],
                          );

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    product
                                            .isEmpty
                                        ? description
                                        : product,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  if (description
                                          .isNotEmpty &&
                                      description !=
                                          product) ...[
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      description,
                                    ),
                                  ],

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Text(
                                    'Quantity: $quantity',
                                  ),

                                  Text(
                                    'Unit price: $unitPrice $currency',
                                  ),

                                  Text(
                                    'Subtotal: $subtotal $currency',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 16,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        Text(
                          '$amountTotal $currency',
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    if (canConfirm())
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            FilledButton.icon(
                          onPressed:
                              confirming
                                  ? null
                                  : confirmOrder,
                          icon: confirming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons.check,
                                ),
                          label: Text(
                            confirming
                                ? 'Confirming...'
                                : 'Confirm Order',
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}