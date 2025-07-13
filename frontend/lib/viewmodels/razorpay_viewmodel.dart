import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/razorpay_service.dart';

final razorpayProvider = Provider<RazorpayService>((ref) {
  final service = RazorpayService();
  ref.onDispose(() => service.clear());
  return service;
});

final paymentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.read(razorpayProvider);
  return await service.fetchAllPayments();
});
