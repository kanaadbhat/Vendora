import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.model.dart';
import '../models/subscription.model.dart';
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
        return _handleIntroductionQuestion();
      }

      // First try normal conversation
      if (!_isSubscriptionRelated(message)) {
        final response = await _chat.sendMessage(Content.text(message));
        return _createSimpleResponse(
          response.text ?? 'I cannot respond right now',
        );
      }

      // Check if user is asking for delivery logs
      if (_isDeliveryLogQuery(message)) {
        return _handleDeliveryLogQuery(userId, message, subscriptions);
      }

      // For potentially subscription-related messages
      final prompt = _buildSubscriptionPrompt(userId, message, subscriptions);
      final response = await _chat.sendMessage(Content.text(prompt));
      final text = response.text?.trim() ?? '';

      if (text.isEmpty)
        return _createSimpleResponse('I cannot respond right now');

      // Try to parse as subscription response
      try {
        final jsonMap = _extractJson(text);
        if (jsonMap.isNotEmpty && _isValidSubscriptionResponse(jsonMap)) {
          // Store the potential action and ask for confirmation
          _pendingAction = jsonMap;
          return _createConfirmationMessage(jsonMap);
        }
      } catch (e) {
        debugPrint('Subscription parsing failed: $e');
      }

      // Fallback to normal response
      return _createSimpleResponse(text);
    } catch (e) {
      debugPrint('GeminiService error: $e');
      return _createSimpleResponse("Sorry, I can't help with that right now");
    }
  }

  bool _isDeliveryLogQuery(String message) {
    final keywords = [
      'show my deliveries',
      'view my deliveries',
      'delivery history',
      'delivery logs',
      'past deliveries',
      'when are my deliveries'
    ];
    return keywords.any((word) => message.toLowerCase().contains(word));
  }

  Future<ChatMessage> _handleDeliveryLogQuery(
    String userId,
    String message,
    List<Subscription> subscriptions,
  ) async {
    try {
      // Find which subscription they're asking about
      final subscription = _findRelevantSubscription(message, subscriptions);
      if (subscription == null) {
        return _createSimpleResponse('Which subscription are you asking about?');
      }

      // Get delivery logs
      final response = await _api.get('/logs/${subscription.id}');
      if (response.statusCode == 200) {
        final logs = response.data as List;
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: _formatDeliveryLogs(logs, subscription),
          type: MessageType.ai,
          timestamp: DateTime.now(),
          metadata: {
            'userId': userId,
            'subscriptionId': subscription.id,
            'isLogResponse': true
          },
        );
      } else {
        return _createSimpleResponse('Could not retrieve delivery logs');
      }
    } catch (e) {
      debugPrint('Delivery log query error: $e');
      return _createSimpleResponse('Error retrieving delivery logs');
    }
  }

  String _formatDeliveryLogs(List<dynamic> logs, Subscription subscription) {
    if (logs.isEmpty) {
      return 'No delivery logs found for ${subscription.productName}';
    }

    final buffer = StringBuffer();
    buffer.writeln('Here are your delivery logs for ${subscription.productName}:');
    
    for (final log in logs) {
      final date = log['date'] ?? 'Unknown date';
      final status = log['canceled'] == true ? '❌ Canceled' : '✅ Delivered';
      buffer.writeln('• $date - $status');
    }
    
    return buffer.toString();
  }

  Subscription? _findRelevantSubscription(
    String message,
    List<Subscription> subscriptions,
  ) {
    if (subscriptions.length == 1) return subscriptions.first;
    
    for (final sub in subscriptions) {
      if (message.toLowerCase().contains(sub.productName.toLowerCase())) {
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

  ChatMessage _handleIntroductionQuestion() {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content:
          '''I am an AI assistant integrated into the Vendora Delivery Management app. I can help you with:

1. Managing your subscriptions
2. Updating delivery schedules
3. Modifying delivery quantities
4. Canceling or rescheduling deliveries
5. Checking delivery status
6. Answering questions about your subscriptions

Just let me know what you need help with!''',
      type: MessageType.ai,
      timestamp: DateTime.now(),
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
          _executeApiCall(apiCall); // Note: Fire and forget
        }
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: action['confirmation']?.toString() ?? '✅ Action completed!',
          type: MessageType.ai,
          timestamp: DateTime.now(),
          metadata: {
            ...action,
            'userId': userId,
            'confirmed': true,
            if (apiCall != null) 'apiCall': apiCall,
          },
        );
      } else {
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: "Okay, I won't make any changes.",
          type: MessageType.ai,
          timestamp: DateTime.now(),
          metadata: {'userId': userId, 'confirmed': false},
        );
      }
    } catch (e) {
      debugPrint('Confirmation handling error: $e');
      _pendingAction = null;
      return _createSimpleResponse(
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

  ChatMessage _createConfirmationMessage(Map<String, dynamic> action) {
    final confirmationQuestion = '''
I think you want to ${action['intent'] == 'config' ? 'update delivery configuration' : 'override a delivery'}:
${action['confirmation']}

Is this correct? Please respond with "yes" or "no".
''';

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: confirmationQuestion,
      type: MessageType.ai,
      timestamp: DateTime.now(),
      metadata: {...action, 'isConfirmationPrompt': true},
    );
  }

  bool _isSubscriptionRelated(String message) {
    final keywords = [
      'delivery',
      'subscription',
      'order',
      'change',
      'cancel',
      'reschedule',
      'update',
      'modify',
    ];
    return keywords.any((word) => message.toLowerCase().contains(word));
  }

  ChatMessage _createSimpleResponse(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: MessageType.ai,
      timestamp: DateTime.now(),
    );
  }

  String _buildSubscriptionPrompt(
    String userId,
    String message,
    List<Subscription> subs,
  ) {
    final subList = subs
        .map((s) {
          return '''
Subscription: ${s.productName} from ${s.vendorName}
ID: ${s.id}
''';
        })
        .join('\n\n');

    return '''You are an AI assistant for the Vendora Delivery Management app. When you detect subscription-related requests, respond in JSON format:

Current subscriptions:
$subList

Possible actions:
1. Save/Update delivery configuration - use "intent": "config"
   - Endpoint: /config/:subscriptionId
   - Method: POST
   - Body: { "days": ["monday",...], "quantity": number }

2. Override single delivery log - use "intent": "override"
   - Endpoint: /logs/override/:subscriptionId
   - Method: POST
   - Body: { "date": "YYYY-MM-DD", "cancel": boolean, "quantity": number }

For subscription requests, respond EXACTLY in this format:
{
  "intent": "config"|"override",
  "entities": {
    "subscriptionId": "ID",
    "date": "YYYY-MM-DD",
    "days": ["monday",...],
    "quantity": number,
    "cancel": boolean
  },
  "confirmation": "clear message summarizing the action",
  "apiCall": {
    "endpoint": "string",
    "method": "POST",
    "body": { ... }
  }
}

For general questions about subscriptions or delivery configurations, respond in a natural, conversational way without JSON formatting.

User message: "$message"''';
  }

  bool _isValidSubscriptionResponse(Map<String, dynamic> json) {
    return json.containsKey('intent') &&
        ['config', 'override'].contains(json['intent']) &&
        json.containsKey('confirmation') &&
        json.containsKey('apiCall');
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
      final endpoint = apiCall['endpoint']?.toString() ?? '';
      final method = apiCall['method']?.toString() ?? '';
      final body = apiCall['body'];

      if (endpoint.isEmpty || method != 'POST') {
        throw Exception('Invalid API call');
      }

      await _api.post(endpoint, data: body);
    } catch (e) {
      debugPrint('API call failed: $e');
      rethrow;
    }
  }
}