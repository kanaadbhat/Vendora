import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.model.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../widgets/chat/chatbubble.dart';
import '../../widgets/chat/loadingbubble.dart';
import '../../viewmodels/productwithsubscribers_viewmodel.dart';
import '../../widgets/chat/chatInputBar.dart';
import '../../widgets/chat/chatMessageList.dart';
import '../../widgets/chat/errorBanner.dart';

class VendorChatScreen extends ConsumerStatefulWidget {
  final String userId;

  const VendorChatScreen({super.key, required this.userId});

  @override
  ConsumerState<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends ConsumerState<VendorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load chat history when screen starts
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
  void didUpdateWidget(VendorChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    ref
        .read(chatViewModelProvider.notifier)
        .vendorChatSendMessage(
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
    final data = ref.watch(productWithSubscribersProvider(widget.userId));

    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Assistant'), centerTitle: true),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data.isEmpty) {
            return const Center(child: Text('Please add products.'));
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
