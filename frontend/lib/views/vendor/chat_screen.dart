import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.model.dart';
import '../../models/productwithsubscribers.model.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../widgets/chatbubble.dart';
import '../../widgets/loadingbubble.dart';

class VendorChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final List<ProductWithSubscribers> productsWithSubscribers;

  const VendorChatScreen({
    super.key,
    required this.userId,
    required this.productsWithSubscribers,
  });

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
          productsWithSubscribers: widget.productsWithSubscribers,
         
        );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);

    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Assistant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                chatState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        if (msg.type == MessageType.system &&
                            msg.metadata?['isLoading'] == true) {
                          return LoadingBubble();
                        }
                        return ChatBubble(message: msg);
                      },
                    ),
          ),
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[100],
              child: Text(
                chatState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


