import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl for timestamp formatting
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/users/show_post_content.dart';

class Message {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final SharedPost? sharedPost;
  final StoryReply? entity;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    this.sharedPost,
    this.entity,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    SharedPost? sharedPost;
    StoryReply? storyReply;
    String content = json['content'] ?? '';

    // Try to decode content as JSON (if it's a valid JSON string)
    try {
      final decodedContent = jsonDecode(content);
      if (decodedContent is Map<String, dynamic>) {
        // If it has "_id" and "data" keys, treat it as a SharedPost
        if (decodedContent.containsKey('_id') &&
            decodedContent.containsKey('data')) {
          sharedPost = SharedPost.fromJson(decodedContent);
        }
      }
    } catch (e) {
      // If parsing fails, it means content is a normal text message
    }

    // Try to decode entity as JSON (if applicable)
    try {
      final entityDecoded = jsonDecode(json['entity'] ?? '{}');
      if (entityDecoded is Map<String, dynamic> &&
          entityDecoded.containsKey('entityId') &&
          entityDecoded.containsKey('entity')) {
        storyReply = StoryReply.fromJson(entityDecoded);
      }
    } catch (e) {}

    // Handle timestamp conversion: if it's an int, convert it from Unix time.
    DateTime parsedTimestamp;
    if (json['timestamp'] != null) {
      if (json['timestamp'] is int) {
        // Assuming timestamp is in seconds
        parsedTimestamp =
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000);
      } else if (json['timestamp'] is String) {
        parsedTimestamp = DateTime.parse(json['timestamp']);
      } else {
        parsedTimestamp = DateTime.now();
      }
    } else {
      parsedTimestamp = DateTime.now();
    }

    return Message(
      id: json['_id'] ?? '',
      content: sharedPost != null ? '' : content,
      senderId: json['senderId'] ?? json['senderInfo']?['_id'] ?? '',
      timestamp: parsedTimestamp,
      sharedPost: sharedPost,
      entity: storyReply,
    );
  }
}

class SharedPost {
  final String id;
  final String author;
  final PostData data;
  final String feedId;
  final String name;

  SharedPost({
    required this.id,
    required this.author,
    required this.data,
    required this.feedId,
    required this.name,
  });

  factory SharedPost.fromJson(Map<String, dynamic> json) {
    return SharedPost(
      id: json['_id'],
      author: json['author'],
      data: PostData.fromJson(json['data']),
      feedId: json['feedId'],
      name: json['name'],
    );
  }
}

class PostData {
  final String content;
  final List<Media>? media;

  PostData({
    required this.content,
    this.media,
  });

  factory PostData.fromJson(Map<String, dynamic> json) {
    return PostData(
      content: json['content'],
      media: (json['media'] as List?)
          ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Media {
  final String url;
  final String type;

  Media({
    required this.url,
    required this.type,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      url: json['url'],
      type: json['type'],
    );
  }
}

class StoryReply {
  final String content;
  final String? storyUrl; // Extracted from the inner entity
  final bool isBot;

  StoryReply({
    required this.content,
    this.storyUrl,
    required this.isBot,
  });

  factory StoryReply.fromJson(Map<String, dynamic> json) {
    // Check if the entity is nested within another 'entity' key
    final entityDetails = json['entity'] is Map ? json['entity'] : json;

    return StoryReply(
      content: json["content"],
      storyUrl:
          entityDetails['url'], // Extract URL from nested or top-level entity
      isBot: json["isBot"] ?? false,
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSender;
  final Map<String, Participant> participantsMap;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    required this.participantsMap,
    required this.currentUserId,
  });

  String _getSenderName() {
    if (isSender) return ''; // Don't show name for your own messages

    final participant = participantsMap[message.senderId];
    return participant?.name ?? 'Unknown User';
  }

  // Format timestamp to show time for today, or date for older messages
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(timestamp); // e.g., 3:45 PM
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('h:mm a').format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a')
          .format(timestamp); // e.g., Oct 10, 3:45 PM
    }
  }

  @override
  Widget build(BuildContext context) {
    final senderName = _getSenderName();

    return Column(
      crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (senderName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
            child: Text(
              senderName,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Align(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSender ? const Color(0xFF7400A5) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: message.entity != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.entity != null) _buildStoryReply(context),
                          Text(
                            message.content,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ],
                      )
                    : message.sharedPost != null
                        ? _buildSharedPost(context)
                        : Text(
                            message.content,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
              ),
              // Add timestamp below the message
              Padding(
                padding: EdgeInsets.only(
                  left: isSender ? 0 : 16,
                  right: isSender ? 16 : 0,
                  bottom: 4,
                ),
                child: Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryReply(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Post header
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('replied to your story'),
            SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 8),
        // Post media
        if (message.entity!.storyUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.entity!.storyUrl ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 150,
            ),
          ),
      ],
    );
  }

  Widget _buildSharedPost(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PostDetailsScreen(feedId: message.sharedPost!.feedId)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Post header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/avatar/4.png'),
                radius: 12,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.sharedPost!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Post media (looping over the media list)
          if (message.sharedPost!.data.media != null &&
              message.sharedPost!.data.media!.isNotEmpty)
            Column(
              children: message.sharedPost!.data.media!.map((media) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      media.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                    ),
                  ),
                );
              }).toList(),
            ),

          // Post content
          if (message.sharedPost!.data.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: message.sharedPost!.data.media != null &&
                        message.sharedPost!.data.media!.isNotEmpty
                    ? 8
                    : 0,
              ),
              child: Text(
                message.sharedPost!.data.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
