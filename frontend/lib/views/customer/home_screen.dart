import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'explore_vendors_screen.dart';
import 'subscription_screen.dart';
import 'chat_screen.dart';
import '../auth/login_screen.dart';
import '../../models/subscription_model.dart' as ChatSubscription;
//import '../../models/subscription_model.dart' as HomeSubscription;

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check authentication state
    Future.microtask(() {
      final authState = ref.watch(authProvider);
      authState.whenData((user) {
        if (user == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          return;
        }
        // Fetch subscriptions if authenticated
        ref.read(subscriptionProvider.notifier).fetchSubscriptions();
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExploreVendorsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        );
        break;
      // In the navigation case 3 (chat screen):
      case 3:
        final user = ref.read(authProvider).value;
        final subscriptions = ref.read(subscriptionProvider).value;
        if (user != null && subscriptions != null && subscriptions.isNotEmpty) {
          // Convert to ChatSubscription with ALL required parameters
          final chatSubscriptions =
              subscriptions
                  .map(
                    (sub) => ChatSubscription.Subscription(
                      id: sub.id,
                      subscribedBy: user.id, // Using current user's ID
                      productId: sub.productId,
                      name: sub.name,
                      description: sub.description,
                      price: sub.price,
                      image: sub.image,
                      vendorId: sub.vendorId,
                      vendorName: sub.vendorName,
                      createdAt: sub.createdAt,
                    ),
                  )
                  .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    userId: user.id,
                    subscriptions: chatSubscriptions,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please subscribe to a vendor to start chatting'),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: subscriptionsAsync.when(
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
                                  'Total Subscriptions',
                                  subscriptions.length.toString(),
                                  Icons.subscriptions,
                                ),
                                _buildStatCard(
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
                            const Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (subscriptions.isEmpty)
                              const Center(child: Text('No recent activity'))
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: subscriptions.length,
                                itemBuilder: (context, index) {
                                  final subscription = subscriptions[index];
                                  return ListTile(
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
                                  () {
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

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ChatScreen(
                                                userId: user.id,
                                                subscriptions:
                                                    chatSubscriptions,
                                              ),
                                        ),
                                      );
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
              if (error.toString().contains('Unauthorized')) {
                // Redirect to login screen if unauthorized
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                });
              }
              return Center(child: Text('Error: $error'));
            },
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            role: 'customer',
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.blue)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
