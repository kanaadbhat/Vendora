import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.model.dart';
import '../models/subscription_model.dart';
import '../models/subscriptionDeliveries.model.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final GenerativeModel _model;
  late ChatSession _chat;
  final ApiService _api;
  Map<String, dynamic>? _pendingAction;

  GeminiService(this._api)
    : _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      ) {
    _chat = _model.startChat();
  }

  void resetChat() {
    _chat = _model.startChat();
    _pendingAction = null;
  }

  Future<ChatMessage> sendMessage({
    required String userId,
    required String message,
    required List<Subscription> subscriptions,
    required List<SubscriptionDelivery> subscriptionDeliveries,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('Gemini API key not configured');

      // Check for pending actions or specific queries
      if (_pendingAction != null) {
        return _handleConfirmationResponse(userId, message);
      }
      if (_isIntroductionQuestion(message)) {
        return _handleIntroductionQuestion(userId);
      }
      if (_isDeliveryConfigQuery(message)) {
        return await _handleDeliveryConfigQuery(
          userId,
          message,
          subscriptions,
          subscriptionDeliveries,
        );
      }
      if (_isDeliveryLogQuery(message)) {
        return await _handleDeliveryLogQuery(
          userId,
          message,
          subscriptions,
          subscriptionDeliveries,
        );
      }
      if (_isSubscriptionListQuery(message)) {
        return _handleSubscriptionList(userId, subscriptions);
      }

      // Handle normal conversation or potential actions
      return await _handleNormalOrActionableMessage(
        userId,
        message,
        subscriptions,
        subscriptionDeliveries,
      );
    } catch (e) {
      debugPrint('GeminiService error: $e');
      return _createAiMessage(
        userId,
        "Sorry, I can't help with that right now",
      );
    }
  }

  // Handle normal conversation or actionable messages
  Future<ChatMessage> _handleNormalOrActionableMessage(
    String userId,
    String message,
    List<Subscription> subscriptions,
    List<SubscriptionDelivery> subscriptionDeliveries,
  ) async {
    if (!_isPotentialAction(message)) {
      final prompt = _buildActionPrompt(
        userId,
        message,
        subscriptions,
        subscriptionDeliveries,
      );
      final response = await _chat.sendMessage(Content.text(prompt));
      return _createAiMessage(
        userId,
        response.text ?? 'I cannot respond right now',
      );
    }

    final prompt = _buildActionPrompt(
      userId,
      message,
      subscriptions,
      subscriptionDeliveries,
    );
    final response = await _chat.sendMessage(Content.text(prompt));
    final text = response.text?.trim() ?? '';

    if (text.isEmpty) {
      return _createAiMessage(userId, 'I cannot respond right now');
    }

    // Try to parse as potential action
    return _handlePotentialActionResponse(userId, text);
  }

  // Handle potential action responses
  ChatMessage _handlePotentialActionResponse(String userId, String text) {
    try {
      final jsonMap = _extractJson(text);
      if (jsonMap.isNotEmpty && _isValidActionResponse(jsonMap)) {
        _pendingAction = jsonMap;
        return _createConfirmationMessage(userId, jsonMap);
      }
    } catch (e) {
      debugPrint('Action parsing failed: $e');
    }
    return _createAiMessage(userId, text);
  }

  // Subscription and delivery log handling
  bool _isDeliveryLogQuery(String message) {
    final keywords = [
      'show my deliveries',
      'view my deliveries',
      'delivery history',
      'delivery logs',
      'past deliveries',
      'when are my deliveries',
    ];
    return keywords.any((word) => message.toLowerCase().contains(word));
  }

  bool _isSubscriptionListQuery(String message) {
    final keywords = [
      'what subscriptions do I have',
      'list my subscriptions',
      'my current subscriptions',
      'show my subscriptions',
      'what am I subscribed to',
      'what products have I subscribed to',
      'what subscriptions so i currently have',
      'what products have i subscribed currently',
    ];
    return keywords.any((word) => message.toLowerCase().contains(word));
  }

  ChatMessage _handleSubscriptionList(
    String userId,
    List<Subscription> subscriptions,
  ) {
    if (subscriptions.isEmpty) {
      return _createAiMessage(
        userId,
        'You currently have no active subscriptions.',
      );
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'You have ${subscriptions.length} active subscription${subscriptions.length > 1 ? 's' : ''}:',
    );

    for (final sub in subscriptions) {
      buffer.writeln('\n• ${sub.name} from ${sub.vendorName}');
      buffer.writeln('  - Price: \$${sub.price.toStringAsFixed(2)}');

      if (sub.description.isNotEmpty) {
        buffer.writeln('  - Description: ${sub.description}');
      }

      buffer.writeln('  - Since: ${_formatDate(sub.createdAt)}');
      buffer.writeln('  - Subscription ID: ${sub.id}');
    }

    return _createAiMessage(userId, buffer.toString());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<ChatMessage> _handleDeliveryLogQuery(
    String userId,
    String message,
    List<Subscription> subscriptions,
    List<SubscriptionDelivery> subscriptionDeliveries,
  ) async {
    try {
      final subscription = _findRelevantSubscription(message, subscriptions);
      if (subscription == null) {
        return _createAiMessage(
          userId,
          'Which subscription are you asking about?',
        );
      }
      final delivery = subscriptionDeliveries.firstWhere(
        (d) => d.subscriptionId == subscription.id,
        orElse:
            () => SubscriptionDelivery(
              subscriptionId: subscription.id,
              deliveryConfig: DeliveryConfig(days: [], quantity: 0),
              deliveryLogs: [],
            ),
      );
      if (delivery.deliveryLogs.isEmpty) {
        return _createAiMessage(
          userId,
          'No delivery logs found for ${subscription.name}',
        );
      }
      final buffer = StringBuffer();
      buffer.writeln('Delivery history for ${subscription.name}:');
      for (final log in delivery.deliveryLogs.take(5)) {
        final date = log.date.toIso8601String().split('T').first;
        final status =
            log.cancelled
                ? '❌ Canceled'
                : (log.delivered ? '✅ Delivered' : '⏳ Pending');
        buffer.writeln('• $date - $status (Qty: ${log.quantity})');
      }
      if (delivery.deliveryLogs.length > 5) {
        buffer.writeln(
          '\nShowing 5 most recent of ${delivery.deliveryLogs.length} total deliveries',
        );
      }
      return _createAiMessage(
        userId,
        buffer.toString(),
        metadata: {'subscriptionId': subscription.id, 'isLogResponse': true},
      );
    } catch (e) {
      debugPrint('Delivery log query error: $e');
      return _createAiMessage(userId, 'Error retrieving delivery logs');
    }
  }

  Subscription? _findRelevantSubscription(
    String message,
    List<Subscription> subscriptions,
  ) {
    if (subscriptions.length == 1) return subscriptions.first;

    for (final sub in subscriptions) {
      if (message.toLowerCase().contains(sub.name.toLowerCase())) {
        return sub;
      }
    }

    return null;
  }

  // Introduction handling
  bool _isIntroductionQuestion(String message) {
    final introQuestions = [
      'who are you',
      'what are you',
      'what can you do',
      'how can you help',
      'what is your purpose',
    ];
    return introQuestions.any((q) => message.toLowerCase().contains(q));
  }

  ChatMessage _handleIntroductionQuestion(String userId) {
    return _createAiMessage(
      userId,
      '''I am your Vendora Delivery Assistant. I can help you with:

• Viewing your subscriptions
• Checking delivery schedules
• Updating delivery preferences
• Canceling or rescheduling deliveries
• Answering questions about your orders

What would you like help with today?''',
    );
  }

  // Confirmation handling
  ChatMessage _handleConfirmationResponse(String userId, String userResponse) {
    try {
      final isConfirmed = _isPositiveConfirmation(userResponse);
      final action = _pendingAction!;
      _pendingAction = null;

      if (isConfirmed) {
        final apiCall = action['apiCall'];
        if (apiCall is Map<String, dynamic>) {
          debugPrint('Making API call:');
          debugPrint('Method: ${apiCall['method']}');
          debugPrint('Endpoint: ${apiCall['endpoint']}');
          debugPrint('Body: ${apiCall['body']}');

          // Make the API call immediately
          _executeApiCall(apiCall)
              .then((_) {
                return _createAiMessage(
                  userId,
                  '✅ ${action['successMessage'] ?? 'Action completed successfully!'}',
                  metadata: {...action, 'confirmed': true, 'apiCall': apiCall},
                );
              })
              .catchError((e) {
                debugPrint('API call failed: $e');
                return _createAiMessage(
                  userId,
                  '❌ Failed to complete the action. Please try again.',
                  metadata: {'error': e.toString()},
                );
              });
        }
        return _createAiMessage(
          userId,
          'Processing your request...',
          metadata: {'isProcessing': true},
        );
      } else {
        return _createAiMessage(
          userId,
          "Okay, I won't make any changes.",
          metadata: {'confirmed': false},
        );
      }
    } catch (e) {
      debugPrint('Confirmation handling error: $e');
      _pendingAction = null;
      return _createAiMessage(
        userId,
        "Sorry, I couldn't process that confirmation",
      );
    }
  }

  bool _isPositiveConfirmation(String response) {
    final positiveKeywords = [
      'yes',
      'yeah',
      'yup',
      'confirm',
      'ok',
      'okay',
      'sure',
      'do it',
    ];
    return positiveKeywords.any(
      (word) => response.toLowerCase().contains(word),
    );
  }

  ChatMessage _createConfirmationMessage(
    String userId,
    Map<String, dynamic> action,
  ) {
    return _createAiMessage(
      userId,
      action['confirmation'] ?? 'Should I proceed with this change?',
      metadata: {...action, 'isConfirmationPrompt': true},
    );
  }

  bool _isPotentialAction(String message) {
    final keywords = [
      'change',
      'update',
      'modify',
      'cancel',
      'reschedule',
      'switch',
      'set',
      'edit',
    ];
    return keywords.any((word) => message.toLowerCase().contains(word));
  }

  ChatMessage _createAiMessage(
    String userId,
    String content, {
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.ai,
      timestamp: DateTime.now(),
      metadata: {'userId': userId, ...?metadata},
    );
  }

  bool _isDeliveryConfigQuery(String message) {
    final keywords = [
      'what is my delivery configuration',
      'show my delivery config',
      'current delivery config',
      'delivery schedule',
      'when are my deliveries scheduled',
      'what days are my deliveries',
      'how many deliveries do I get',
    ];
    return keywords.any((word) => message.toLowerCase().contains(word));
  }

  Future<ChatMessage> _handleDeliveryConfigQuery(
    String userId,
    String message,
    List<Subscription> subscriptions,
    List<SubscriptionDelivery> subscriptionDeliveries,
  ) async {
    try {
      final subscription = _findRelevantSubscription(message, subscriptions);
      if (subscription == null) {
        return _createAiMessage(
          userId,
          'Which subscription are you asking about?',
        );
      }

      final delivery = subscriptionDeliveries.firstWhere(
        (d) => d.subscriptionId == subscription.id,
        orElse:
            () => SubscriptionDelivery(
              subscriptionId: subscription.id,
              deliveryConfig: DeliveryConfig(days: [], quantity: 0),
              deliveryLogs: [],
            ),
      );

      if (delivery.deliveryConfig.days.isEmpty) {
        return _createAiMessage(
          userId,
          'No delivery configuration found for ${subscription.name}. Would you like to set one up?',
        );
      }

      final days = delivery.deliveryConfig.days.join(', ');
      final quantity = delivery.deliveryConfig.quantity;
      return _createAiMessage(
        userId,
        'Current default delivery config for ${subscription.name} is on $days with a quantity of $quantity.',
      );
    } catch (e) {
      debugPrint('Delivery config query error: $e');
      return _createAiMessage(
        userId,
        'Error retrieving delivery configuration',
      );
    }
  }

  String _buildActionPrompt(
    String userId,
    String message,
    List<Subscription> subs,
    List<SubscriptionDelivery> deliveries,
  ) {
    final subList = subs
        .map(
          (s) => '''
- ${s.name} from ${s.vendorName}
  • Price: \$${s.price.toStringAsFixed(2)}
  • Subscribed since: ${_formatDate(s.createdAt)}
''',
        )
        .join('\n');

    final deliveryInfo = deliveries
        .map((d) {
          final sub = subs.firstWhere(
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
${sub.name}:
  • Delivery Config: ${config.days.join(', ')} (Qty: ${config.quantity})
  • Recent Deliveries:
$logs''';
        })
        .join('\n');

    return '''You are an AI assistant for Vendora Delivery Management app. You have FULL ACCESS to the user's subscription and delivery data and should respond accordingly.

Current Subscriptions:
$subList

Delivery Information:
$deliveryInfo

Response Rules:
1. When asked about subscriptions or deliveries, ALWAYS use the actual data shown above
2. Never say you can't access subscription or delivery information
3. Be helpful and specific about the user's actual subscriptions and deliveries
4. For modification requests, ask for confirmation

Example Responses:
:User  "What products have I subscribed to?"
Response: "You currently have these subscriptions:\n[list their actual subscriptions]"

:User  "When did I subscribe to X?"
Response: "You subscribed to X on [date]"

:User  "Show my delivery logs for X"
Response: "Here are your recent deliveries for X:\n[list delivery logs]"

:User  "What is my delivery configuration for X?"
Response: "Current default delivery config for X is on [days] with a quantity of [quantity]."

User  Message: "$message"''';
  }

  bool _isValidActionResponse(Map<String, dynamic> json) {
    return json.containsKey('user_message') &&
        json.containsKey('action') &&
        json['action'] is Map &&
        (json['action'] as Map).containsKey('intent') &&
        (json['action'] as Map).containsKey('apiCall');
  }

  Map<String, dynamic> _extractJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end < 0 || start >= end) return {};
      return json.decode(text.substring(start, end + 1))
          as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON extraction error: $e');
      return {};
    }
  }

  Future<void> _executeApiCall(Map<String, dynamic> apiCall) async {
    try {
      final endpoint = apiCall['endpoint'] as String;
      final method = apiCall['method'] as String;
      final body = apiCall['body'];

      debugPrint('Executing API call:');
      debugPrint('Method: $method');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Body: $body');

      dynamic response;
      switch (method) {
        case 'POST':
          response = await _api.post(endpoint, data: body);
          break;
        case 'PUT':
          response = await _api.put(endpoint, data: body);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('API call failed with status ${response.statusCode}');
      }

      debugPrint('API call successful: ${response.statusCode}');
      debugPrint('Response: ${response.data}');
    } catch (e) {
      debugPrint('Error executing API call: $e');
      throw e;
    }
  }
}
