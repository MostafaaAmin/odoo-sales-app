import 'package:flutter/material.dart';

import '../services/odoo_service.dart';
import 'customer_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter username and password',
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final odooService = OdooService();

      await odooService.login(
        username,
        password,
      );

      final customers =
          await odooService.getCustomers();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CustomerListScreen(
            customers: customers,
            odooService: odooService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration:
                    const InputDecoration(
                  labelText: 'Username',
                  prefixIcon:
                      Icon(Icons.person),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      Icon(Icons.lock),
                  border:
                      OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  if (!isLoading) {
                    login();
                  }
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      isLoading ? null : login,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}