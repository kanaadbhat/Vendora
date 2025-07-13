import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/razorpay_viewmodel.dart';
import 'package:razorpay_web/razorpay_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? selectedVendorId;
  String? selectedVendorName;
  final TextEditingController _amountController = TextEditingController();
  bool _snackBarShown = false;

  void _showSingleSnackBar(BuildContext context, String message) {
    if (_snackBarShown) return;
    _snackBarShown = true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      ).closed.then((_) {
        _snackBarShown = false;
      });
  }

  void _popIfMounted() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Make a Payment')),
      body: subscriptionsAsync.when(
        data: (subscriptions) {
          // Get unique vendors from subscriptions
          final vendors = {
            for (var sub in subscriptions) sub.vendorId: sub.vendorName,
          };

          bool isPayEnabled =
              (selectedVendorId != null &&
                  (int.tryParse(_amountController.text) ?? 0) > 0);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Payment image at the top
                  Center(
                    child: Image.asset(
                      'assets/payment.png',
                      height: 350,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Vendor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedVendorId,
                    items:
                        vendors.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedVendorId = value;
                        selectedVendorName = vendors[value];
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose a vendor',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter Amount (₹)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Amount in INR',
                    ),
                    onChanged: (_) {
                      setState(() {}); // Update pay button state
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, _) {
                      final razorpayService = ref.read(razorpayProvider);
                      void handleSuccess(
                        PaymentSuccessResponse response,
                      ) async {
                        final verified = await razorpayService.verifyPayment(
                          orderId: response.orderId!,
                          paymentId: response.paymentId!,
                          signature: response.signature!,
                          from: user?.id ?? '',
                          to: selectedVendorId ?? '',
                          amount: int.tryParse(_amountController.text) ?? 0,
                          currency: 'INR',
                          receipt: 'order_rcptid_11',
                          description: 'Vendora Payment to $selectedVendorName',
                        );
                        if (mounted) {
                          _showSingleSnackBar(
                            context,
                            verified
                                ? "Payment Verified Successfully"
                                : "Payment Verification Failed",
                          );
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            _popIfMounted,
                          );
                        }
                      }

                      void handleError(PaymentFailureResponse response) {
                        if (mounted) {
                          _showSingleSnackBar(
                            context,
                            "Payment Failed: ${response.message}",
                          );
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            _popIfMounted,
                          );
                        }
                      }

                      void handleExternalWallet(
                        ExternalWalletResponse response,
                      ) {
                        if (mounted) {
                          _showSingleSnackBar(
                            context,
                            "External Wallet: ${response.walletName}",
                          );
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            _popIfMounted,
                          );
                        }
                      }

                      razorpayService.registerEventHandlers(
                        onSuccess: handleSuccess,
                        onError: handleError,
                        onExternalWallet: handleExternalWallet,
                      );
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isPayEnabled
                                  ? () {
                                    final amount =
                                        int.tryParse(_amountController.text) ??
                                        0;
                                    if (amount <= 0) {
                                      _showSingleSnackBar(
                                        context,
                                        'Enter a valid amount.',
                                      );
                                      return;
                                    }
                                    razorpayService.createOrderAndPay(
                                      amount: amount,
                                      currency: "INR",
                                      receipt: "order_rcptid_11",
                                      name: user?.name ?? "Customer",
                                      description:
                                          "Vendora Payment to $selectedVendorName",
                                      prefillContact: "9123456789",
                                      prefillEmail:
                                          user?.email ?? "test@example.com",
                                      razorpayKey:
                                          kIsWeb && kReleaseMode
                                              ? const String.fromEnvironment(
                                                'RAZORPAY_KEY_ID',
                                                defaultValue: '',
                                              )
                                              : dotenv.env['RAZORPAY_KEY_ID'] ??
                                                  '',
                                    );
                                  }
                                  : null,
                          child: const Text("Pay Now"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
