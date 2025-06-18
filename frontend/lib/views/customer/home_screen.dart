import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'explore_vendors_screen.dart';
import 'subscription_screen.dart';
import 'chat_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../models/subscription_model.dart' as ChatSubscription;
import '../../viewmodels/subscriptionDelivery.viewmodel.dart';
import 'dashboard_screen.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    
    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final List<Widget> _screens = [
          const DashboardScreen(),
          const ExploreVendorsScreen(),
          const SubscriptionScreen(),
          _buildChatScreen(user.id),
        ];
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer Dashboard'),
            actions: [
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
                  debugPrint("[DEBUG] CustomerHomeScreen - Logout button pressed");
                  await ref.read(authProvider.notifier).logout();
                  debugPrint("[DEBUG] CustomerHomeScreen - Logout completed, checking if mounted");
                  
                  // Add a small delay to ensure state updates are processed
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  if (mounted) {
                    debugPrint("[DEBUG] CustomerHomeScreen - Widget is mounted, navigating to LoginScreen");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  } else {
                    debugPrint("[DEBUG] CustomerHomeScreen - Widget is not mounted, navigation skipped");
                  }
                },
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            role: 'customer',
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Text('Error loading user data'),
        ),
      ),
    );
  }
  
  Widget _buildChatScreen(String userId) {
    final subscriptions = ref.watch(subscriptionProvider).value;
    
    if (subscriptions == null || subscriptions.isEmpty) {
      return const Center(
        child: Text('Please subscribe to a vendor to start chatting'),
      );
    }
    
    // This is a placeholder widget that will be replaced with the actual ChatScreen
    // when the user taps on the Chat tab
    return FutureBuilder(
      future: _prepareChatScreen(userId, subscriptions),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data!;
        } else {
          return const Center(child: Text('Unable to load chat'));
        }
      },
    );
  }
  
  Future<Widget> _prepareChatScreen(String userId, List<dynamic> subscriptions) async {
    final chatSubscriptions = subscriptions.map((sub) => 
      ChatSubscription.Subscription(
        id: sub.id,
        subscribedBy: userId,
        productId: sub.productId,
        name: sub.name,
        description: sub.description,
        price: sub.price,
        image: sub.image,
        vendorId: sub.vendorId,
        vendorName: sub.vendorName,
        createdAt: sub.createdAt,
      )
    ).toList();
    
    final deliveries = await ref
        .read(subscriptionDeliveryProvider.notifier)
        .fetchDeliveries(chatSubscriptions);
    
    return ChatScreen(
      userId: userId,
      subscriptions: chatSubscriptions,
      subscriptionDeliveries: deliveries,
    );
  }
}
