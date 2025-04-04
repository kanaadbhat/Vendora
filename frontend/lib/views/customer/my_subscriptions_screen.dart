import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/subscription_viewmodel.dart';

class MySubscriptionsScreen extends ConsumerStatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  ConsumerState<MySubscriptionsScreen> createState() =>
      _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends ConsumerState<MySubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(subscriptionProvider.notifier).fetchSubscriptions(),
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
            'My Subscriptions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: subscriptionState.when(
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return const Center(child: Text('No subscriptions yet'));
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
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Navigate to subscription details
                        },
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
