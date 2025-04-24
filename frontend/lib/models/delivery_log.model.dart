import 'package:flutter/foundation.dart';

@immutable
class DeliveryLog {
  final DateTime date;
  final int quantity;
  final bool delivered;
  final bool cancelled;

  const DeliveryLog({
    required this.date,
    required this.quantity,
    this.delivered = false,
    this.cancelled = false,
  });

  factory DeliveryLog.fromJson(Map<String, dynamic> json) {
    return DeliveryLog(
      date: DateTime.parse(json['date'] as String),
      quantity: json['quantity'] as int,
      delivered: json['delivered'] as bool? ?? false,
      cancelled: json['cancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'quantity': quantity,
      'delivered': delivered,
      'cancelled': cancelled,
    };
  }

  DeliveryLog copyWith({
    DateTime? date,
    int? quantity,
    bool? delivered,
    bool? cancelled,
  }) {
    return DeliveryLog(
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      delivered: delivered ?? this.delivered,
      cancelled: cancelled ?? this.cancelled,
    );
  }
}
