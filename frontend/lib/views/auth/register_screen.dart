import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/pick_and_upload.dart';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  String _selectedRole = 'customer';
  File? _selectedImage;
  String? _uploadedImageUrl;
  final pickAndUpload = PickAndUpload();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'password': _passwordController.text,
      'role': _selectedRole,
      if (_uploadedImageUrl != null) 'profileimage': _uploadedImageUrl,
    };

    if (_selectedRole == 'vendor') {
      data.addAll({
        'businessName': _businessNameController.text,
        'businessDescription': _businessDescriptionController.text,
      });
    }

    await ref.read(authProvider.notifier).register(data);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/2.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains('@')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: "Role",
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'customer',
                              child: Text('Customer'),
                            ),
                            DropdownMenuItem(
                              value: 'vendor',
                              child: Text('Vendor'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                        if (_selectedRole == 'vendor') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessNameController,
                            decoration: InputDecoration(
                              labelText: "Business Name",
                              prefixIcon: Icon(
                                Icons.business_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your business name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _businessDescriptionController,
                            decoration: InputDecoration(
                              labelText: "Business Description",
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your business description';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),

                        FormField<File>(
                          validator: (value) {
                            if (_selectedImage == null) {
                              return 'Please select a profile photo';
                            }
                            return null;
                          },
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final imageUrl = await pickAndUpload
                                        .pickAndUploadImage(context);

                                    if (imageUrl != null) {
                                      setState(() {
                                        _uploadedImageUrl = imageUrl;
                                        _selectedImage = File('dummy');
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            state.hasError
                                                ? Colors.red
                                                : Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child:
                                          _uploadedImageUrl != null
                                              ? Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.green,
                                                    width: 3,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    _uploadedImageUrl!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                              : DottedBorder(
                                                borderType: BorderType.RRect,
                                                radius: const Radius.circular(
                                                  12,
                                                ),
                                                color: Colors.grey,
                                                strokeWidth: 2,
                                                dashPattern: const [6, 4],
                                                child: Container(
                                                  width: 150,
                                                  height: 150,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Add Profile Photo',
                                                    style: TextStyle(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).hintColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Label below the field
                                Text(
                                  _uploadedImageUrl != null
                                      ? 'File uploaded successfully'
                                      : 'Please select a profile photo',
                                  style: TextStyle(
                                    color:
                                        state.hasError
                                            ? Colors.red
                                            : _uploadedImageUrl != null
                                            ? Colors.green
                                            : Theme.of(context).hintColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                        if (authState.isLoading)
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (authState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              authState.error.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
