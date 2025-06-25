import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../models/subscription_model.dart' as ChatSubscription;
import '../../viewmodels/subscriptionDelivery.viewmodel.dart';
import '../../models/subscriptionDeliveries.model.dart';


final chatScreenDataProvider = FutureProvider.family<(
  List<ChatSubscription.Subscription>,
  List<SubscriptionDelivery>
), String>((ref, userId) async {
  final subscriptions = ref.watch(subscriptionProvider).value;

  if (subscriptions == null || subscriptions.isEmpty) {
    return (<ChatSubscription.Subscription>[], <SubscriptionDelivery>[]);
  }

  final chatSubscriptions = subscriptions.map(
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
  ).toList();

  final deliveries = await ref
      .read(subscriptionDeliveryProvider.notifier)
      .fetchDeliveries(chatSubscriptions);

  return (chatSubscriptions, deliveries);
});


