import '../models/product_model.dart';
import '../models/subscription_model.dart';
import '../models/subscriptionDeliveries.model.dart';

class ProductWithSubscribers {
  final Product product;
  final List<Subscriber> subscribers;

  ProductWithSubscribers({
    required this.product,
    required this.subscribers,
  });

  factory ProductWithSubscribers.fromJson(Map<String, dynamic> json) {
    return ProductWithSubscribers(
      product: Product.fromJson(json['product']),
      subscribers: (json['subscribers'] as List<dynamic>?)
              ?.map((e) => Subscriber.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Subscriber {
  final Subscription subscription;
  final SubscriptionDelivery deliveryDetails;

  Subscriber({
    required this.subscription,
    required this.deliveryDetails,
  });

  factory Subscriber.fromJson(Map<String, dynamic> json) {
    return Subscriber(
      subscription: Subscription.fromJson(json['subscription']),
      deliveryDetails: SubscriptionDelivery.fromJson(json['deliveryDetails']),
    );
  }
}
