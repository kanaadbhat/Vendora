import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../models/product_model.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../viewmodels/subscriptionDelivery.viewmodel.dart';

class VendorProductsScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorProductsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  ConsumerState<VendorProductsScreen> createState() =>
      _VendorProductsScreenState();
}

class _VendorProductsScreenState extends ConsumerState<VendorProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ref
          .read(userProvider.notifier)
          .fetchVendorProducts(widget.vendorId);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  Future<void> _subscribeToProduct(Product product) async {
    final passwordController = TextEditingController();
    final quantityController = TextEditingController();
    List<String> selectedDays = [];

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Subscribe to Product',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Product: ${product.name}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Delivery Days:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday',
                      ].map(
                        (day) => CheckboxListTile(
                          title: Text(day),
                          value: selectedDays.contains(day),
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          hintText: 'Enter quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    int quantity = int.tryParse(quantityController.text) ?? 0;

                    if (quantity < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quantity must be at least 1.'),
                        ),
                      );
                      return;
                    }

                    try {
                      final subscriptionId = await ref
                          .read(subscriptionProvider.notifier)
                          .subscribeToProduct(
                            product.id,
                            passwordController.text,
                          );

                      await ref
                          .read(subscriptionDeliveryProvider.notifier)
                          .saveOrUpdateDeliveryConfig(
                            subscriptionId,
                            selectedDays,
                            quantity,
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully subscribed!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error subscribing: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Subscribe'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(
    Product product,
    AsyncValue<bool> subscriptionStatus,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dart dark color
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            AspectRatio(
              aspectRatio: 1.2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[100]),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Color.fromARGB(210, 232, 232, 235),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Product description
                    Expanded(
                      child: Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[300],
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price and subscribe button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${double.parse(product.price).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        _buildSubscribeButton(subscriptionStatus, product),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(
    AsyncValue<bool> subscriptionStatus,
    Product product,
  ) {
    return subscriptionStatus.when(
      data:
          (isSubscribed) => SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed:
                  isSubscribed ? null : () => _subscribeToProduct(product),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubscribed ? Colors.grey[400] : Colors.blue,
                foregroundColor: isSubscribed ? Colors.grey[600] : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: isSubscribed ? 0 : 2,
              ),
              child: Text(
                isSubscribed ? 'Subscribed' : 'Subscribe',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ),
      loading:
          () => const SizedBox(
            height: 28,
            width: 28,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error:
          (err, _) => const SizedBox(
            height: 28,
            width: 28,
            child: Center(
              child: Icon(Icons.error, size: 16, color: Colors.red),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxis =
        width > 1200
            ? 5
            : width > 900
            ? 4
            : width > 600
            ? 3
            : width > 400
            ? 2
            : 1;

    return Scaffold(
      appBar: AppBar(title: Text("${widget.vendorName}'s Products")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? const Center(child: Text('No products available'))
              : Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75, // Portrait mode - taller than wide
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final subscriptionStatus = ref.watch(
                      isProductSubscribedProvider(product.id),
                    );
                    return _buildProductCard(product, subscriptionStatus);
                  },
                ),
              ),
    );
  }
}
