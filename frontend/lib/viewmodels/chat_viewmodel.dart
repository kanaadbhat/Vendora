import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.model.dart';
import '../services/user_gemini_service.dart';
import '../services/vendor_gemini_service.dart';
import '../services/api_service.dart';
import 'subscriptionswithdeliveries_viewmodel.dart';
import '../../viewmodels/productwithsubscribers_viewmodel.dart';

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
  final UserChatGeminiService _userchatgeminiService;
  final VendorChatGeminiService _vendorchatgeminiService;
  final ApiService _apiService;

  ChatViewModel(
    this._userchatgeminiService,
    this._vendorchatgeminiService,
    this._apiService,
  ) : super(const ChatState());

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

  Future<void> vendorChatSendMessage({
    required String message,
    required String userId,
    required WidgetRef ref,
  }) async {
    if (userId.isEmpty) {
      state = state.copyWith(error: 'User ID is required');
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      type: MessageType.user,
      timestamp: DateTime.now(),
      metadata: {'userId': userId},
    );

    state = state.copyWith(messages: [...state.messages, userMessage]);

    try {
      await saveMessage(userMessage);

      final loadingMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Processing...',
        type: MessageType.system,
        timestamp: DateTime.now(),
        metadata: {'userId': userId, 'isLoading': true},
      );
      state = state.copyWith(messages: [...state.messages, loadingMessage]);

      // Get product/subscriber data from provider
      final data = ref.read(productWithSubscribersProvider(userId));
      final productsWithSubscribers = data.asData?.value ?? [];

      final aiMessage = await _vendorchatgeminiService.sendMessage(
        message: message,
        userId: userId,
        productsWithSubscribers: productsWithSubscribers,
        ref: ref,
      );

      // Remove loading bubble
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
    } catch (e) {
      state = state.copyWith(error: 'Error sending message: $e');
    }
  }

  Future<void> customerChatSendMessage({
    required String message,
    required String userId,
    required WidgetRef ref,
  }) async {
    if (userId.isEmpty) {
      state = state.copyWith(error: 'User ID is required');
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      type: MessageType.user,
      timestamp: DateTime.now(),
      metadata: {'userId': userId},
    );

    state = state.copyWith(messages: [...state.messages, userMessage]);

    try {
      await saveMessage(userMessage);

      final loadingMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Processing...',
        type: MessageType.system,
        timestamp: DateTime.now(),
        metadata: {'userId': userId, 'isLoading': true},
      );
      state = state.copyWith(messages: [...state.messages, loadingMessage]);

      final data = ref.read(chatScreenDataProvider(userId));
      final subscriptions = data.asData?.value.$1 ?? [];
      final subscriptionDeliveries = data.asData?.value.$2 ?? [];

      final aiMessage = await _userchatgeminiService.sendMessage(
        message: message,
        userId: userId,
        subscriptions: subscriptions,
        subscriptionDeliveries: subscriptionDeliveries,
        ref: ref,
      );

      // Remove loading bubble
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
    } catch (e) {
      state = state.copyWith(error: 'Error sending message: $e');
    }
  }
}

final chatViewModelProvider = StateNotifierProvider<ChatViewModel, ChatState>((
  ref,
) {
  final apiService = ApiService();
  final userchatgeminiService = UserChatGeminiService(apiService);
  final vendorchatgeminiService = VendorChatGeminiService();
  return ChatViewModel(
    userchatgeminiService,
    vendorchatgeminiService,
    apiService,
  );
});
