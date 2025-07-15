import '../../models/subscriptionDeliveries.model.dart';
import '../../models/subscription_model.dart';
import 'message_utils.dart';
import 'package:flutter/foundation.dart';

class UserPromptBuilder {
  /// Constructs the full “context prompt” to send to Gemini whenever we need
  /// to handle a normal chat or attempt to parse an action.
  static String buildPrompt({
    required String userId,
    required String message,
    required List<Subscription> subscriptions,
    required List<SubscriptionDelivery> subscriptionDeliveries,
  }) {
    debugPrint(
      '[DEBUG] PromptBuilder.buildPrompt() - Building prompt for user: $userId',
    );
    debugPrint('[DEBUG] PromptBuilder.buildPrompt() - Message: $message');
    debugPrint(
      '[DEBUG] PromptBuilder.buildPrompt() - Subscriptions count: ${subscriptions.length}',
    );

    // Format subscriptions list with IDs
    final subList = subscriptions
        .map(
          (s) => '''
          - ${s.name} from ${s.vendorName} (ID: ${s.id})
            • Price: ₹${s.price.toStringAsFixed(2)}
            • Subscribed since: ${MessageUtils.formatDate(s.createdAt)}
          ''',
        )
        .join('\n');

    // Format delivery information with subscription IDs
    final deliveryInfo = subscriptionDeliveries
        .map((d) {
          final sub = subscriptions.firstWhere(
            (s) => s.id == d.subscriptionId,
            orElse:
                () => Subscription(
                  id: d.subscriptionId,
                  subscribedBy: '',
                  productId: '',
                  name: 'Unknown',
                  description: '',
                  price: 0.0,
                  image: '',
                  vendorId: '',
                  vendorName: '',
                  createdAt: DateTime.now(),
                ),
          );
          if (sub.name == 'Unknown') return '';

          final config = d.deliveryConfig;
          final logs = d.deliveryLogs
              .take(3)
              .map((log) {
                final date = log.date.toIso8601String().split('T').first;
                final status =
                    log.cancelled
                        ? '❌ Canceled'
                        : (log.delivered ? '✅ Delivered' : '⏳ Pending');
                return '    - $date: $status (Qty: ${log.quantity})';
              })
              .join('\n');

          return '''
Subscription: ${sub.name} (ID: ${sub.id})
  DeliveryConfig:
    Days: ${config.days.join(', ')}
    Quantity: ${config.quantity}
  DeliveryLogs:
$logs''';
        })
        .join('\n');

    debugPrint(
      '[DEBUG] PromptBuilder.buildPrompt() - Formatted subscription list and delivery info',
    );

    final promptText =
        '''You are a Multilingual AI assistant for Vendora Delivery Management app. You have FULL ACCESS to the user's subscription and delivery data and should respond accordingly.
    Using this chatbot users can see their subscription status and associated data, and change delivery details of their subscriptions.

Current Subscriptions:
$subList

Delivery Information:
$deliveryInfo

Response Rules:
1. First, determine the type of query:
   - Introduction questions about Vendora
   - Subscription-related queries
   - Delivery configuration queries
   - Delivery log/history queries
   - Potential actions that require API calls
   - General conversation

2. For potential actions, respond with this JSON schema ONLY (no additional text, no markdown formatting, no code blocks):
{
  "action": {
    "intent": "string describing the action",
    "apiCall": {
      "method": "POST",
      "endpoint": "string",
      "body": { "key": "value" }
    },
    "confirmation": "string asking for confirmation",
    "successMessage": "string to show on success"
  }
}

Available API Endpoints:
1. Save/Update Delivery Config
   - POST /subscriptionDelivery/config/:subscriptionId
   - Body: { "days": ["mon", "tue"], "quantity": number }

2. Override Delivery Log
   - POST /subscriptionDelivery/logs/override/:subscriptionId
   - Body: { "date": "YYYY-MM-DD", "cancel": boolean, "quantity": number }

3. For all other queries, respond naturally using the provided data.

4. Always respond in the same language as the user's message.

5. If you detect a potential action:
   - Return ONLY the JSON schema with appropriate values
   - Include the EXACT subscription ID in the endpoint
   - Do not add any text before or after the JSON

6. For introduction questions, provide information about Vendora's delivery management capabilities.

7. For subscription queries, use the actual subscription data provided.

8. For delivery queries, use the actual delivery configuration and logs provided.

User Message: "$message"''';

    debugPrint(
      '[DEBUG] PromptBuilder.buildPrompt() - Prompt built successfully',
    );
    return promptText;
  }
}
