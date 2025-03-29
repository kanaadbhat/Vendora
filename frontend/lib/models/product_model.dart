import 'dart:convert';

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String image;
  final String createdBy;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.image,
    required this.createdBy,
  });

  // Convert JSON to Product object
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      createdBy: json['createdBy'] ?? '',
    );
  }

  // Convert Product object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'description': description,
      'image': image,
      'createdBy': createdBy,
    };
  }

  // Convert JSON string to Product object
  static Product fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return Product.fromJson(jsonData);
  }

  // Convert Product object to JSON string
  String toJsonString() {
    return json.encode(toJson());
  }
}
