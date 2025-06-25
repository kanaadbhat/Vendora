import '../../models/productwithsubscribers.model.dart';
import 'package:flutter/foundation.dart';

class VendorPromptBuilder {
  static String buildVendorPrompt({
    required String userId,
    required String message,
    required List<ProductWithSubscribers> productsWithSubscribers,
  }) {
    final productDetails =
        productsWithSubscribers.map((pws) {
          final product = pws.product;

          return {
            'productId': product.id,
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'image': product.image,
            'createdBy': product.createdBy,
          };
        }).toList();

    final subscriberDetailsPerProduct =
        productsWithSubscribers.map((pws) {
          return {
            'productId': pws.product.id,
            'subscribers':
                pws.subscribers.map((subscriber) {
                  final sub =
                      subscriber.subscriptionWithSubscriber.subscription;
                  final user =
                      subscriber.subscriptionWithSubscriber.subscribedBy;
                  final del = subscriber.deliveryDetails;

                  return {
                    'subscriptionId': sub.id,
                    'subscribedBy': {
                      'id': user.id,
                      'name': user.name,
                      'email': user.email,
                      'phone': user.phone,
                    },
                    'productId': sub.productId,
                    'subscriptionName': sub.name,
                    'subscriptionDescription': sub.description,
                    'subscriptionPrice': sub.price,
                    'vendorId': sub.vendorId,
                    'vendorName': sub.vendorName,
                    'subscribedAt': sub.createdAt.toIso8601String(),
                    'deliveryConfig': {
                      'days': del.deliveryConfig.days,
                      'quantity': del.deliveryConfig.quantity,
                    },
                    'deliveryLogs':
                        del.deliveryLogs.map((log) {
                          return {
                            'date': log.date.toIso8601String(),
                            'quantity': log.quantity,
                            'delivered': log.delivered,
                            'cancelled': log.cancelled,
                          };
                        }).toList(),
                  };
                }).toList(),
          };
        }).toList();

    final productListText = productDetails
        .map(
          (p) => '''
                    - ${p['name']} (ID: ${p['productId']})
                      • Description: ${p['description']}
                      • Price: ₹${p['price']}
                      • Created By: ${p['createdBy']}
                    ''',
        )
        .join('\n');

    final subscriberListText = subscriberDetailsPerProduct
        .map((entry) {
          final productId = entry['productId'];
          final subscribers = entry['subscribers'] as List;

          final formattedSubscribers = subscribers
              .map((s) {
                final logs = (s['deliveryLogs'] as List)
                    .map((log) {
                      return '      - ${log['date']} | Qty: ${log['quantity']} | '
                          'Delivered: ${log['delivered']} | Cancelled: ${log['cancelled']}';
                    })
                    .join('\n');

                return '''
  - Subscription ID: ${s['subscriptionId']}
    • Subscribed By: ${s['subscribedBy']}
    • Name: ${s['subscriptionName']}
    • Description: ${s['subscriptionDescription']}
    • Price: ₹${s['subscriptionPrice']}
    • Subscribed On: ${s['subscribedAt']}
    • Delivery Days: ${s['deliveryConfig']['days'].join(', ')}
    • Delivery Quantity: ${s['deliveryConfig']['quantity']}
    • Delivery Logs:
$logs
''';
              })
              .join('\n');

          return '''
Product ID: $productId
Subscribers:
$formattedSubscribers
''';
        })
        .join('\n---\n');

    final promptText = '''
  You are a Multilingual AI assistant for Vendora Delivery Management app. You have FULL ACCESS to all of Vendor data and should respond accordingly.
    Using this chatbot vendors can see the products they have added along with which users have subscribed to their products along with what delivery details.

    Current Products added by the vendor:
    $productListText

    Current Subscribers for each product along with associated information:
    $subscriberListText

    User Message:
    $message

    Response Rules:
    1. Always respond in the language of the user.
    2. Provide detailed information about products and subscribers.
    3. If the user asks about a specific product, provide details about that product and its subscribers.
    4. If the user asks about a specific subscriber, provide details about that subscriber and their subscriptions.
    4. if user asks what are his current products then output the product list
    5. If the user asks about delivery details, provide information about delivery configurations and logs.
    6. Always respons in a professional and helpful manner
    7. If the user asks for help provide guidance on how to use the chatbot
    8. If user asks questions like who are you then give output about yourselfes and what you can do.
''';
    debugPrint(
      '[DEBUG] PromptBuilder.buildPrompt() - Prompt built successfully',
    );
    return promptText;
  }
}
