import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/utils/constants.dart';

class ChatRoom {
  final String id;
  final String chatRoomId;
  final List<Participant> participants;
  final String roomType;
  final String? groupName;
  final String? profileUrl;
  final String? admin;
  final LastMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.chatRoomId,
    required this.participants,
    required this.roomType,
    this.groupName,
    this.profileUrl,
    this.admin,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'],
      chatRoomId: json['chatRoomId'],
      participants: List<Participant>.from(
        json['participants'].map((x) => Participant.fromJson(x)),
      ),
      roomType: json['roomType'],
      groupName: json['groupName'],
      profileUrl: json['profileUrl'],
      admin: json['admin'],
      lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null,
    );
  }
}

class Participant {
  final String userId;
  final String? profilePic;
  final String name;

  Participant({
    required this.userId,
    this.profilePic,
    required this.name,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'],
      profilePic: json['profilePic'],
      name: json['name'],
    );
  }
}

class LastMessage {
  final String messageId;
  final int timestamp;
  final dynamic content;

  LastMessage({
    required this.messageId,
    required this.timestamp,
    required this.content,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      messageId: json['messageId'],
      timestamp: json['timestamp'],
      content: json['content'] is String ? json['content'] : jsonEncode(json['content']),
    );
  }
}

void showChatRoomSheet(BuildContext context, Post post) {
  String? selectedChatRoomId;
  String searchQuery = "";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),

                  // Chat room grid
                  Expanded(
                    child: FutureBuilder<List<ChatRoom>>(
                      future: _fetchChatRooms(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.purple));
                        }

                        if (snapshot.hasError) {
                          print(snapshot.error);
                          return Center(
                              child: Text(
                            'No chat initiated',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ));
                        }

                        final chatRooms = snapshot.data ?? [];

                        // Filter chat rooms based on search query
                        final filteredChatRooms = chatRooms.where((room) {
                          final roomName = room.roomType == 'group' ? room.groupName?.toLowerCase() ?? '' : room.participants.first.name.toLowerCase();
                          return roomName.contains(searchQuery);
                        }).toList();

                        if (filteredChatRooms.isEmpty) {
                          return Center(
                            child: Text(
                              'No matching users found',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: filteredChatRooms.length,
                          itemBuilder: (context, index) {
                            final chatRoom = filteredChatRooms[index];
                            final isSelected = chatRoom.chatRoomId == selectedChatRoomId;

                            final userName = chatRoom.roomType == 'group' ? chatRoom.groupName ?? 'Group' : chatRoom.participants.first.name;

                            final profileImage = chatRoom.roomType == 'group' ? chatRoom.profileUrl : chatRoom.participants.first.profilePic;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedChatRoomId = chatRoom.chatRoomId;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: isSelected ? Border.all(color: Colors.purple, width: 2) : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: isSelected ? Border.all(color: Colors.purple, width: 2) : null,
                                        ),
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.grey[800],
                                          backgroundImage: profileImage != null ? NetworkImage(profileImage) : const AssetImage('assets/avatar/4.png') as ImageProvider,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      userName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Send button
                  if (selectedChatRoomId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: GestureDetector(
                        onTap: () async {
                          if (selectedChatRoomId != null) {
                            await _sendMessage(selectedChatRoomId!, post);
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Send',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Future<List<ChatRoom>> _fetchChatRooms() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  final token = prefs.getString('user_token');

  if (userId == null || token == null) {
    throw Exception('User ID or Token not found');
  }

  final response = await http.get(
    Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
    headers: {
      'userId': userId,
      'token': token,
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    print("Fetched Data: $data");

    List<ChatRoom> chatRooms = List<ChatRoom>.from(
      data['chatRooms'].map((x) {
        ChatRoom chatRoom = ChatRoom.fromJson(x);

        // Remove problematic chat room based on content type
        if (chatRoom.lastMessage?.content is Map<String, dynamic>) {
          print("Removed Chat Room ID: ${chatRoom.chatRoomId}");
          return null; // Skip this chat room
        }

        return chatRoom;
      }),
    ).whereType<ChatRoom>().toList(); // Removes null values

    print("Final Chat Rooms: $chatRooms");
    return chatRooms;
  } else {
    throw Exception('Failed to load chat rooms');
  }
}

Future<void> _sendMessage(String chatRoomId, Post post) async {
  final prefs = await SharedPreferences.getInstance();
  final senderId = prefs.getString('user_id');

  if (senderId != null) {
    final postJson = {
      '_id': post.id,
      'author': post.id,
      'data': {
        'content': post.content,
        'media': post.media,
      },
      'feedId': post.feedId,
      'name': post.usrname,
    };

    SocketService().sendMessage(senderId, chatRoomId, json.encode(postJson), '', false, false);

    Fluttertoast.showToast(msg: 'Sent', gravity: ToastGravity.CENTER, toastLength: Toast.LENGTH_SHORT, backgroundColor: Colors.black, textColor: Colors.white, fontSize: 16);
  }
}
