class DeliveryLog {
  DateTime date;
  int quantity;
  bool delivered;
  bool cancelled;

  DeliveryLog({
    required this.date,
    required this.quantity,
    this.delivered = false,
    this.cancelled = false,
  });

  factory DeliveryLog.fromJson(Map<String, dynamic> json) {
    return DeliveryLog(
      date: DateTime.parse(json['date']),
      quantity: json['quantity'],
      delivered: json['delivered'] ?? false,
      cancelled: json['cancelled'] ?? false,
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
}

class DeliveryConfig {
  List<String> days;
  int quantity;

  DeliveryConfig({required this.days, required this.quantity});

  factory DeliveryConfig.fromJson(Map<String, dynamic> json) {
    return DeliveryConfig(
      days: List<String>.from(json['days']),
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'days': days, 'quantity': quantity};
  }
}

class SubscriptionDelivery {
  String subscriptionId;
  DeliveryConfig deliveryConfig;
  List<DeliveryLog> deliveryLogs;

  SubscriptionDelivery({
    required this.subscriptionId,
    required this.deliveryConfig,
    required this.deliveryLogs,
  });

  factory SubscriptionDelivery.fromJson(Map<String, dynamic> json) {
    return SubscriptionDelivery(
      subscriptionId: json['subscriptionId'],
      deliveryConfig: DeliveryConfig.fromJson(json['deliveryConfig']),
      deliveryLogs:
          (json['deliveryLogs'] as List)
              .map((log) => DeliveryLog.fromJson(log))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'deliveryConfig': deliveryConfig.toJson(),
      'deliveryLogs': deliveryLogs.map((log) => log.toJson()).toList(),
    };
  }
}
