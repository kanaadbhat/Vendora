import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_screen.dart';
import '../viewmodels/theme_viewmodel.dart';

class AppDrawer extends ConsumerWidget {
  final String? role;
  final String? image;
  final void Function(int)? setTab;
  final void Function(String featureKey)? onFeature;

  const AppDrawer({
    super.key,
    this.role,
    this.image,
    this.setTab,
    this.onFeature,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isCustomer = role == 'customer';
    debugPrint('Profile image URL: $image');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: image != null ? NetworkImage(image!) : null,
                  child:
                      image == null
                          ? Icon(Icons.person, size: 35, color: Colors.grey)
                          : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vendora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isCustomer ? 'Customer Dashboard' : 'Vendor Dashboard',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          // Navigation items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              setTab?.call(0);
              Navigator.pop(context);
            },
          ),
          if (isCustomer) ...[
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Explore Vendors'),
              onTap: () {
                setTab?.call(1);
                onFeature?.call('explore');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions),
              title: const Text('My Subscriptions'),
              onTap: () {
                setTab?.call(1);
                onFeature?.call('subscriptions');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payments'),
              onTap: () {
                setTab?.call(1);
                onFeature?.call('payments');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                setTab?.call(2);
                Navigator.pop(context);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('My Products'),
              onTap: () {
                setTab?.call(1);
                onFeature?.call('products');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                setTab?.call(2);
                Navigator.pop(context);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
            onTap: () {
              ref.read(themeProvider.notifier).toggleTheme();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              debugPrint("[DEBUG] AppDrawer - Logout button pressed");
              await ref.read(authProvider.notifier).logout();
              debugPrint("[DEBUG] AppDrawer - Logout completed");

              // Add a small delay to ensure state updates are processed
              await Future.delayed(const Duration(milliseconds: 300));

              if (context.mounted) {
                debugPrint(
                  "[DEBUG] AppDrawer - Context is mounted, navigating to LoginScreen",
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                debugPrint(
                  "[DEBUG] AppDrawer - Context is not mounted, navigation skipped",
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
