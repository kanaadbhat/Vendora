import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'product_list_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'features.dart';
import '../../viewmodels/product_viewmodel.dart';

class VendorHomeScreen extends ConsumerStatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  ConsumerState<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends ConsumerState<VendorHomeScreen> {
  int _currentIndex = 0;
  bool _productsFetched = false;

  @override
  void initState() {
    super.initState();
    // Remove the premature auth check - let the build method handle everything
  }

  void _fetchProductsIfNeeded() {
    if (!_productsFetched) {
      debugPrint(
        "[DEBUG] VendorHomeScreen._fetchProductsIfNeeded() - Fetching products",
      );
      Future.microtask(() {
        ref.read(productProvider.notifier).fetchProducts();
      });
      _productsFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    debugPrint("[DEBUG] VendorHomeScreen.build() - Auth state: $authState");

    return authState.when(
      data: (user) {
        debugPrint(
          "[DEBUG] VendorHomeScreen.build() - User: ${user?.name} (${user?.role})",
        );
        if (user == null) {
          debugPrint(
            "[DEBUG] VendorHomeScreen.build() - User is null, showing loading",
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

        // Fetch products when user is available
        _fetchProductsIfNeeded();

        debugPrint(
          "[DEBUG] VendorHomeScreen.build() - Building vendor dashboard for user: ${user.name}",
        );
        final List<Widget> _screens = [
          const DashboardScreen(),
          const VendorFeaturesScreen(),
          const ProductListScreen(),
          VendorChatScreen(userId: user.id),
        ];

        return Scaffold(
          appBar: AppBar(title: const Text('Vendor Dashboard')),
          drawer: AppDrawer(role: user.role, image: user.profileimage),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
      loading: () {
        debugPrint("[DEBUG] VendorHomeScreen.build() - Auth state is loading");
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
        debugPrint("[DEBUG] VendorHomeScreen.build() - Auth state has error");
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
