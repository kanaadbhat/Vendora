import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/chat_message.model.dart';
import '../models/subscription_model.dart';
import '../models/subscriptionDeliveries.model.dart';
import '../services/api_service.dart';
import 'utils/user_prompt_builder.dart';
import 'utils/message_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/subscriptionswithdeliveries_viewmodel.dart';

class UserChatGeminiService {
  final GenerativeModel _model;
  late ChatSession _chat;
  final ApiService _api;
  Map<String, dynamic>? _pendingAction;

  UserChatGeminiService(this._api)
    : _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _getApiKey(),
      ) {
    _chat = _model.startChat();
    debugPrint('[DEBUG] GeminiService initialized');
  }

  static String _getApiKey() {
    if (kIsWeb && kReleaseMode) {
      // Only use dart-define in production builds on web
      return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    }
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Resets the chat session and clears any pending action
  void resetChat() {
    debugPrint('[DEBUG] GeminiService.resetChat() - Resetting chat session');
    _chat = _model.startChat();
    _pendingAction = null;
  }

  /// Main entry point: handles user message and routes to the right handler.
  Future<ChatMessage> sendMessage({
    required String userId,
    required String message,
    required List<Subscription> subscriptions,
    required List<SubscriptionDelivery> subscriptionDeliveries,
    required WidgetRef ref,
  }) async {
    debugPrint(
      '[DEBUG] GeminiService.sendMessage() - Processing message: $message',
    );
    debugPrint('[DEBUG] GeminiService.sendMessage() - User ID: $userId');
    debugPrint(
      '[DEBUG] GeminiService.sendMessage() - Subscriptions count: ${subscriptions.length}',
    );
    debugPrint(
      '[DEBUG] GeminiService.sendMessage() - SubscriptionDeliveries count: ${subscriptionDeliveries.length}',
    );

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('Gemini API key not configured');

      // If we're waiting on a confirmation, handle that first
      if (_pendingAction != null) {
        debugPrint(
          '[DEBUG] GeminiService.sendMessage() - Handling confirmation response',
        );
        final response = await _handleConfirmationResponse(
          userId: userId,
          userResponse: message,
          ref: ref,
        );
        return response;
      }

      // Get response from Gemini
      debugPrint('[DEBUG] GeminiService.sendMessage() - Building prompt');
      final prompt = UserPromptBuilder.buildPrompt(
        userId: userId,
        message: message,
        subscriptions: subscriptions,
        subscriptionDeliveries: subscriptionDeliveries,
      );

      debugPrint(
        '[DEBUG] GeminiService.sendMessage() - Sending message to Gemini',
      );
      final response = await _chat.sendMessage(Content.text(prompt));
      final responseText = response.text ?? '';
      debugPrint(
        '[DEBUG] GeminiService.sendMessage() - Raw Gemini response: $responseText',
      );

      // Try to parse as JSON to check if it's an action
      try {
        debugPrint(
          '[DEBUG] GeminiService.sendMessage() - Attempting to parse response as JSON',
        );

        // Extract JSON from markdown code blocks if present
        String jsonString = responseText;
        final markdownJsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
        final match = markdownJsonRegex.firstMatch(responseText);

        if (match != null && match.groupCount >= 1) {
          jsonString = match.group(1)!.trim();
          debugPrint(
            '[DEBUG] GeminiService.sendMessage() - Extracted JSON from markdown: $jsonString',
          );
        }

        final jsonResponse = jsonDecode(jsonString);
        debugPrint(
          '[DEBUG] GeminiService.sendMessage() - Parsed JSON: ${jsonEncode(jsonResponse)}',
        );

        if (jsonResponse['action'] != null) {
          debugPrint(
            '[DEBUG] GeminiService.sendMessage() - Action detected in response',
          );
          _pendingAction = jsonResponse['action'];
          debugPrint(
            '[DEBUG] GeminiService.sendMessage() - Confirmation message: ${_pendingAction!['confirmation']}',
          );
          return MessageUtils.createAiMessage(
            userId: userId,
            content: _pendingAction!['confirmation'],
            metadata: {'isActionConfirmation': true},
          );
        }
      } catch (e) {
        // Not a JSON response, treat as normal message
        debugPrint(
          '[DEBUG] GeminiService.sendMessage() - Not a JSON response: $e',
        );
      }

      debugPrint(
        '[DEBUG] GeminiService.sendMessage() - Returning normal message response',
      );
      return MessageUtils.createAiMessage(
        userId: userId,
        content: responseText,
      );
    } catch (e) {
      debugPrint('[DEBUG] GeminiService error: $e');
      return MessageUtils.createAiMessage(
        userId: userId,
        content: "Sorry, I can't help with that right now",
      );
    }
  }

  Future<ChatMessage> _handleConfirmationResponse({
    required String userId,
    required String userResponse,
    required WidgetRef ref,
  }) async {
    debugPrint(
      '[DEBUG] GeminiService._handleConfirmationResponse() - Processing: $userResponse',
    );

    if (_pendingAction == null) {
      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - No pending action found',
      );
      return MessageUtils.createAiMessage(
        userId: userId,
        content: "I'm not sure what you're confirming. Let's start over.",
      );
    }

    // Check if user confirmed
    final isConfirmed = userResponse.toLowerCase().contains(
      RegExp(r'\b(yes|yeah|sure|ok|okay|confirm|proceed)\b'),
    );
    debugPrint(
      '[DEBUG] GeminiService._handleConfirmationResponse() - User confirmed: $isConfirmed',
    );

    if (!isConfirmed) {
      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - User declined, clearing pending action',
      );
      _pendingAction = null;
      return MessageUtils.createAiMessage(
        userId: userId,
        content: "Alright, let's continue with something else.",
      );
    }

    try {
      // Execute the API call
      final apiCall = _pendingAction!['apiCall'];
      final method = apiCall['method'];
      final endpoint = apiCall['endpoint'];
      final body = apiCall['body'];
      final successMessage = _pendingAction!['successMessage'];

      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - Executing API call:',
      );
      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - Method: $method',
      );
      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - Endpoint: $endpoint',
      );
      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - Body: $body',
      );

      Response response;
      switch (method) {
        case 'POST':
          response = await _api.post(endpoint, data: body);
          break;
        case 'PUT':
          response = await _api.put(endpoint, data: body);
          break;
        case 'GET':
          response = await _api.get(endpoint);
          break;
        case 'DELETE':
          response = await _api.delete(endpoint, data: body);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - API response status: ${response.statusCode}',
      );
      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - API response data: ${response.data}',
      );

      // Store success message before clearing pending action
      final storedSuccessMessage = successMessage;
      _pendingAction = null;

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint(
          '[DEBUG] GeminiService._handleConfirmationResponse() - API call successful',
        );
        debugPrint(
          '[DEBUG] GeminiService._handleConfirmationResponse() - Success message: $storedSuccessMessage',
        );
        debugPrint('[DEBUG] Invalidating chatScreenDataProvider($userId)');
        ref.invalidate(chatScreenDataProvider(userId));
        return MessageUtils.createAiMessage(
          userId: userId,
          content: storedSuccessMessage,
        );
      } else {
        debugPrint(
          '[DEBUG] GeminiService._handleConfirmationResponse() - API call failed',
        );
        return MessageUtils.createAiMessage(
          userId: userId,
          content: "The changes couldn't be saved. Please try again later.",
        );
      }
    } catch (e) {
      debugPrint(
        '[DEBUG] GeminiService._handleConfirmationResponse() - Error: $e',
      );
      _pendingAction = null;
      return MessageUtils.createAiMessage(
        userId: userId,
        content:
            "There was an error processing your request. Please try again later.",
      );
    }
  }
}
