import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;

  ReactionPicker({super.key, required this.onReactionSelected});

  final List<String> emojis = ['😊', '❤️', '😂', '😮', '😢', '👍'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: emojis.map((emoji) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                onReactionSelected(emoji);
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
