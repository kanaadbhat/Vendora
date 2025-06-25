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
  final SubscriptionWithSubscriber subscriptionWithSubscriber;
  final SubscriptionDelivery deliveryDetails;

  Subscriber({
    required this.subscriptionWithSubscriber,
    required this.deliveryDetails,
  });

  factory Subscriber.fromJson(Map<String, dynamic> json) {
    return Subscriber(
      subscriptionWithSubscriber:
          SubscriptionWithSubscriber.fromJson(json['subscription']),
      deliveryDetails:
          SubscriptionDelivery.fromJson(json['deliveryDetails']),
    );
  }
}

class SubscriptionWithSubscriber {
  final Subscription subscription;
  final SubscribedBy subscribedBy;

  SubscriptionWithSubscriber({
    required this.subscription,
    required this.subscribedBy,
  });

 factory SubscriptionWithSubscriber.fromJson(Map<String, dynamic> json) {
  final subJson = {
    ...json,
    'subscribedBy': json['subscribedBy']?['_id'] ?? '', // for Subscription compatibility
  };

  return SubscriptionWithSubscriber(
    subscription: Subscription.fromJson(subJson),
    subscribedBy: SubscribedBy.fromJson(json['subscribedBy'] ?? {}),
  );
}

}

class SubscribedBy {
  final String id;
  final String name;
  final String email;
  final String phone;

  SubscribedBy({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory SubscribedBy.fromJson(Map<String, dynamic> json) {
    return SubscribedBy(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };
}
