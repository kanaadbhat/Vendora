import 'package:flutter/material.dart';
import '../../models/chat_message.model.dart';
import '../../widgets/chat/chatbubble.dart';
import '../../widgets/chat/loadingbubble.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ScrollController scrollController;

  const ChatMessagesList({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        if (msg.type == MessageType.system &&
            msg.metadata?['isLoading'] == true) {
          return  LoadingBubble();
        }
        return ChatBubble(message: msg);
      },
    );
  }
}
