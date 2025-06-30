import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../services/pick_and_upload.dart';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSubmitting = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  final pickAndUpload = PickAndUpload();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      debugPrint('Submitting product form...');
      final price = _priceController.text;

      await ref
          .read(productProvider.notifier)
          .addProduct(
            _nameController.text,
            _descriptionController.text,
            price,
            _uploadedImageUrl,
          );

      if (mounted) {
        debugPrint('Product added successfully, navigating back');
        // First show the success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Then navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormField<File>(
                validator: (value) {
                  if (_selectedImage == null) {
                    return 'Please select a product photo';
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
                              color: state.hasError ? Colors.red : Colors.grey,
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          _uploadedImageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                    : DottedBorder(
                                      borderType: BorderType.RRect,
                                      radius: const Radius.circular(12),
                                      color: Colors.grey,
                                      strokeWidth: 2,
                                      dashPattern: const [6, 4],
                                      child: Container(
                                        width: 150,
                                        height: 150,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Add Product Photo',
                                          style: TextStyle(
                                            color: Theme.of(context).hintColor,
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
                            : 'Please select a Product photo',
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

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
