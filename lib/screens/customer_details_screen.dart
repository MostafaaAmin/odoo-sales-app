import 'package:flutter/material.dart';

import '../services/odoo_service.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({
    super.key,
    required this.customer,
    required this.odooService,
  });

  final Map<String, dynamic> customer;
  final OdooService odooService;

  @override
  State<CustomerDetailsScreen> createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState
    extends State<CustomerDetailsScreen> {
  late final TextEditingController phoneController;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    phoneController = TextEditingController(
      text: cleanValue(widget.customer['phone']),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String cleanValue(dynamic value) {
    if (value == null || value == false) {
      return '';
    }

    return value.toString();
  }

  String getRelationName(dynamic value) {
    if (value is List && value.length > 1) {
      return cleanValue(value[1]);
    }

    return '';
  }

  String getAddress() {
    final street =
        cleanValue(widget.customer['street']);

    final street2 =
        cleanValue(widget.customer['street2']);

    final city =
        cleanValue(widget.customer['city']);

    final zip =
        cleanValue(widget.customer['zip']);

    final state =
        getRelationName(
          widget.customer['state_id'],
        );

    final country =
        getRelationName(
          widget.customer['country_id'],
        );

    final addressParts = [
      street,
      street2,
      zip,
      city,
      state,
      country,
    ].where(
      (value) => value.isNotEmpty,
    ).toList();

    return addressParts.join(', ');
  }

  Future<void> savePhone() async {
    final newPhone =
        phoneController.text.trim();

    if (newPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a phone number',
          ),
        ),
      );

      return;
    }

    final idValue = widget.customer['id'];

    final customerId = idValue is int
        ? idValue
        : int.tryParse(idValue.toString());

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid customer ID',
          ),
        ),
      );

      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await widget.odooService
          .updateCustomerPhone(
        customerId,
        newPhone,
      );

      widget.customer['phone'] = newPhone;

      if (!mounted) return;

      Navigator.pop(
        context,
        widget.customer,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        cleanValue(widget.customer['name']);

    final email =
        cleanValue(widget.customer['email']);

    final address = getAddress();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Details',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            name.isEmpty
                ? 'Unnamed Customer'
                : name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          TextField(
            controller: phoneController,
            keyboardType:
                TextInputType.phone,
            decoration:
                const InputDecoration(
              labelText: 'Phone',
              prefixIcon:
                  Icon(Icons.phone),
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  saving ? null : savePhone,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                saving
                    ? 'Saving...'
                    : 'Save Phone',
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            email.isEmpty
                ? 'No email available'
                : email,
          ),

          const SizedBox(height: 24),

          const Text(
            'Address',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            address.isEmpty
                ? 'No address available'
                : address,
          ),
        ],
      ),
    );
  }
}