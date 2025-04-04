import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/subscription_viewmodel.dart';

class ManageSubscriptionsScreen extends ConsumerStatefulWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  ConsumerState<ManageSubscriptionsScreen> createState() =>
      _ManageSubscriptionsScreenState();
}

class _ManageSubscriptionsScreenState
    extends ConsumerState<ManageSubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(subscriptionProvider.notifier).fetchSubscriptions(),
    );
  }

  Future<void> _showUnsubscribeDialog(String subscriptionId) async {
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unsubscribe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your account password to unsubscribe'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(subscriptionProvider.notifier)
                        .unsubscribeFromProduct(
                          subscriptionId,
                          passwordController.text,
                        );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully unsubscribed!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Unsubscribe'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Subscriptions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: subscriptionState.when(
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return const Center(
                    child: Text('No subscriptions to manage'),
                  );
                }
                return ListView.builder(
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = subscriptions[index];
                    return Card(
                      child: ListTile(
                        leading:
                            subscription.image.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    subscription.image,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const CircleAvatar(
                                  child: Icon(Icons.subscriptions),
                                ),
                        title: Text(subscription.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subscription.description),
                            Text(
                              'Vendor: ${subscription.vendorName}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '\$${subscription.price}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel),
                          color: Colors.red,
                          onPressed:
                              () => _showUnsubscribeDialog(subscription.id),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
