import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscriptionDeliveries.model.dart';
import '../models/subscription_model.dart' as ChatSubscription;
import '../viewmodels/subscription_viewmodel.dart';
import 'subscriptionDelivery.viewmodel.dart';


final chatScreenDataProvider = AsyncNotifierProvider.family<
  ChatScreenDataNotifier,
  (List<ChatSubscription.Subscription>, List<SubscriptionDelivery>),
  String
>(ChatScreenDataNotifier.new);

class ChatScreenDataNotifier
    extends
        FamilyAsyncNotifier<
          (List<ChatSubscription.Subscription>, List<SubscriptionDelivery>),
          String
        > {
  @override
  Future<(List<ChatSubscription.Subscription>, List<SubscriptionDelivery>)>
  build(String userId) async {
    final subscriptions = ref.read(subscriptionProvider).value;

    if (subscriptions == null || subscriptions.isEmpty) {
      return (<ChatSubscription.Subscription>[], <SubscriptionDelivery>[]);
    }

    final chatSubscriptions =
        subscriptions
            .map(
              (sub) => ChatSubscription.Subscription(
                id: sub.id,
                subscribedBy: userId,
                productId: sub.productId,
                name: sub.name,
                description: sub.description,
                price: sub.price,
                image: sub.image,
                vendorId: sub.vendorId,
                vendorName: sub.vendorName,
                createdAt: sub.createdAt,
              ),
            )
            .toList();

    final deliveries = await ref
        .read(subscriptionDeliveryProvider.notifier)
        .fetchDeliveries(chatSubscriptions);

    return (chatSubscriptions, deliveries);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }
}
