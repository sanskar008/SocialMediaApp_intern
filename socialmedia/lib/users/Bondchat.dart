// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
// import 'package:socialmedia/bottom_nav_bar/activity/group/shimmerchatscreen.dart';

// import 'package:socialmedia/services/chat_socket_service.dart';
// import 'package:socialmedia/services/voice_settings.dart';
// import 'package:socialmedia/users/searched_userprofile.dart';
// import 'package:socialmedia/utils/constants.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:just_audio/just_audio.dart';

// import 'dart:typed_data';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class UserRecommendation {
//   final String id;
//   final String name;
//   final String nickName;
//   final List<String> interests;
//   final int matchingInterestsCount;
//   final bool hasMessageInterest;

//   UserRecommendation({
//     required this.id,
//     required this.name,
//     required this.nickName,
//     required this.interests,
//     required this.matchingInterestsCount,
//     required this.hasMessageInterest,
//   });

//   factory UserRecommendation.fromJson(Map<String, dynamic> json) {
//     return UserRecommendation(
//       id: json['_id'],
//       name: json['name'],
//       nickName: json['nickName'],
//       interests: List<String>.from(json['interests'] ?? []),
//       matchingInterestsCount: json['matchingInterestsCount'] ?? 0,
//       hasMessageInterest: json['hasMessageInterest'] ?? false,
//     );
//   }
// }

// class ChatMessage {
//   final String id;
//   final dynamic content;
//   final String senderId;
//   final DateTime createdAt;
//   final String? media;
//   final String entity;
//   final bool isBot;
//   final List<UserRecommendation>? userRecommendations;

//   ChatMessage({
//     required this.id,
//     required this.content,
//     required this.senderId,
//     required this.createdAt,
//     this.media,
//     required this.entity,
//     this.isBot = false,
//     this.userRecommendations,
//   });

//   factory ChatMessage.fromJson(Map<String, dynamic> json) {
//     dynamic messageContent = json['content'];
//     List<UserRecommendation>? users;

//     // Check if content is a map with 'users' array
//     if (messageContent is Map<String, dynamic> && messageContent.containsKey('users') && messageContent['users'] is List) {
//       users = (messageContent['users'] as List).map((user) => UserRecommendation.fromJson(user)).toList();

//       // Extract just the text message part
//       messageContent = messageContent['message'] ?? '';
//     }

//     return ChatMessage(
//       id: json['_id'] ?? json['id'] ?? DateTime.now().toString(),
//       content: messageContent,
//       senderId: json['senderId'],
//       createdAt: json['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000) : DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
//       media: json['media'],
//       entity: json['entity'] ?? '',
//       isBot: json['isBot'] ?? false,
//       userRecommendations: users,
//     );
//   }
// }

// class BondChatScreen extends StatefulWidget {
//   const BondChatScreen({Key? key}) : super(key: key);

//   @override
//   _BondChatScreenState createState() => _BondChatScreenState();
// }

// class _BondChatScreenState extends State<BondChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final SocketService _socketService = SocketService();
//   final _pagingController = PagingController<int, ChatMessage>(firstPageKey: 1);
//   static const _pageSize = 20;

//   String? _currentUserId;
//   String? _chatRoomId;
//   String? _token;
//   bool _isLoading = true;
//   bool _isSpeakerOn = false;
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   stt.SpeechToText _speech = stt.SpeechToText();
//   bool _isListening = false;
//   String _selectedVoice = 'male';
//   String _botName = 'Michael';

//   @override
//   void initState() {
//     super.initState();
//     _loadVoiceSettings();
//     _initializeChat();
//   }

//   Future<void> _loadVoiceSettings() async {
//     final voice = await VoiceSettings.getSelectedVoice();
//     setState(() {
//       _selectedVoice = voice;
//       _botName = VoiceSettings.getVoiceName(voice);
//     });
//   }

//   Future<void> _fetchPage(int pageKey) async {
//     try {
//       print('Fetching page $pageKey for room $_chatRoomId');

//       if (_chatRoomId == null) {
//         print('Chat room ID is null');
//         return;
//       }

//       final response = await http.post(
//         Uri.parse('${BASE_URL}api/get-all-messages'),
//         headers: {
//           'userid': _currentUserId!,
//           'token': _token!,
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'roomId': _chatRoomId,
//           'page': pageKey.toString(),
//           'limit': _pageSize.toString(),
//         }),
//       );

//       print('API Response status: ${response.statusCode}');
//       print('API Response body: ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = jsonDecode(response.body);
//         final List<dynamic> messagesList = responseData['messages'];
//         final messages = messagesList.map((msg) => ChatMessage.fromJson(msg)).toList();

//         final isLastPage = responseData['currentPage'] >= responseData['totalPages'];

//         if (isLastPage) {
//           _pagingController.appendLastPage(messages);
//         } else {
//           final nextPageKey = pageKey + 1;
//           _pagingController.appendPage(messages, nextPageKey);
//         }

//         setState(() {
//           _isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to fetch messages: ${response.statusCode}');
//       }
//     } catch (error) {
//       print('Error fetching messages: $error');
//       _pagingController.error = error;
//     }
//   }

//   Future<void> _initializeChat() async {
//     try {
//       print('Initializing chat...');
//       final prefs = await SharedPreferences.getInstance();
//       _token = prefs.getString('user_token');
//       _currentUserId = prefs.getString('user_id');

//       print('Token: $_token');
//       print('User ID: $_currentUserId');

//       if (_token == null || _currentUserId == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Authentication required')),
//         );
//         return;
//       }

//       final response = await http.post(
//         Uri.parse('${BASE_URL}api/start-message'),
//         headers: {
//           'userid': _currentUserId!,
//           'token': _token!,
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({'userId2': '67d3bf8914c75ee094e30bfa'}),
//       );

//       print('Start message response: ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = jsonDecode(response.body);
//         setState(() {
//           _chatRoomId = responseData['chatRoom']['chatRoomId'];
//         });

//         // Initialize paging controller after getting chat room ID
//         _pagingController.addPageRequestListener((pageKey) {
//           _fetchPage(pageKey);
//         });

//         await _socketService.connect();
//         _socketService.joinRoom(_chatRoomId!);

//         // Trigger initial load
//         _fetchPage(1);

//         _socketService.onMessageReceived = (message) {
//           final newMessage = ChatMessage.fromJson(message);

//           print(newMessage);

//           if (_pagingController.itemList == null) {
//             _pagingController.itemList = [];
//           }
//           _pagingController.itemList!.insert(0, newMessage);
//           setState(() {});
//           if (_isSpeakerOn && message['isBot'] == true && message['media'] != null) {
//             print("🎵 Polly audio detected, playing...");
//             Future.microtask(() async {
//               await _playPollyAudio(message['media']);
//             });
//           }
//         };
//       } else {
//         print('Failed to start chat: ${response.statusCode}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to start chat')),
//         );
//       }
//     } catch (e) {
//       print('Error initializing chat: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('An error occurred')),
//       );
//     }
//   }

//   Future<void> _playPollyAudio(String base64Audio) async {
//     try {
//       print("🎵 Starting audio playback process...");

//       // Decode base64 to binary data
//       Uint8List audioBytes = base64Decode(base64Audio);
//       print("🎵 Base64 decoded successfully, audio size: ${audioBytes.length} bytes");

//       // Get temporary directory
//       Directory tempDir = await getTemporaryDirectory();
//       String filePath = '${tempDir.path}/polly_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

//       // Save audio file
//       File audioFile = File(filePath);
//       await audioFile.writeAsBytes(audioBytes);
//       print("🎵 Audio file saved to: $filePath");

//       // Stop any currently playing audio
//       await _audioPlayer.stop();

//       // Set the audio source and play
//       await _audioPlayer.setFilePath(filePath);
//       print("🎵 Audio source set successfully");

//       // Add error listener
//       _audioPlayer.playbackEventStream.listen(
//         (event) {
//           print("🎵 Playback event: $event");
//         },
//         onError: (Object e, StackTrace st) {
//           print("⚠ Audio playback error: $e");
//         },
//       );

//       // Play the audio
//       await _audioPlayer.play();
//       print("🎵 Audio playback started");

//       // Clean up the file after playback
//       _audioPlayer.playerStateStream.listen((state) {
//         if (state.processingState == ProcessingState.completed) {
//           print("🎵 Audio playback completed, cleaning up file");
//           audioFile.delete().catchError((error) {
//             print("⚠ Error deleting audio file: $error");
//           });
//         }
//       });

//     } catch (e) {
//       print("⚠ Error in _playPollyAudio: $e");
//     }
//   }

//   void _toggleVoice() async {
//     final newVoice = _selectedVoice == 'male' ? 'female' : 'male';
//     await VoiceSettings.setSelectedVoice(newVoice);
//     setState(() {
//       _selectedVoice = newVoice;
//       _botName = VoiceSettings.getVoiceName(newVoice);
//     });
//   }

//   void _sendMessage() {
//     final message = _messageController.text.trim();
//     if (message.isNotEmpty && _chatRoomId != null) {
//       final newMessage = ChatMessage(
//         id: DateTime.now().toString(),
//         content: message,
//         senderId: _currentUserId!,
//         createdAt: DateTime.now(),
//         entity: '',
//       );

//       if (_pagingController.itemList == null) {
//         _pagingController.itemList = [];
//       }
//       _pagingController.itemList!.insert(0, newMessage);
//       setState(() {});

//       _socketService.sendMessage(
//         _currentUserId!,
//         _chatRoomId!,
//         message,
//         '',
//         true,
//         _isSpeakerOn,
//         voice: _selectedVoice,

//       );

//       if (_isListening) {
//         _speech.stop();
//         setState(() => _isListening = false);
//       }

//       _messageController.clear();
//     }
//   }

//   void _startListening() async {
//     bool available = await _speech.initialize(
//       onStatus: (status) {
//         print("🎤 Speech Status: $status");
//       },
//       onError: (errorNotification) {
//         print("Speech Error: $errorNotification");
//       },
//     );

//     if (available) {
//       setState(() => _isListening = true);
//       _speech.listen(
//         onResult: (result) {
//           if (!_isListening) return;
//           setState(() {
//             _messageController.text = result.recognizedWords;
//           });
//         },
//       );
//     } else {
//       print("Speech Recognition is not available.");
//     }
//   }

//   void _stopListening() {
//     _speech.stop();
//     setState(() => _isListening = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: Text(_botName, style: GoogleFonts.poppins(color: Colors.white)),
//         actions: [
//           IconButton(
//             icon: Icon(
//               _selectedVoice == 'male' ? Icons.man : Icons.woman,
//               color: const Color(0xFF7400A5),
//             ),
//             onPressed: _toggleVoice,
//             tooltip: 'Switch to ${_selectedVoice == 'male' ? 'female' : 'male'} voice',
//           ),
//           IconButton(
//             icon: Icon(
//                 _isSpeakerOn ? Icons.volume_up_outlined : Icons.volume_off,
//                 color: const Color(0xFF7400A5)),
//             onPressed: () {
//               setState(() {
//                 _isSpeakerOn = !_isSpeakerOn;
//               });
//             },
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: _isLoading
//             ? const Center(child: CompleteChatShimmer())
//             : Column(
//                 children: [
//                   Expanded(
//                     child: RefreshIndicator(
//                       onRefresh: () async {
//                         _pagingController.refresh();
//                       },
//                       child: PagedListView<int, ChatMessage>(
//                         pagingController: _pagingController,
//                         reverse: true,
//                         builderDelegate: PagedChildBuilderDelegate<ChatMessage>(
//                           itemBuilder: (context, message, index) {
//                             final isMe = message.senderId == _currentUserId;
//                             final isBot = message.isBot;

//                             if (message.userRecommendations != null &&
//                                 message.userRecommendations!.isNotEmpty) {
//                               return Column(
//                                 crossAxisAlignment: isMe
//                                     ? CrossAxisAlignment.end
//                                     : CrossAxisAlignment.start,
//                                 children: [
//                                   // Message bubble with text
//                                   Align(
//                                     alignment: isMe
//                                         ? Alignment.centerRight
//                                         : Alignment.centerLeft,
//                                     child: Container(
//                                       margin: const EdgeInsets.symmetric(
//                                           vertical: 5, horizontal: 10),
//                                       padding: const EdgeInsets.all(12),
//                                       decoration: BoxDecoration(
//                                         color: isMe
//                                             ? const Color(0xFF7400A5)
//                                             : Colors.grey.shade800,
//                                         borderRadius: BorderRadius.circular(15),
//                                       ),
//                                       child: Text(
//                                         message.content.toString(),
//                                         style: GoogleFonts.poppins(
//                                             color: Colors.white),
//                                       ),
//                                     ),
//                                   ),

//                                   // User recommendations section
//                                   Container(
//                                     margin: const EdgeInsets.symmetric(
//                                         vertical: 5, horizontal: 10),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         // User tiles
//                                         ...message.userRecommendations!
//                                             .map((user) => GestureDetector(
//                                                 onTap: () {
//                                                   Navigator.pushReplacement(
//                                                       context,
//                                                       MaterialPageRoute(
//                                                           builder: (context) =>
//                                                               UserProfileScreen(
//                                                                   userId:
//                                                                       user.id)));
//                                                 },
//                                                 child: Container(
//                                                   padding:
//                                                       const EdgeInsets.all(12),
//                                                   margin: const EdgeInsets.only(
//                                                       bottom: 8),
//                                                   decoration: BoxDecoration(
//                                                     color: Colors.grey.shade900,
//                                                     borderRadius:
//                                                         BorderRadius.circular(15),
//                                                     border: Border.all(
//                                                       color: const Color(0xFF7400A5)
//                                                           .withOpacity(0.5),
//                                                       width: 1,
//                                                     ),
//                                                   ),
//                                                   child: Row(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start, // Align items to the top
//                                                     mainAxisSize:
//                                                         MainAxisSize.min,
//                                                     children: [
//                                                       // Avatar
//                                                       CircleAvatar(
//                                                         backgroundColor: const Color(0xFF7400A5)
//                                                             .withOpacity(0.3),
//                                                         radius: 20,
//                                                         child: Text(
//                                                           user.name.isNotEmpty
//                                                               ? user.name[0]
//                                                                   .toUpperCase()
//                                                               : '?',
//                                                           style:
//                                                               GoogleFonts.poppins(
//                                                             color: Colors.white,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       const SizedBox(width: 10),
//                                                       Flexible(
//                                                         // Add Flexible to allow text to wrap properly
//                                                         child: Column(
//                                                           crossAxisAlignment:
//                                                               CrossAxisAlignment
//                                                                   .start,
//                                                           children: [
//                                                             Text(
//                                                               user.name,
//                                                               style: GoogleFonts
//                                                                   .poppins(
//                                                                 color:
//                                                                     Colors.white,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                               ),
//                                                               overflow:
//                                                                   TextOverflow
//                                                                       .ellipsis,
//                                                             ),
//                                                             const SizedBox(
//                                                                 height:
//                                                                     4), // Increased spacing
//                                                             Text(
//                                                               'Interests: ${user.interests.join(", ")}',
//                                                               style: GoogleFonts
//                                                                   .poppins(
//                                                                 color: Colors.grey
//                                                                     .shade400,
//                                                                 fontSize: 12,
//                                                               ),
//                                                               maxLines: 2,
//                                                               overflow:
//                                                                   TextOverflow
//                                                                       .ellipsis,
//                                                             ),
//                                                             const SizedBox(
//                                                                 height:
//                                                                     4), // Increased spacing
//                                                             Text(
//                                                               'Matching: ${user.matchingInterestsCount} interest${user.matchingInterestsCount != 1 ? "s" : ""}',
//                                                               style: GoogleFonts
//                                                                   .poppins(
//                                                                 color: const Color(0xFF7400A5),
//                                                                 fontSize: 12,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w500,
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 )))
//                                             .toList(),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             } else {
//                               return Align(
//                                 alignment: isMe
//                                     ? Alignment.centerRight
//                                     : Alignment.centerLeft,
//                                 child: Container(
//                                   margin: const EdgeInsets.symmetric(
//                                       vertical: 5, horizontal: 10),
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: isMe
//                                         ? const Color(0xFF7400A5)
//                                         : Colors.grey.shade800,
//                                     borderRadius: BorderRadius.circular(15),
//                                   ),
//                                   child: Text(
//                                     message.content,
//                                     style:
//                                         GoogleFonts.poppins(color: Colors.white),
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                           noItemsFoundIndicatorBuilder: (context) {
//                             return Align(
//                               alignment: Alignment.bottomLeft,
//                               child: Padding(
//                                 padding: EdgeInsets.only(
//                                     bottom:
//                                         MediaQuery.of(context).size.height * 0.12,
//                                     left: 20),
//                                 child: RichText(
//                                     textAlign: TextAlign.start,
//                                     text: TextSpan(
//                                         style: TextStyle(height: 1.4),
//                                         children: [
//                                           TextSpan(
//                                               text: 'Hey,\n',
//                                               style: GoogleFonts.leagueSpartan(
//                                                   fontSize: 40.sp,
//                                                   fontWeight: FontWeight.w900)),
//                                           TextSpan(
//                                               text: "I'm  ",
//                                               style: GoogleFonts.leagueSpartan(
//                                                   fontSize: 40.sp,
//                                                   fontWeight: FontWeight.w900)),
//                                           TextSpan(
//                                             text: "BondChat\n",
//                                             style: GoogleFonts.leagueSpartan(
//                                               fontSize:
//                                                   45, // or use 45.sp if you're using ScreenUtil
//                                               fontWeight: FontWeight.w900,
//                                               foreground: Paint()
//                                                 ..shader = const LinearGradient(
//                                                   colors: [
//                                                     // #E25FB2
//                                                     Color(0xFF7E6DF1),
//                                                     Color(0xFF7E6DF1), // #7E6DF1
//                                                     Color(0xFFE25FB2),
//                                                   ],
//                                                 ).createShader(
//                                                   // Adjust these coordinates as needed for the best gradient placement
//                                                   const Rect.fromLTWH(
//                                                       0.0, 0.0, 300.0, 70.0),
//                                                 )
//                                                 ..style = PaintingStyle
//                                                     .stroke // Outline style
//                                                 ..strokeWidth =
//                                                     2, // Outline thickness
//                                             ),
//                                           ),
//                                           TextSpan(
//                                               text:
//                                                   'Your Favoruite Buddy at work',
//                                               style: GoogleFonts.leagueSpartan(
//                                                   fontSize: 30.sp,
//                                                   fontWeight: FontWeight.w300,
//                                                   color: Colors.grey.shade500)),
//                                         ])),
//                               ),
//                             );
//                           },
//                           firstPageErrorIndicatorBuilder: (context) => Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text('Error loading messages',
//                                     style: TextStyle(color: Colors.white)),
//                                 ElevatedButton(
//                                   onPressed: () => _pagingController.refresh(),
//                                   child: Text('Retry'),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade900,
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                             child: TextField(
//                               controller: _messageController,
//                               style: const TextStyle(color: Colors.white),
//                               decoration: const InputDecoration(
//                                 hintText: 'Type your message...',
//                                 hintStyle: TextStyle(color: Colors.grey),
//                                 border: InputBorder.none,
//                                 contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 20, vertical: 15),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         IconButton(
//                           icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
//                               color: const Color(0xFF7400A5)),
//                           onPressed: () {
//                             _isListening ? _stopListening() : _startListening();
//                           },
//                         ),
//                         Container(
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Color(0xFF7400A5),
//                           ),
//                           child: IconButton(
//                             icon: const Icon(Icons.send, color: Colors.white),
//                             onPressed: _sendMessage,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _pagingController.dispose();
//     _audioPlayer.dispose(); // Properly dispose of the audio player
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/shimmerchatscreen.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';

import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/services/voice_settings.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class UserRecommendation {
  final String id;
  final String name;
  final String nickName;
  final List<String> interests;
  final int matchingInterestsCount;
  final bool hasMessageInterest;

  UserRecommendation({
    required this.id,
    required this.name,
    required this.nickName,
    required this.interests,
    required this.matchingInterestsCount,
    required this.hasMessageInterest,
  });

  factory UserRecommendation.fromJson(Map<String, dynamic> json) {
    return UserRecommendation(
      id: json['_id'],
      name: json['name'],
      nickName: json['nickName'],
      interests: List<String>.from(json['interests'] ?? []),
      matchingInterestsCount: json['matchingInterestsCount'] ?? 0,
      hasMessageInterest: json['hasMessageInterest'] ?? false,
    );
  }
}

class ChatMessage {
  final String id;
  final dynamic content;
  final String senderId;
  final DateTime createdAt;
  final String? media;
  final String entity;
  final bool isBot;
  final List<UserRecommendation>? userRecommendations;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
    this.media,
    required this.entity,
    this.isBot = false,
    this.userRecommendations,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    dynamic messageContent = json['content'];
    List<UserRecommendation>? users;

    // Check if content is a map with 'users' array
    if (messageContent is Map<String, dynamic> &&
        messageContent.containsKey('users') &&
        messageContent['users'] is List) {
      users = (messageContent['users'] as List)
          .map((user) => UserRecommendation.fromJson(user))
          .toList();

      // Extract just the text message part
      messageContent = messageContent['message'] ?? '';
    }

    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? DateTime.now().toString(),
      content: messageContent,
      senderId: json['senderId'],
      createdAt: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000)
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      media: json['media'],
      entity: json['entity'] ?? '',
      isBot: json['isBot'] ?? false,
      userRecommendations: users,
    );
  }
}

class BondChatScreen extends StatefulWidget {
  const BondChatScreen({Key? key}) : super(key: key);

  @override
  _BondChatScreenState createState() => _BondChatScreenState();
}

class _BondChatScreenState extends State<BondChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SocketService _socketService = SocketService();
  final _pagingController = PagingController<int, ChatMessage>(firstPageKey: 1);
  static const _pageSize = 20;

  String? _currentUserId;
  String? _chatRoomId;
  String? _token;
  bool _isLoading = true;
  bool _isSpeakerOn = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedVoice = 'male';
  String _botName = 'Michael';

  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
    _initializeChat();
  }

  Future<void> _loadVoiceSettings() async {
    final voice = await VoiceSettings.getSelectedVoice();
    setState(() {
      _selectedVoice = voice;
      _botName = VoiceSettings.getVoiceName(voice);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      print('Fetching page $pageKey for room $_chatRoomId');

      if (_chatRoomId == null) {
        print('Chat room ID is null');
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/get-all-messages'),
        headers: {
          'userid': _currentUserId!,
          'token': _token!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'roomId': _chatRoomId,
          'page': pageKey.toString(),
          'limit': _pageSize.toString(),
        }),
      );

      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> messagesList = responseData['messages'];
        final messages =
            messagesList.map((msg) => ChatMessage.fromJson(msg)).toList();

        final isLastPage =
            responseData['currentPage'] >= responseData['totalPages'];

        if (isLastPage) {
          _pagingController.appendLastPage(messages);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(messages, nextPageKey);
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching messages: $error');
      _pagingController.error = error;
    }
  }

  Future<void> _initializeChat() async {
    try {
      print('Initializing chat...');
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('user_token');
      _currentUserId = prefs.getString('user_id');

      print('Token: $_token');
      print('User ID: $_currentUserId');

      if (_token == null || _currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Center(child: Text('Authentication required'))),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/start-message'),
        headers: {
          'userid': _currentUserId!,
          'token': _token!,
          'Content-Type': 'application/json',
        },
        // body: jsonEncode({'userId2': '67d3bf8914c75ee094e30bfa'}),
        body: jsonEncode({'userId2': '67f4ecba7f663162b8466076'}),
      );

      print('Start message response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _chatRoomId = responseData['chatRoom']['chatRoomId'];
        });

        // Initialize paging controller after getting chat room ID
        _pagingController.addPageRequestListener((pageKey) {
          _fetchPage(pageKey);
        });

        await _socketService.connect();
        _socketService.joinRoom(_chatRoomId!);

        // Trigger initial load
        _fetchPage(1);

        _socketService.onMessageReceived = (message) {
          final newMessage = ChatMessage.fromJson(message);

          print(newMessage);

          if (_pagingController.itemList == null) {
            _pagingController.itemList = [];
          }
          _pagingController.itemList!.insert(0, newMessage);
          setState(() {});
          if (_isSpeakerOn &&
              message['isBot'] == true &&
              message['media'] != null) {
            print("🎵 Polly audio detected, playing...");
            Future.microtask(() async {
              await _playPollyAudio(message['media']);
            });
          }
        };
      } else {
        print('Failed to start chat: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Center(child: Text('Failed to start chat'))),
        );
      }
    } catch (e) {
      print('Error initializing chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text('An error occurred'))),
      );
    }
  }

  Future<void> _playPollyAudio(String base64Audio) async {
    try {
      print("🎵 Starting audio playback process...");

      // Decode base64 to binary data
      Uint8List audioBytes = base64Decode(base64Audio);
      print(
          "🎵 Base64 decoded successfully, audio size: ${audioBytes.length} bytes");

      // Get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String filePath =
          '${tempDir.path}/polly_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

      // Save audio file
      File audioFile = File(filePath);
      await audioFile.writeAsBytes(audioBytes);
      print("🎵 Audio file saved to: $filePath");

      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Set the audio source and play
      await _audioPlayer.setFilePath(filePath);
      print("🎵 Audio source set successfully");

      // Add error listener
      _audioPlayer.playbackEventStream.listen(
        (event) {
          print("🎵 Playback event: $event");
        },
        onError: (Object e, StackTrace st) {
          print("⚠ Audio playback error: $e");
        },
      );

      // Play the audio
      await _audioPlayer.play();
      print("🎵 Audio playback started");

      // Clean up the file after playback
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          print("🎵 Audio playback completed, cleaning up file");
          audioFile.delete().catchError((error) {
            print("⚠ Error deleting audio file: $error");
          });
        }
      });
    } catch (e) {
      print("⚠ Error in _playPollyAudio: $e");
    }
  }

  void _toggleVoice(String newVoice) async {
    await VoiceSettings.setSelectedVoice(newVoice);
    setState(() {
      _selectedVoice = newVoice;
      _botName = newVoice == 'male' ? 'Michael' : 'Vanessa';
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _chatRoomId != null) {
      final newMessage = ChatMessage(
        id: DateTime.now().toString(),
        content: message,
        senderId: _currentUserId!,
        createdAt: DateTime.now(),
        entity: '',
      );

      if (_pagingController.itemList == null) {
        _pagingController.itemList = [];
      }
      _pagingController.itemList!.insert(0, newMessage);
      setState(() {});

      _socketService.sendMessage(
        _currentUserId!,
        _chatRoomId!,
        message,
        '',
        true,
        _isSpeakerOn,
        voice: _selectedVoice,
      );

      if (_isListening) {
        _speech.stop();
        setState(() => _isListening = false);
      }

      _messageController.clear();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("🎤 Speech Status: $status");
      },
      onError: (errorNotification) {
        print("Speech Error: $errorNotification");
      },
    );

    if (available) {
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          if (!_isListening) return;

          setState(() {
            _messageController.text = result.recognizedWords;
          });

          // Send message **only when speech recognition is complete**
          if (result.finalResult) {
            _sendMessage();
            _messageController.clear();
            setState(() => _isListening = false);
          }
        },
      );
    } else {
      print("Speech Recognition is not available.");
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> BottomNavBarScreen()));
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            )),
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Text(_botName, style: GoogleFonts.poppins(color: Colors.white)),
            SizedBox(
              width: 10.w,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF7400A5),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  'Basic',
                  style:
                      GoogleFonts.poppins(fontSize: 10.sp, color: Colors.white),
                ),
              ),
            )
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _selectedVoice == 'male' ? Icons.man : Icons.woman,
              color: const Color(0xFF7400A5),
            ),
            onSelected: (String newVoice) {
              setState(() {
                _selectedVoice = newVoice;
              });
              _toggleVoice(newVoice);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'male',
                child: Row(
                  children: [
                    Icon(Icons.man, color: const Color(0xFF7400A5)),
                    SizedBox(width: 8),
                    Text('Michael'),
                    Spacer(),
                    if (_selectedVoice == 'male')
                      Icon(Icons.check_circle, color: Colors.grey),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'female',
                child: Row(
                  children: [
                    Icon(Icons.woman, color: const Color(0xFF7400A5)),
                    SizedBox(width: 8),
                    Text('Vanessa'),
                    Spacer(),
                    if (_selectedVoice == 'female')
                      Icon(Icons.check_circle, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
                _isSpeakerOn ? Icons.volume_up_outlined : Icons.volume_off,
                color: const Color(0xFF7400A5)),
            onPressed: () {
              setState(() {
                _isSpeakerOn = !_isSpeakerOn;
              });
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CompleteChatShimmer())
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _pagingController.refresh();
                      },
                      child: PagedListView<int, ChatMessage>(
                        pagingController: _pagingController,
                        reverse: true,
                        builderDelegate: PagedChildBuilderDelegate<ChatMessage>(
                          itemBuilder: (context, message, index) {
                            final isMe = message.senderId == _currentUserId;
                            final isBot = message.isBot;

                            if (message.userRecommendations != null &&
                                message.userRecommendations!.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  // Message bubble with text
                                  Align(
                                    alignment: isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFF7400A5)
                                            : Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        message.content.toString(),
                                        style: GoogleFonts.poppins(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),

                                  // User recommendations section
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // User tiles
                                        ...message.userRecommendations!
                                            .map((user) => GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              UserProfileScreen(
                                                                  userId: user
                                                                      .id)));
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  margin: const EdgeInsets.only(
                                                      bottom: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade900,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    border: Border.all(
                                                      color: const Color(
                                                              0xFF7400A5)
                                                          .withOpacity(0.5),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start, // Align items to the top
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // Avatar
                                                      CircleAvatar(
                                                        backgroundColor:
                                                            const Color(
                                                                    0xFF7400A5)
                                                                .withOpacity(
                                                                    0.3),
                                                        radius: 20,
                                                        child: Text(
                                                          user.name.isNotEmpty
                                                              ? user.name[0]
                                                                  .toUpperCase()
                                                              : '?',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Flexible(
                                                        // Add Flexible to allow text to wrap properly
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              user.name,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                                height:
                                                                    4), // Increased spacing
                                                            Text(
                                                              'Interests: ${user.interests.join(", ")}',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
                                                                fontSize: 12,
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                                height:
                                                                    4), // Increased spacing
                                                            Text(
                                                              'Matching: ${user.matchingInterestsCount} interest${user.matchingInterestsCount != 1 ? "s" : ""}',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color: const Color(
                                                                    0xFF7400A5),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )))
                                            .toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFF7400A5)
                                        : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    message.content,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          },
                          noItemsFoundIndicatorBuilder: (context) {
                            return Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).size.height *
                                        0.12,
                                    left: 20),
                                child: RichText(
                                    textAlign: TextAlign.start,
                                    text: TextSpan(
                                        style: TextStyle(height: 1.4),
                                        children: [
                                          TextSpan(
                                              text: 'Welcome,\n',
                                              style: GoogleFonts.leagueSpartan(
                                                  fontSize: 40.sp,
                                                  fontWeight: FontWeight.w900)),
                                          TextSpan(
                                              text: "To  ",
                                              style: GoogleFonts.leagueSpartan(
                                                  fontSize: 40.sp,
                                                  fontWeight: FontWeight.w900)),
                                          TextSpan(
                                            text: "BondChat\n",
                                            style: GoogleFonts.leagueSpartan(
                                              fontSize:
                                                  45, // or use 45.sp if you're using ScreenUtil

                                              fontWeight: FontWeight.w900,
                                              foreground: Paint()
                                                ..shader = const LinearGradient(
                                                  colors: [
                                                    // #E25FB2
                                                    Color(0xFF7E6DF1),
                                                    Color(
                                                        0xFF7E6DF1), // #7E6DF1
                                                    Color(0xFFE25FB2),
                                                  ],
                                                ).createShader(
                                                  // Adjust these coordinates as needed for the best gradient placement
                                                  const Rect.fromLTWH(
                                                      0.0, 0.0, 300.0, 70.0),
                                                )
                                                ..style = PaintingStyle
                                                    .stroke // Outline style
                                                ..strokeWidth =
                                                    2, // Outline thickness
                                            ),
                                          ),
                                          TextSpan(
                                              text: 'Choose Your Persona',
                                              style: GoogleFonts.leagueSpartan(
                                                  fontSize: 25.sp,
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.grey.shade500)),
                                        ])),
                              ),
                            );
                          },
                          firstPageErrorIndicatorBuilder: (context) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error loading messages',
                                    style: TextStyle(color: Colors.white)),
                                ElevatedButton(
                                  onPressed: () => _pagingController.refresh(),
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                              color: const Color(0xFF7400A5)),
                          onPressed: () {
                            _isListening ? _stopListening() : _startListening();
                          },
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF7400A5),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
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

  @override
  void dispose() {
    _messageController.dispose();
    _pagingController.dispose();
    _audioPlayer.dispose(); // Properly dispose of the audio player
    super.dispose();
  }
}
