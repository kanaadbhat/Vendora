import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String description;
  final String price;
  final String image;
  final String createdBy;
  //final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.createdBy,
    //  required this.createdAt,
  });

  // Convert JSON to Product object
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        price: json['price']?.toString() ?? '0',
        image: json['image'] ?? 'https://via.placeholder.com/150',
        createdBy: json['createdBy'] ?? '',
      );
    } catch (e) {
      print('Error parsing product JSON: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  // Convert Product object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'createdBy': createdBy,
      //'createdAt': createdAt.toIso8601String(),
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
