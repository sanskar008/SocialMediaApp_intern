import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final VoidCallback? onLongPress; // New callback for long press

  const ChatMessage({
    super.key,
    required this.messageData,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Extracting the necessary information
    var senderInfo = messageData['senderInfo'] ?? {};
    var name = senderInfo['name'] ?? 'Unknown';
    var profilePic = senderInfo['profilePic'] ?? '';
    var message = messageData['message'] ?? '';
    var reactions =
        (messageData['reactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: GestureDetector(
        onLongPress: onLongPress, // Trigger long press
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle avatar for the sender
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child: profilePic.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.black),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            // Message container
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(fontSize: 16),
                        ),
                        // Display reactions
                        if (reactions.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: reactions.map((reaction) {
                              return Text(
                                reaction['reaction'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
