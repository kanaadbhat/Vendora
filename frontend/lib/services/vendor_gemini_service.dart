import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.model.dart';
import '../models/productwithsubscribers.model.dart';
import 'utils/vendor_prompt_builder.dart';
import 'utils/message_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VendorChatGeminiService {
  final GenerativeModel _model;
  late ChatSession _chat;

  VendorChatGeminiService()
    : _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _getApiKey(),
      ) {
    _chat = _model.startChat();
    debugPrint('[DEBUG] VendorChatGeminiService initialized');
  }

  static String _getApiKey() {
    if (kIsWeb && kReleaseMode) {
      // Only use dart-define in production builds on web
      return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    }
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Resets the chat session
  void resetChat() {
    debugPrint(
      '[DEBUG] VendorChatGeminiService.resetChat() - Resetting session',
    );
    _chat = _model.startChat();
  }

  /// Main vendor message handler
  Future<ChatMessage> sendMessage({
    required String message,
    required String userId,
    required List<ProductWithSubscribers> productsWithSubscribers,
    required WidgetRef ref,
  }) async {
    debugPrint(
      '[DEBUG] VendorChatGeminiService.sendMessage() - Message: $message',
    );
    debugPrint(
      '[DEBUG] VendorChatGeminiService.sendMessage() - Products count: ${productsWithSubscribers.length}',
    );

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('Gemini API key not configured');

      // Build vendor prompt
      final prompt = VendorPromptBuilder.buildVendorPrompt(
        userId: userId,
        message: message,
        productsWithSubscribers: productsWithSubscribers,
      );

      final response = await _chat.sendMessage(Content.text(prompt));
      final responseText = response.text ?? '';
      debugPrint(
        '[DEBUG] VendorChatGeminiService.sendMessage() - Gemini response: $responseText',
      );

      return MessageUtils.createAiMessage(
        userId: userId,
        content: responseText,
      );
    } catch (e) {
      debugPrint('[DEBUG] VendorChatGeminiService.sendMessage() - Error: $e');
      return MessageUtils.createAiMessage(
        userId: userId,
        content: "Sorry, I couldn't process that right now.",
      );
    }
  }
}
