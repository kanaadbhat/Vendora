import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import 'explore_vendors_screen.dart';
import 'subscription_screen.dart';
import 'chat_screen.dart';
import '../../models/subscription_model.dart' as ChatSubscription;
import '../../viewmodels/subscriptionDelivery.viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final user = ref.watch(authProvider).value;
    
    return subscriptionsAsync.when(
      data: (subscriptions) {
        // Calculate total due amount
        final totalDue = subscriptions.fold<double>(
          0,
          (sum, subscription) => sum + subscription.price,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? "Customer"}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your subscriptions and explore vendors',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            context,
                            'Total Subscriptions',
                            subscriptions.length.toString(),
                            Icons.subscriptions,
                          ),
                          _buildStatCard(
                            context,
                            'Total Due',
                            '\$${totalDue.toStringAsFixed(2)}',
                            Icons.payment,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Activity
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subscriptions.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const SubscriptionScreen(),
                                  ),
                                );
                              },
                              child: const Text('View All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (subscriptions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No subscriptions yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Explore vendors to find products to subscribe to',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              subscriptions.length > 3
                                  ? 3
                                  : subscriptions.length,
                          itemBuilder: (context, index) {
                            final subscription = subscriptions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    subscription.image,
                                  ),
                                ),
                                title: Text(subscription.name),
                                subtitle: Text(
                                  'Vendor: ${subscription.vendorName}\nPrice: \$${subscription.price.toStringAsFixed(2)}',
                                ),
                                trailing: Text(
                                  subscription.createdAt.toString().split(
                                    ' ',
                                  )[0],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildActionCard(
                            context,
                            'Explore Vendors',
                            Icons.store,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const ExploreVendorsScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Manage Subscriptions',
                            Icons.subscriptions,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const SubscriptionScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            'Chat with AI',
                            Icons.chat,
                            () async {
                              final user = ref.read(authProvider).value;
                              final subscriptions =
                                  ref.read(subscriptionProvider).value;
                              if (user != null &&
                                  subscriptions != null &&
                                  subscriptions.isNotEmpty) {
                                final chatSubscriptions =
                                    subscriptions
                                        .map(
                                          (sub) =>
                                              ChatSubscription.Subscription(
                                                id: sub.id,
                                                subscribedBy: user.id,
                                                productId: sub.productId,
                                                name: sub.name,
                                                description:
                                                    sub.description,
                                                price: sub.price,
                                                image: sub.image,
                                                vendorId: sub.vendorId,
                                                vendorName:
                                                    sub.vendorName,
                                                createdAt: sub.createdAt,
                                              ),
                                        )
                                        .toList();

                                final deliveries = await ref
                                    .read(subscriptionDeliveryProvider.notifier)
                                    .fetchDeliveries(chatSubscriptions);

                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatScreen(
                                            userId: user.id,
                                            subscriptions:
                                                chatSubscriptions,
                                            subscriptionDeliveries:
                                                deliveries,
                                          ),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please subscribe to a vendor to start chatting',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        return Center(child: Text('Error: $error'));
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor =
        isDarkMode
            ? Theme.of(context).colorScheme.surface
            : primaryColor.withOpacity(0.1);
    final textColor =
        isDarkMode ? Theme.of(context).colorScheme.onSurface : primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: primaryColor),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, color: textColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor =
        isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    final textColor = primaryColor;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}