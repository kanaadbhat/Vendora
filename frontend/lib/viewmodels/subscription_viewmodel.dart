import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

final subscriptionProvider = StateNotifierProvider<
  SubscriptionViewModel,
  AsyncValue<List<Subscription>>
>((ref) => SubscriptionViewModel(ref));

final isProductSubscribedProvider = Provider.family<AsyncValue<bool>, String>((
  ref,
  productId,
) {
  final subscriptionState = ref.watch(subscriptionProvider);
  final subscriptions = subscriptionState.value ?? [];
  final isSubscribed = subscriptions.any((sub) => sub.productId == productId);
  return AsyncValue.data(isSubscribed);
});

class SubscriptionViewModel
    extends StateNotifier<AsyncValue<List<Subscription>>> {
  SubscriptionViewModel(this.ref) : super(const AsyncValue.data([]));

  final Ref ref;
  final ApiService _apiService = ApiService();

  Future<void> fetchSubscriptions() async {
    state = const AsyncValue.loading();
    try {
      debugPrint('Fetching subscriptions...');
      final response = await _apiService.get('/userProduct/all');

      if (response.statusCode == 200) {
        final List<dynamic> subscriptionsJson = response.data['data'] ?? [];
        final subscriptions =
            subscriptionsJson.map((json) {
              try {
                return Subscription.fromJson(json);
              } catch (e) {
                debugPrint('Error parsing subscription: $e');
                debugPrint('Problematic JSON: $json');
                rethrow;
              }
            }).toList();
        state = AsyncValue.data(subscriptions);
      } else if (response.statusCode == 404) {
        state = const AsyncValue.data([]);
      } else {
        final errorMessage =
            response.data['message']?.toString() ??
            'Failed to fetch subscriptions';
        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching subscriptions: $e');
      debugPrint('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

 Future<String> subscribeToProduct(String productId, String password) async {
  try {
    debugPrint('Subscribing to product: $productId');
    final response = await _apiService.post(
      '/userProduct/subscribe/$productId',
      data: {'password': password},
    );

    if (response.statusCode == 201) {
      final subscriptionData = response.data['data'];
      final subscriptionId = subscriptionData['_id'];

      debugPrint('Successfully subscribed to product: $productId');
      await fetchSubscriptions(); // Refresh the list

      return subscriptionId;
    } else {
      final error =
          response.data['message']?.toString() ?? 'Failed to subscribe';
      debugPrint('Error subscribing to product: $error');
      throw Exception(error);
    }
  } catch (e, stackTrace) {
    debugPrint('Exception in subscribeToProduct: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

  Future<void> unsubscribeFromProduct(
    String subscriptionId,
    String password,
  ) async {
    try {
      debugPrint('Unsubscribing from product: $subscriptionId');
      final response = await _apiService.delete(
        '/userProduct/unsubscribe/$subscriptionId',
        data: {'password': password},
      );

      if (response.statusCode == 200) {
        debugPrint('Successfully unsubscribed from product: $subscriptionId');
        await fetchSubscriptions(); // Refresh the list
      } else {
        final error =
            response.data['message']?.toString() ?? 'Failed to unsubscribe';
        debugPrint('Error unsubscribing from product: $error');
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in unsubscribeFromProduct: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
