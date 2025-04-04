import 'dart:convert';

class Subscription {
  final String id;
  final String subscribedBy;
  final String productId;
  final String name;
  final String description;
  final double price;
  final String image;
  final String vendorId;
  final String vendorName;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.subscribedBy,
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.vendorId,
    required this.vendorName,
    required this.createdAt,
  });

  // Convert JSON to Subscription object
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'] ?? '',
      subscribedBy: json['subscribedBy'] ?? '',
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price:
          json['price'] is String
              ? double.parse(json['price'])
              : (json['price'] ?? 0.0).toDouble(),
      image: json['image'] ?? '',
      vendorId: json['vendorId'] ?? '',
      vendorName: json['vendorName'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Convert Subscription object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'subscribedBy': subscribedBy,
      'productId': productId,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'createdAt': createdAt.toIso8601String(),
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
