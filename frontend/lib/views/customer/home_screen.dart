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
    // Remove the premature auth check - let the build method handle everything
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    debugPrint("[DEBUG] CustomerHomeScreen.build() - Auth state: $authState");

    return authState.when(
      data: (user) {
        debugPrint(
          "[DEBUG] CustomerHomeScreen.build() - User: " +
              (user?.name ?? 'null') +
              " (" +
              (user?.role ?? 'null') +
              ")",
        );
        if (user == null) {
          debugPrint(
            "[DEBUG] CustomerHomeScreen.build() - User is null, showing loading",
          );
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user data...'),
                ],
              ),
            ),
          );
        }

        final List<Widget> _screens = [
          const DashboardScreen(),
          const ExploreVendorsScreen(),
          const SubscriptionScreen(),
          ChatScreen(userId: user.id),
        ];

        debugPrint('Profile image: ${user.profileimage}');
        return Scaffold(
          appBar: AppBar(title: const Text('Customer Dashboard')),
          drawer: AppDrawer(role: user.role, image: user.profileimage),
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
      loading: () {
        debugPrint(
          "[DEBUG] CustomerHomeScreen.build() - Auth state is loading",
        );
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading authentication...'),
              ],
            ),
          ),
        );
      },
      error: (_, __) {
        debugPrint("[DEBUG] CustomerHomeScreen.build() - Auth state has error");
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading user data'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      () => ref.read(authProvider.notifier).initializeUser(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
