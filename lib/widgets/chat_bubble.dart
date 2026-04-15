import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime? timestamp;

  const ChatBubble({
    Key? key,
    required this.text,
    required this.isUser,
    this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFE91E63)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            if (timestamp \!= null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${timestamp\!.hour}:${timestamp\!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
