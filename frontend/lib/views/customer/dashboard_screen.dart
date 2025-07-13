import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import 'subscription_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:razorpay_web/razorpay_web.dart';
import '../../viewmodels/razorpay_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final user = ref.watch(authProvider).value;

    return subscriptionsAsync.when(
      data: (subscriptions) {
        // Calculate total due amount
        final totalDue = subscriptions.fold<double>(
          0,
          (sum, subscription) => sum + subscription.price,
        );

        return Scaffold(
          body: SingleChildScrollView(
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
                        'Welcome, ${user?.name ?? "Customer"}',
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
                              context,
                              'Total Subscriptions',
                              subscriptions.length.toString(),
                              Icons.subscriptions,
                            ),
                            _buildStatCard(
                              context,
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
                                      builder:
                                          (context) =>
                                              const SubscriptionScreen(),
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
                                  Icon(
                                    Icons.info_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No subscriptions yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
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
                            itemCount:
                                subscriptions.length > 3
                                    ? 3
                                    : subscriptions.length,
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
                          'Payment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final razorpayService = ref.read(razorpayProvider);
                            void handleSuccess(
                              PaymentSuccessResponse response,
                            ) async {
                              final verified = await razorpayService
                                  .verifyPayment(
                                    orderId: response.orderId!,
                                    paymentId: response.paymentId!,
                                    signature: response.signature!,
                                  );
                              // Use the current context safely
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      verified
                                          ? "Payment Verified Successfully"
                                          : "Payment Verification Failed",
                                    ),
                                  ),
                                );
                              }
                            }

                            void handleError(PaymentFailureResponse response) {
                              // Use the current context safely
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Failed: ${response.message}",
                                    ),
                                  ),
                                );
                              }
                            }

                            void handleExternalWallet(
                              ExternalWalletResponse response,
                            ) {
                              // Use the current context safely
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "External Wallet: ${response.walletName}",
                                    ),
                                  ),
                                );
                              }
                            }

                            razorpayService.registerEventHandlers(
                              onSuccess: handleSuccess,
                              onError: handleError,
                              onExternalWallet: handleExternalWallet,
                            );
                            return ElevatedButton(
                              onPressed: () {
                                razorpayService.createOrderAndPay(
                                  amount: 5,
                                  currency: "INR",
                                  receipt: "order_rcptid_11",
                                  name: user?.name ?? "Customer",
                                  description: "Vendora Subscription Payment",
                                  prefillContact: "9123456789",
                                  prefillEmail:
                                      user?.email ?? "test@example.com",
                                  razorpayKey:
                                      kIsWeb && kReleaseMode
                                          ? const String.fromEnvironment(
                                            'RAZORPAY_KEY_ID',
                                            defaultValue: '',
                                          )
                                          : dotenv.env['RAZORPAY_KEY_ID'] ?? '',
                                );
                              },
                              child: const Text("Pay ₹500"),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        return Center(child: Text('Error: $error'));
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor =
        isDarkMode
            ? Theme.of(context).colorScheme.surface
            : primaryColor.withOpacity(0.1);
    final textColor =
        isDarkMode ? Theme.of(context).colorScheme.onSurface : primaryColor;

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
}
