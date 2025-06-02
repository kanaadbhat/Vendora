import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart'; // Add this import
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'explore_vendors_screen.dart';
import 'subscription_screen.dart';
import 'chat_screen.dart';
import '../auth/login_screen.dart';
import '../../models/subscription_model.dart' as ChatSubscription;
import '../../models/subscriptionDeliveries.model.dart';
import '../../services/api_service.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _selectedIndex = 0;
  late Future<List<SubscriptionDelivery>> _deliveriesFuture;

  @override
  void initState() {
    super.initState();
    // Initialize deliveries future
    _deliveriesFuture = Future.value([]);

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

  Future<List<SubscriptionDelivery>> _fetchDeliveries(
    List<ChatSubscription.Subscription> subscriptions,
  ) async {
    final api = ApiService();
    final List<SubscriptionDelivery> deliveries = [];

    for (final sub in subscriptions) {
      // First get the delivery config
      final configResp = await api.get(
        '/subscriptionDelivery/config/${sub.id}',
      );
      if (configResp.statusCode == 200 && configResp.data['data'] != null) {
        final configData = configResp.data['data'];
        final deliveryConfig = DeliveryConfig(
          days: List<String>.from(configData['days'] ?? []),
          quantity: configData['quantity'] ?? 0,
        );

        // Then get the delivery logs
        final logsResp = await api.get('/subscriptionDelivery/logs/${sub.id}');
        if (logsResp.statusCode == 200 && logsResp.data['data'] != null) {
          deliveries.add(
            SubscriptionDelivery(
              subscriptionId: sub.id,
              deliveryConfig: deliveryConfig,
              deliveryLogs:
                  (logsResp.data['data'] as List)
                      .map((log) => DeliveryLog.fromJson(log))
                      .toList(),
            ),
          );
        }
      }
    }
    return deliveries;
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
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
      case 3:
        final user = ref.read(authProvider).value;
        final subscriptions = ref.read(subscriptionProvider).value;
        if (user != null && subscriptions != null && subscriptions.isNotEmpty) {
          final chatSubscriptions =
              subscriptions
                  .map(
                    (sub) => ChatSubscription.Subscription(
                      id: sub.id,
                      subscribedBy: user.id,
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

          final deliveries = await _fetchDeliveries(chatSubscriptions);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ChatScreen(
                      userId: user.id,
                      subscriptions: chatSubscriptions,
                      subscriptionDeliveries: deliveries,
                    ),
              ),
            );
          }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              // Theme toggle button
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              ),
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
                    // Welcome section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
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
                            'Welcome, ${user.name}',
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
                                          builder: (context) => const SubscriptionScreen(),
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
                                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No subscriptions yet',
                                        style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                itemCount: subscriptions.length > 3 ? 3 : subscriptions.length,
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

                                      final deliveries = await _fetchDeliveries(
                                        chatSubscriptions,
                                      );

                                      if (mounted) {
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
              if (error.toString().contains('Unauthorized')) {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDarkMode 
        ? Theme.of(context).colorScheme.surface 
        : primaryColor.withOpacity(0.1);
    final textColor = isDarkMode 
        ? Theme.of(context).colorScheme.onSurface 
        : primaryColor;

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
    final backgroundColor = isDarkMode 
        ? Theme.of(context).colorScheme.surface 
        : Colors.white;
    final textColor = primaryColor;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
