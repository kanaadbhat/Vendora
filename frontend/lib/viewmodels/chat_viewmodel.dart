import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.model.dart';
import '../models/subscription_model.dart';
import '../models/subscriptionDeliveries.model.dart';
import '../services/gemini_service.dart';
import '../services/api_service.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  final GeminiService _geminiService;
  final ApiService _apiService;

  ChatViewModel(this._geminiService, this._apiService)
    : super(const ChatState());

  Future<void> loadChatHistory(String userId) async {
    if (userId.isEmpty) {
      state = state.copyWith(error: 'User ID is required', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.get('/chat/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data as List<dynamic>;
        final messages =
            messagesData
                .map((e) {
                  try {
                    return ChatMessage.fromJson(e as Map<String, dynamic>);
                  } catch (e) {
                    debugPrint('Error parsing message: $e');
                    return null;
                  }
                })
                .whereType<ChatMessage>()
                .toList();

        // Sort messages by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        state = state.copyWith(messages: messages, isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Failed to load chat history: ${response.statusCode}',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error loading chat history: $e',
        isLoading: false,
      );
    }
  }

  Future<void> saveMessage(ChatMessage message) async {
    try {
      final sanitizedMetadata = Map<String, dynamic>.from(
        message.metadata ?? {},
      );
      sanitizedMetadata.remove('apiCall');

      final messageData = {
        'userId': message.metadata?['userId'] ?? '',
        'content': message.content,
        'type': message.type.toString().split('.').last,
        'metadata': sanitizedMetadata,
      };

      debugPrint('Saving Message: $messageData');

      final response = await _apiService.post('/chat', data: messageData);
      if (response.statusCode != 201) {
        debugPrint('Failed to save message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to save message: $e');
    }
  }

  Future<void> sendMessage({
    required String message,
    required String userId,
    required List<Subscription> subscriptions,
    required List<SubscriptionDelivery> subscriptionDeliveries,
  }) async {
    if (userId.isEmpty) {
      state = state.copyWith(error: 'User ID is required');
      return;
    }

    // Add user message to state
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      type: MessageType.user,
      timestamp: DateTime.now(),
      metadata: {'userId': userId},
    );
    state = state.copyWith(messages: [...state.messages, userMessage]);

    try {
      // Save user message to backend
      await saveMessage(userMessage);

      // Add loading message
      final loadingMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Processing...',
        type: MessageType.system,
        timestamp: DateTime.now(),
        metadata: {'userId': userId, 'isLoading': true},
      );
      state = state.copyWith(messages: [...state.messages, loadingMessage]);

      // Get AI response
      final aiMessage = await _geminiService.sendMessage(
        message: message,
        userId: userId,
        subscriptions: subscriptions,
        subscriptionDeliveries: subscriptionDeliveries,
      );

      // Remove loading message
      state = state.copyWith(
        messages:
            state.messages.where((m) => m.id != loadingMessage.id).toList(),
      );

      final aiMessageWithMetadata = aiMessage.copyWith(
        metadata: {...?aiMessage.metadata, 'userId': userId},
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessageWithMetadata],
      );
      await saveMessage(aiMessageWithMetadata);

      if (aiMessageWithMetadata.metadata != null) {
        final apiCall =
            aiMessageWithMetadata.metadata!['apiCall'] as Map<String, dynamic>?;
        if (apiCall != null) {
          await _handleBackendAction(apiCall);
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Error sending message: $e');
    }
  }

  Future<void> _handleBackendAction(Map<String, dynamic> apiCall) async {
    try {
      final endpoint = apiCall['endpoint'] as String? ?? '';
      final method = apiCall['method'] as String? ?? '';
      final body = apiCall['body'];

      debugPrint('=== API Call Debug ===');
      debugPrint('Method: $method');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Body: ${body ?? 'No body'}');
      debugPrint('=======================');

      if (endpoint.isEmpty || method.isEmpty) {
        debugPrint('Invalid API call metadata');
        return;
      }

      dynamic response;
      switch (method) {
        case 'POST':
          response = await _apiService.post(endpoint, data: body ?? {});
          break;
        case 'PUT':
          response = await _apiService.put(endpoint, data: body ?? {});
          break;
        case 'GET':
          response = await _apiService.get(endpoint);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('API call successful: ${response.statusCode}');
      } else {
        debugPrint('API call failed: ${response.statusCode}');
        throw Exception('API call failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error executing API call: $e');
      throw e;
    }
  }
}

final chatViewModelProvider = StateNotifierProvider<ChatViewModel, ChatState>((
  ref,
) {
  final apiService = ApiService();
  final geminiService = GeminiService(apiService);
  return ChatViewModel(geminiService, apiService);
});
