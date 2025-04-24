import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/auth/auth_screen.dart';
import 'views/customer/home_screen.dart';
import 'views/vendor/home_screen.dart';
import 'viewmodels/role_viewmodel.dart';
import 'widgets/error_widget.dart';
import 'widgets/loading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(roleProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vendora',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: roleState.when(
        data: (role) {
          if (role == "customer") {
            return const CustomerHomeScreen();
          } else if (role == "vendor") {
            return const VendorHomeScreen();
          } else {
            return const AuthScreen();
          }
        },
        loading: () => const LoadingWidget(message: 'Loading...'),
        error:
            (error, _) => CustomErrorWidget(
              message: error.toString(),
              onRetry: () => ref.read(roleProvider.notifier).fetchUserRole(),
            ),
      ),
    );
  }
}
