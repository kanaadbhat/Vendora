import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

import 'views/auth/auth_screen.dart';
import 'views/customer/home_screen.dart';
import 'views/vendor/home_screen.dart';
import 'viewmodels/role_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/server_availability_viewmodel.dart';
import 'widgets/error_widget.dart';
import 'widgets/loading_widget.dart';
import 'widgets/server_loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    if (!kReleaseMode) {
      await dotenv.load(fileName: '.env.local');
    }
  } else {
    if (kReleaseMode) {
      await dotenv.load(fileName: '.env');
    } else {
      await dotenv.load(fileName: '.env.local');
    }
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(roleProvider);
    final themeMode = ref.watch(themeProvider);
    final serverState = ref.watch(serverAvailabilityProvider);

    // Define your theme data once and reuse:
    final lightThemeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    final darkThemeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vendora',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: themeMode,
      home: Builder(
        builder: (context) {
          // Check server availability first before showing any UI
          if (!serverState.isAvailable && !serverState.hasError) {
            // Start checking server availability if not already checking
            if (!serverState.isChecking) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(serverAvailabilityProvider.notifier).checkServerAvailability();
              });
            }
            
            return const ServerLoadingScreen(
              message: "Connecting to server, please wait...",
            );
          }
          
          // If server check failed, show error with retry option
          if (serverState.hasError && !serverState.isAvailable) {
            return CustomErrorWidget(
              message: "Unable to connect to server. Please check your internet connection and try again.",
              onRetry: () => ref.read(serverAvailabilityProvider.notifier).checkServerAvailability(),
            );
          }

          final brightness = MediaQuery.of(context).platformBrightness;

          return roleState.when(
            data: (role) {
              debugPrint("[UI] roleState.when -> role = $role");
              debugPrint(
                "[UI] roleState.when -> role type: ${role.runtimeType}",
              );
              debugPrint(
                "[UI] roleState.when -> role == 'vendor': ${role == 'vendor'}",
              );
              debugPrint(
                "[UI] roleState.when -> role == 'customer': ${role == 'customer'}",
              );

              if (role == "customer") {
                debugPrint(
                  "[UI] roleState.when -> Returning CustomerHomeScreen",
                );
                return const CustomerHomeScreen();
              } else if (role == "vendor") {
                debugPrint("[UI] roleState.when -> Returning VendorHomeScreen");
                return const VendorHomeScreen();
              } else {
                debugPrint(
                  "[UI] roleState.when -> Returning AuthScreen (role is null or unknown)",
                );
                // Use the same theme for AuthScreen based on system brightness:
                return Theme(
                  data:
                      brightness == Brightness.dark
                          ? darkThemeData
                          : lightThemeData,
                  child: const AuthScreen(),
                );
              }
            },
            loading: () => const LoadingWidget(message: 'Loading...'),
            error:
                (error, _) => CustomErrorWidget(
                  message: error.toString(),
                  onRetry:
                      () => ref.read(roleProvider.notifier).fetchUserRole(),
                ),
          );
        },
      ),
    );
  }
}
