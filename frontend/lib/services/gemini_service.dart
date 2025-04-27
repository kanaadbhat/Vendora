import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.model.dart';
import '../models/subscription_model.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final GenerativeModel _model;
  late ChatSession _chat;
  final ApiService _api;
  Map<String, dynamic>? _pendingAction;

  GeminiService(this._api)
    : _model = GenerativeModel(
        model: 'gemini-1.5-pro',
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
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('Gemini API key not configured');

      // Check if this is a confirmation response to a pending action
      if (_pendingAction != null) {
        return _handleConfirmationResponse(userId, message);
      }

      // Handle introduction questions
      if (_isIntroductionQuestion(message)) {
        return _handleIntroductionQuestion(userId);
      }

      // Handle delivery log queries
      if (_isDeliveryLogQuery(message)) {
        return _handleDeliveryLogQuery(userId, message, subscriptions);
      }

      // Handle subscription listing
      if (_isSubscriptionListQuery(message)) {
        return _handleSubscriptionList(userId, subscriptions);
      }

      // First try normal conversation for non-actionable queries
      if (!_isPotentialAction(message)) {
        final prompt = _buildActionPrompt(userId, message, subscriptions);
        final response = await _chat.sendMessage(Content.text(prompt));
        return _createAiMessage(
          userId,
          response.text ?? 'I cannot respond right now',
        );
      }

      // For potentially actionable messages
      final prompt = _buildActionPrompt(userId, message, subscriptions);
      final response = await _chat.sendMessage(Content.text(prompt));
      final text = response.text?.trim() ?? '';

      if (text.isEmpty) {
        return _createAiMessage(userId, 'I cannot respond right now');
      }

      // Try to parse as potential action
      try {
        final jsonMap = _extractJson(text);
        if (jsonMap.isNotEmpty && _isValidActionResponse(jsonMap)) {
          // Store the potential action and ask for confirmation
          _pendingAction = jsonMap;
          return _createConfirmationMessage(userId, jsonMap);
        }
      } catch (e) {
        debugPrint('Action parsing failed: $e');
      }

      // Fallback to normal response
      return _createAiMessage(userId, text);
    } catch (e) {
      debugPrint('GeminiService error: $e');
      return _createAiMessage(
        userId,
        "Sorry, I can't help with that right now",
      );
    }
  }

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
  ) async {
    try {
      final subscription = _findRelevantSubscription(message, subscriptions);
      if (subscription == null) {
        return _createAiMessage(
          userId,
          'Which subscription are you asking about?',
        );
      }

      final response = await _api.get('/logs/${subscription.id}');
      if (response.statusCode == 200) {
        final logs = response.data as List;
        return _createAiMessage(
          userId,
          _formatDeliveryLogs(logs, subscription),
          metadata: {'subscriptionId': subscription.id, 'isLogResponse': true},
        );
      } else {
        return _createAiMessage(userId, 'Could not retrieve delivery logs');
      }
    } catch (e) {
      debugPrint('Delivery log query error: $e');
      return _createAiMessage(userId, 'Error retrieving delivery logs');
    }
  }

  String _formatDeliveryLogs(List<dynamic> logs, Subscription subscription) {
    if (logs.isEmpty) {
      return 'No delivery logs found for ${subscription.name}';
    }

    final buffer = StringBuffer();
    buffer.writeln('Delivery history for ${subscription.name}:');

    for (final log in logs.take(5)) {
      final date = log['date'] ?? 'Unknown date';
      final status = log['canceled'] == true ? '❌ Canceled' : '✅ Delivered';
      buffer.writeln('• $date - $status');
    }

    if (logs.length > 5) {
      buffer.writeln(
        '\nShowing 5 most recent of ${logs.length} total deliveries',
      );
    }

    return buffer.toString();
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

  ChatMessage _handleConfirmationResponse(String userId, String userResponse) {
    try {
      final isConfirmed = _isPositiveConfirmation(userResponse);
      final action = _pendingAction!;
      _pendingAction = null;

      if (isConfirmed) {
        // Execute the confirmed action
        final apiCall = action['apiCall'];
        if (apiCall is Map<String, dynamic>) {
          _executeApiCall(apiCall)
              .then((_) {
                return _createAiMessage(
                  userId,
                  '✅ ${action['successMessage'] ?? 'Action completed successfully!'}',
                  metadata: {...action, 'confirmed': true, 'apiCall': apiCall},
                );
              })
              .catchError((e) {
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

  String _buildActionPrompt(
    String userId,
    String message,
    List<Subscription> subs,
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

    return '''You are an AI assistant for Vendora Delivery Management app. You have FULL ACCESS to the user's subscription data and should respond accordingly.

Current Subscriptions:
$subList

Response Rules:
1. When asked about subscriptions, ALWAYS list the actual subscriptions shown above
2. Never say you can't access subscription information
3. Be helpful and specific about the user's actual subscriptions
4. For modification requests, ask for confirmation

Example Responses:
User: "What products have I subscribed to?"
Response: "You currently have these subscriptions:\n[list their actual subscriptions]"

User: "When did I subscribe to X?"
Response: "You subscribed to X on [date]"

User Message: "$message"''';
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

      if (response.statusCode != 200) {
        throw Exception('API call failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error executing API call: $e');
      throw e;
    }
  }
}
