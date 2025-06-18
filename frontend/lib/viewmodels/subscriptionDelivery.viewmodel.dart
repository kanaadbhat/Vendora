import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscriptionDeliveries.model.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart' as ChatSubscription;

final subscriptionDeliveryProvider = StateNotifierProvider<
  SubscriptionDeliveryViewModel,
  AsyncValue<SubscriptionDelivery>
>((ref) => SubscriptionDeliveryViewModel(ref));

class SubscriptionDeliveryViewModel
    extends StateNotifier<AsyncValue<SubscriptionDelivery>> {
  SubscriptionDeliveryViewModel(this.ref) : super(const AsyncValue.loading());

  final Ref ref;
  final ApiService _apiService = ApiService();

  Future<void> fetchDeliveryLogs(String subscriptionId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.get(
        '/subscriptionDelivery/logs/$subscriptionId',
      );

      if (response.statusCode == 200) {
        final logs =
            (response.data['data'] as List)
                .map((log) => DeliveryLog.fromJson(log))
                .toList();

        final deliveryData = SubscriptionDelivery(
          subscriptionId: subscriptionId,
          deliveryConfig: DeliveryConfig(days: [], quantity: 0),
          deliveryLogs: logs,
        );
        state = AsyncValue.data(deliveryData);
      } else {
        state = AsyncValue.error(
          'Failed to fetch delivery logs',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching delivery logs: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> saveOrUpdateDeliveryConfig(
    String subscriptionId,
    List<String> days,
    int quantity,
  ) async {
    try {
      debugPrint(
        'Saving/updating delivery config for Subscription ID: $subscriptionId',
      );
      debugPrint('Days: $days');
      debugPrint('Quantity: $quantity');

      final response = await _apiService.post(
        '/subscriptionDelivery/config/$subscriptionId',
        data: {'days': days, 'quantity': quantity},
      );

      if (response.statusCode == 200) {
        debugPrint('Delivery configuration saved/updated successfully');
        await fetchDeliveryLogs(subscriptionId); // Refresh logs after saving
      } else {
        final error =
            response.data['message']?.toString() ??
            'Failed to save configuration';
        debugPrint('Error response: $error');
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving/updating delivery config: $e');
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  Future<void> updateSingleDeliveryLog(
    String subscriptionId,
    String date, {
    bool cancel = false,
    int? quantity,
  }) async {
    try {
try {
  debugPrint("START: updateSingleDeliveryLog called");
} catch (e) {
  debugPrint("Failed before even logging: $e");
}
      debugPrint('Subscription ID: $subscriptionId');
      debugPrint('Date: $date');
      debugPrint('Cancel: $cancel');
      debugPrint('Quantity: $quantity');

      final response = await _apiService.post(
        '/subscriptionDelivery/logs/override/$subscriptionId',
        data: {
          'date': date,
          'cancel': cancel,
          if (quantity != null) "quantity": quantity,
        },
      );
    debugPrint("Error response: ${response.data}");
      if (response.statusCode == 200) {
        debugPrint('Delivery log updated successfully');
        await fetchDeliveryLogs(subscriptionId); // Refresh logs after updating
      } else {
        final error =
            response.data['message']?.toString() ??
            'Failed to update delivery log';
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating delivery log: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

 Future<List<SubscriptionDelivery>> fetchDeliveries(
    List<ChatSubscription.Subscription> subscriptions,
  ) async {
    final List<SubscriptionDelivery> deliveries = [];

    for (final sub in subscriptions) {
      final resp = await _apiService.get('/subscriptionDelivery/full/${sub.id}');

      if (resp.statusCode == 200 && resp.data['data'] != null) {
        final data = resp.data['data'];

        final deliveryConfig = DeliveryConfig(
          days: List<String>.from(data['deliveryConfig']['days'] ?? []),
          quantity: data['deliveryConfig']['quantity'] ?? 0,
        );

        final deliveryLogs =
            (data['deliveryLogs'] as List)
                .map((log) => DeliveryLog.fromJson(log))
                .toList();

        deliveries.add(
          SubscriptionDelivery(
            subscriptionId: sub.id,
            deliveryConfig: deliveryConfig,
            deliveryLogs: deliveryLogs,
          ),
        );
      }
    }

    return deliveries;
  }

  //might not need
  Future<void> regenerateDeliveryLogs(String subscriptionId) async {
    try {
      final response = await _apiService.post(
        '/subscriptionDelivery/regenerate/$subscriptionId',
      );

      if (response.statusCode == 200) {
        debugPrint('Delivery logs regenerated successfully');
        await fetchDeliveryLogs(
          subscriptionId,
        ); // Refresh logs after regenerating
      } else {
        final error =
            response.data['message']?.toString() ??
            'Failed to regenerate delivery logs';
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      debugPrint('Error regenerating delivery logs: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
