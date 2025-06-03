import '../../models/chat_message.model.dart';

class MessageUtils {
  /// Wraps text into a ChatMessage of type AI, attaching optional metadata
  static ChatMessage createAiMessage({
    required String userId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.ai,
      timestamp: DateTime.now(),
      metadata: {'userId': userId, ...?metadata},
    );
  }

  /// Formats a DateTime as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
