import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  String _role = 'customer';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _businessNameController.clear();
    _businessDescriptionController.clear();
    _form.currentState?.reset();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final data = {
      "email": _emailController.text,
      "password": _passwordController.text,
      "role": _role,
      "name": _nameController.text,
      "phone": _phoneController.text,
    };

    if (_role == "vendor") {
      data.addAll({
        "businessName": _businessNameController.text,
        "businessDescription": _businessDescriptionController.text,
      });
    }

    await ref.read(authProvider.notifier).register(data);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Radio(
                                  value: 'customer',
                                  groupValue: _role,
                                  onChanged: (value) {
                                    setState(() {
                                      _role = value as String;
                                      _clearFields();
                                    });
                                  },
                                ),
                                const Text('Customer'),
                              ],
                            ),
                            Row(
                              children: [
                                Radio(
                                  value: 'vendor',
                                  groupValue: _role,
                                  onChanged: (value) {
                                    setState(() {
                                      _role = value as String;
                                      _clearFields();
                                    });
                                  },
                                ),
                                const Text('Vendor'),
                              ],
                            ),
                          ],
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Password",
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length < 4) {
                              return 'Enter at least 4 characters.';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().length < 10) {
                              return 'Enter a valid phone number.';
                            }
                            return null;
                          },
                        ),
                        if (_role == 'vendor') ...[
                          TextFormField(
                            controller: _businessNameController,
                            decoration: const InputDecoration(
                              labelText: 'Business Name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your business name.';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _businessDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Business Description',
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your business description.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (authState.isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Register'),
                          ),
                        if (authState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              authState.error.toString(),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
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
