import 'dart:convert';

class Subscription {
  final String id;
  final String subscribedBy;
  final String productId;

  Subscription({
    required this.id,
    required this.subscribedBy,
    required this.productId,
  });

  // Convert JSON to Subscription object
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'] ?? '',
      subscribedBy: json['subscribedBy'] ?? '',
      productId: json['productId'] ?? '',
    );
  }

  // Convert Subscription object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'subscribedBy': subscribedBy,
      'productId': productId,
    };
  }

  // Convert JSON string to Subscription object
  static Subscription fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return Subscription.fromJson(jsonData);
  }

  // Convert Subscription object to JSON string
  String toJsonString() {
    return json.encode(toJson());
  }
}
