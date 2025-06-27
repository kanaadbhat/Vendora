import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../widgets/chat/chatInputBar.dart';
import '../../widgets/chat/chatMessageList.dart';
import '../../widgets/chat/errorBanner.dart';
import '../../viewmodels/subscriptionswithdeliveries_viewmodel.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatViewModelProvider.notifier).loadChatHistory(widget.userId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    ref
        .read(chatViewModelProvider.notifier)
        .customerChatSendMessage(
          message: message,
          userId: widget.userId,
          ref: ref,
        );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);
    final chatScreenData = ref.watch(chatScreenDataProvider(widget.userId));

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Assistant')),
      body: chatScreenData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final subscriptions = data.$1;
          if (subscriptions.isEmpty) {
            return const Center(child: Text('Please subscribe to a vendor.'));
          }

          return Column(
            children: [
              Expanded(
                child: ChatMessagesList(
                  messages: chatState.messages,
                  isLoading: chatState.isLoading,
                  scrollController: _scrollController,
                ),
              ),
              if (chatState.error != null)
                ChatErrorBanner(error: chatState.error!),
              const Divider(height: 1),
              ChatInputBar(
                controller: _messageController,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}
