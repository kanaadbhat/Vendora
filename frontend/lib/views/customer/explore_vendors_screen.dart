import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import 'vendor_products_screen.dart';

class ExploreVendorsScreen extends ConsumerStatefulWidget {
  const ExploreVendorsScreen({super.key});

  @override
  ConsumerState<ExploreVendorsScreen> createState() =>
      _ExploreVendorsScreenState();
}

class _ExploreVendorsScreenState extends ConsumerState<ExploreVendorsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch vendors when screen loads
    Future.microtask(() => ref.read(userProvider.notifier).fetchVendors());
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Vendors')),
      body: vendorsAsync.when(
        data: (users) {
          // Filter users to only show vendors
          final vendors = users.where((user) => user.role == 'vendor').toList();

          if (vendors.isEmpty) {
            return const Center(child: Text('No vendors found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(vendor.name[0].toUpperCase()),
                  ),
                  title: Text(vendor.name),
                  subtitle: Text(vendor.email),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => VendorProductsScreen(
                              vendorId: vendor.id,
                              vendorName: vendor.name,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
