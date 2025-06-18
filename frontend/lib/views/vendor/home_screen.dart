import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'product_list_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import '../../viewmodels/theme_viewmodel.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import '../../viewmodels/product_viewmodel.dart';

class VendorHomeScreen extends ConsumerStatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  ConsumerState<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends ConsumerState<VendorHomeScreen> {
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
        ref.read(productProvider.notifier).fetchProducts();
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
          const ProductListScreen(),
          VendorChatScreen(userId: user.id),
        ];
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Vendor Dashboard'),
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
                  debugPrint("[DEBUG] VendorHomeScreen - Logout button pressed");
                  await ref.read(authProvider.notifier).logout();
                  debugPrint("[DEBUG] VendorHomeScreen - Logout completed, checking if mounted");
                  
                  // Add a small delay to ensure state updates are processed
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  if (mounted) {
                    debugPrint("[DEBUG] VendorHomeScreen - Widget is mounted, navigating to LoginScreen");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  } else {
                    debugPrint("[DEBUG] VendorHomeScreen - Widget is not mounted, navigation skipped");
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
}

