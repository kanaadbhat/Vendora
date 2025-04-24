import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.model.dart';
import '../models/subscription.model.dart';
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
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.get('/chat/$userId');
      if (response.statusCode == 200) {
        final messages =
            (response.data as List)
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList();
        state = state.copyWith(messages: messages, isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Failed to load chat history',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> saveMessage(ChatMessage message) async {
    try {
      final response = await _apiService.post('/chat', data: message.toJson());
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
  }) async {
    // Add user message to state
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMessage]);

    // Save user message to backend
    await saveMessage(userMessage);

    // Get AI response
    try {
      final aiMessage = await _geminiService.sendMessage(
        message: message,
        userId: userId,
        subscriptions: subscriptions,
      );

      // Add AI message to state
      state = state.copyWith(messages: [...state.messages, aiMessage]);

      // Save AI message to backend
      await saveMessage(aiMessage);

      // Handle any backend actions from the AI response
      if (aiMessage.metadata != null) {
        final apiCall = aiMessage.metadata!['apiCall'] as Map<String, dynamic>?;
        if (apiCall != null) {
          await _handleBackendAction(apiCall);
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _handleBackendAction(Map<String, dynamic> apiCall) async {
    final endpoint = apiCall['endpoint'] as String;
    final method = apiCall['method'] as String;
    final body = apiCall['body'];

    switch (method) {
      case 'POST':
        await _apiService.post(endpoint, data: body);
        break;
      case 'PUT':
        await _apiService.put(endpoint, data: body);
        break;
      case 'GET':
        await _apiService.get(endpoint);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
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
