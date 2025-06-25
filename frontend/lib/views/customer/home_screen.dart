import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'explore_vendors_screen.dart';
import 'subscription_screen.dart';
import 'chat_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../viewmodels/subscriptionswithdeliveries_viewmodel.dart';
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
          appBar: AppBar(title: const Text('Customer Dashboard')),
          drawer: const AppDrawer(role: 'customer'),
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
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (_, __) =>
              Scaffold(body: Center(child: Text('Error loading user data'))),
    );
  }

  Widget _buildChatScreen(String userId) {
    final chatScreenData = ref.watch(chatScreenDataProvider(userId));

    return chatScreenData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (data) {
        final chatSubscriptions = data.$1;
        final deliveries = data.$2;

        if (chatSubscriptions.isEmpty) {
          return const Center(
            child: Text('Please subscribe to a vendor to start chatting'),
          );
        }

        return ChatScreen(
          userId: userId,
          subscriptions: chatSubscriptions,
          subscriptionDeliveries: deliveries,
        );
      },
    );
  }
}
