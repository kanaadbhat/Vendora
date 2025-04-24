import 'package:flutter/foundation.dart';
import 'delivery_log.model.dart';

@immutable
class Subscription {
  final String id;
  final String productName;
  final String vendorName;
  final List<DeliveryLog> deliveryLogs;

  const Subscription({
    required this.id,
    required this.productName,
    required this.vendorName,
    required this.deliveryLogs,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      productName: json['productName'] as String,
      vendorName: json['vendorName'] as String,
      deliveryLogs:
          (json['deliveryLogs'] as List)
              .map((e) => DeliveryLog.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'vendorName': vendorName,
      'deliveryLogs': deliveryLogs.map((e) => e.toJson()).toList(),
    };
  }
}
