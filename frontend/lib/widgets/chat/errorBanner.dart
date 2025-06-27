import 'package:flutter/material.dart';

class ChatErrorBanner extends StatelessWidget {
  final String error;

  const ChatErrorBanner({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red[100],
      child: Text(
        error,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
