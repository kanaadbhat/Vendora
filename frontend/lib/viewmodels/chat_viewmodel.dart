import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.model.dart';
import '../models/subscription_model.dart';
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
    await saveMessage(userMessage); // Ensure you're sending proper JSON

    // Get AI response
    final aiMessage = await _geminiService.sendMessage(
      message: message,
      userId: userId,
      subscriptions: subscriptions,
    );

    // Ensure AI message has proper metadata with userId
    final aiMessageWithMetadata = aiMessage.copyWith(
      metadata: {...?aiMessage.metadata, 'userId': userId},
    );

    // Add AI message to state
    state = state.copyWith(messages: [...state.messages, aiMessageWithMetadata]);

    // Save AI message to backend
    await saveMessage(aiMessageWithMetadata);

    // Handle any backend actions from the AI response
    if (aiMessageWithMetadata.metadata != null) {
      final apiCall = aiMessageWithMetadata.metadata!['apiCall'] as Map<String, dynamic>?;
      if (apiCall != null) {
        await _handleBackendAction(apiCall);
      }
    }
  } catch (e) {
    state = state.copyWith(error: 'Error sending message: $e');
    // Consider adding retry logic or more specific error handling
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

      switch (method) {
        case 'POST':
          await _apiService.post(endpoint, data: body ?? {});
          break;
        case 'PUT':
          await _apiService.put(endpoint, data: body ?? {});
          break;
        case 'GET':
          await _apiService.get(endpoint);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      debugPrint('Error executing API call: $e');
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
