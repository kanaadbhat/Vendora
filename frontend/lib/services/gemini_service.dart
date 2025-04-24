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

  GeminiService(this._api)
    : _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      ) {
    _chat = _model.startChat();
  }

  /// Resets the conversation context.
  void resetChat() {
    _chat = _model.startChat();
  }

  /// Sends [message] along with user info and subscription list.
  /// Expects Gemini to return a JSON with exactly one of the two actions:
  ///  • config update → POST /config/:subscriptionId
  ///  • log update    → PUT  /log/:subscriptionId
  Future<ChatMessage> sendMessage({
    required String userId,
    required String message,
    required List<Subscription> subscriptions,
  }) async {
    try {
      if (dotenv.env['GEMINI_API_KEY'] == null ||
          dotenv.env['GEMINI_API_KEY']!.isEmpty) {
        throw Exception(
          'Gemini API key not found. Please check your .env file.',
        );
      }

      final prompt = _buildPrompt(userId, message, subscriptions);
      final ai = await _chat.sendMessage(Content.text(prompt));
      final text = ai.text?.trim() ?? '';
      final jsonMap = _extractJson(text);

      // If there is an apiCall, execute it
      if (jsonMap.containsKey('apiCall')) {
        await _executeApiCall(jsonMap['apiCall']);
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: jsonMap['confirmation'] ?? '✅ Done.',
        type: MessageType.ai,
        timestamp: DateTime.now(),
        metadata: jsonMap,
      );
    } catch (e) {
      debugPrint('GeminiService error: $e');
      return ChatMessage.error(
        'Sorry, something went wrong. Please try again.',
      );
    }
  }

  String _buildPrompt(String userId, String message, List<Subscription> subs) {
    final subList = subs
        .map((s) => '${s.id}: ${s.productName} from ${s.vendorName}')
        .join('\n');

    return '''
You are an AI assistant for a daily consumables delivery app.  
User ID: $userId  

Current subscriptions:  
$subList  

Based on the user message below, decide if they want to:
1) Update delivery config (days & quantity)  
2) Update a single delivery log (cancel or change quantity)  

Return **exactly** a JSON object with these fields:

{
  "intent": "config" | "log",
  "entities": {
    "subscriptionId": "<one of the IDs above>",
    "date": "YYYY-MM-DD" | null,
    "days": ["monday",... ]   | null,
    "quantity":  number       | null,
    "cancel":   boolean       | null
  },
  "confirmation": "string",
  "apiCall": {
    "endpoint": string,
    "method":   "POST" | "PUT",
    "body":     { ...entities..., "userId": "$userId" }
  }
}

User Message: "$message"
''';
  }

  Map<String, dynamic> _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end < 0) return {};
    return json.decode(text.substring(start, end + 1));
  }

  Future<void> _executeApiCall(Map<String, dynamic> api) async {
    final ep = api['endpoint'] as String;
    final m = api['method'] as String;
    final b = api['body'];
    if (m == 'POST') {
      await _api.post(ep, data: b);
    } else if (m == 'PUT') {
      await _api.put(ep, data: b);
    } else {
      throw Exception('Unsupported method $m');
    }
  }
}
