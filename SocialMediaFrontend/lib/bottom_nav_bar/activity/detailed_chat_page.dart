import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/see_participants.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group/shimmerchatscreen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group_call.dart';
import 'package:socialmedia/bottom_nav_bar/activity/group_call_bottom_sheet.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/services/agora_Call_Service.dart';
import 'package:socialmedia/services/agora_video_Call.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/services/message.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  DChatScreen({required this.chatRoom});

  @override
  _DChatScreenState createState() => _DChatScreenState();
}

class _DChatScreenState extends State<DChatScreen> {
  final TextEditingController _controller = TextEditingController();
  static const _pageSize = 20;
  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 1);
  String? userid;
  late IO.Socket _socket;
  final SocketService _socketService = SocketService();
  Map<String, Participant> participantsMap = {};
  bool isnewconversation = true;
  late UserProviderall userProvider;
  late Future<List<String>> _randomTextFuture;
  bool isNewConversation = true;
  bool _isMessagesLoaded = false;

  @override
  void initState() {
    super.initState();

    // Initialize userProvider first
    userProvider = Provider.of<UserProviderall>(context, listen: false);

    // Initialize these before any other operations
    _initializeBasicData();
    //_initializeChat();
  }

  Future<void> _initializeBasicData() async {
    try {
      // Load user data first
      await userProvider.loadUserData();

      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userid = prefs.getString('user_id');

      if (userid == null) {
        print('Error: User ID is null');
        return;
      }

      // Initialize socket connection
      await _ensureSocketConnection();

      // Initialize chat after socket connection
      await _initializeChat();

      // Initialize participants map only after we have userid
      if (mounted) {
        initParticipantsMap(widget.chatRoom.participants);
      }

      // Initialize paging controller
      _pagingController.addPageRequestListener((pageKey) {
        _fetchPage(pageKey);
      });

      if (mounted) {
        setState(() {
          _randomTextFuture = fetchRandomText();
        });
      }

      // Fetch first page
      await _fetchPage(1);
    } catch (e) {
      print('Initialization error: $e');
      // Handle error appropriately
    }
  }

  void initParticipantsMap(List<Participant> participants) {
    if (userid == null) {
      print('Error: Cannot initialize participants map without user ID');
      return;
    }

    participantsMap.clear();
    for (var participant in participants) {
      if (participant.userId != userid) {
        participantsMap[participant.userId] = participant;
      }
    }
  }

  Future<void> _ensureSocketConnection() async {
    try {
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }
    } catch (e) {
      print('Socket connection error: $e');
    }
  }

  Future<void> _initializeChat() async {
    try {
      await _socketService.connect();
      print('✅ Socket connected: ${_socketService.isConnected}');

      // Remove any existing receiveMessage listener to avoid duplicates
      // _socketService.socket.off('receiveMessage');

      // Set up the receiveMessage listener with enhanced debugging
      _socketService.socket.on('receiveMessage', (data) {
        print('✅✅✅ Received message via socket: $data');
        try {
          Map<String, dynamic> messageMap;
          if (data is String) {
            messageMap = jsonDecode(data) as Map<String, dynamic>;
          } else if (data is Map) {
            messageMap = Map<String, dynamic>.from(data);
          } else {
            throw Exception('Unexpected data type: ${data.runtimeType}');
          }

          print('Parsed message keys: ${messageMap.keys.toList()}');
          final newMessage = Message.fromJson(messageMap);
          final userProvider =
              Provider.of<UserProviderall>(context, listen: false);
          final currentUserId = userProvider.userId;
          // Only insert into the UI if the message is not from the current user.
          if (newMessage.senderId != currentUserId) {
            if (_pagingController.itemList == null) {
              _pagingController.itemList = [];
            }
            _pagingController.itemList!.insert(0, newMessage);
            _pagingController.notifyListeners();
            print('✅ New message added to list: $newMessage');
          } else {
            print('Message not added since it is from the current user.');
          }
        } catch (e) {
          print('🚨 Error processing socket message: $e');
        }
      });

      // Debug log to confirm room joining
      print('✅ Joining room: ${widget.chatRoom.chatRoomId}');
      _socketService.joinRoom(widget.chatRoom.chatRoomId);
    } catch (e, stackTrace) {
      print('❌ Chat initialization error: $e');
      print('📜 Stack trace: $stackTrace');
    }
  }

  Future<List<String>> fetchRandomText() async {
    //print(widget.chatRoom.participants.first.)
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    String url =
        '${BASE_URL}api/getRandomText?other=${widget.chatRoom.participants.first.userId}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'userid': userProvider.userId!,
        'token': userProvider.userToken!,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String topicText = data['topic'] ?? '';

      // Splitting the text into individual messages
      List<String> messages = topicText.split('\n').map((msg) {
        // Remove leading numbers (e.g., "1. ") and quotation marks
        return msg
            .replaceAll(RegExp(r'^\d+\.\s*'), '')
            .replaceAll('"', '')
            .trim();
      }).toList();

      return messages;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> markMessageAsSeen(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/messages/interact'),
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({"entityId": id, "reactionType": "seen"}),
      );

      if (response.statusCode == 200) {
        print('Message marked as seen');
      } else {
        print('Failed to mark message as seen: ${response.body}');
      }
    } catch (error) {
      print('Error marking message as seen: $error');
    }
  }

  Future<void> initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId =
        prefs.getString('user_id'); // Fetch user ID from SharedPreferences
    print('yelelelelelelellee $userId');

    if (userId == null) {
      debugPrint("User ID not found in SharedPreferences");
      return; // Exit if userId is null
    }

    _socket = IO.io(BASE_URL, <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    _socket.connect();
    print('hogyaaaa');
    _socket.emit('openCall', userId);

    _socket.onConnect((_) {
      debugPrint("Connected to socket server");
    });
  }

  Future<void> fetchUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getString('user_id');
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    print('aaliaaaaa');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        return;
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/get-all-messages'),
        headers: {
          'userid': userId,
          'token': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "roomId": widget.chatRoom.chatRoomId,
          "page": pageKey.toString(),
          "limit": _pageSize.toString(),
        }),
      );

      if (response.statusCode == 200) {
        print('yelelelelele $isnewconversation');

        final data = json.decode(response.body);
        final List<Message> fetchedMessages = (data['messages'] as List)
            .map((msg) => Message.fromJson(msg))
            .toList();
        if (fetchedMessages.length > 0) {
          isnewconversation = false;
          isNewConversation = false;
          print('lelelelel');
          print(data['messages'][0]['_id']);
          markMessageAsSeen(data['messages'][0]['_id']);
        }
        setState(() {
          isnewconversation;
        });
        print('yelele dobara$isnewconversation');
        print('yelelelele ${fetchedMessages.length}');
        if (pageKey == 1) {
          setState(() {
            _isMessagesLoaded = true;
          });
        }

        final isLastPage = fetchedMessages.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(fetchedMessages);
        } else {
          _pagingController.appendPage(fetchedMessages, pageKey + 1);
        }
      } else {
        _pagingController.error = 'Failed to load messages';
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<void> _sendMessage() async {
    final message = _controller.text;
    if (message.isEmpty || userid == null) return;

    try {
      // Create a temporary message object
      final newMessage = Message(
        id: DateTime.now().toString(), // Temporary ID
        content: message,
        senderId: userid!,
        timestamp: DateTime.now(),
        // Add other required fields with default values
      );

      // Add message to the list immediately
      setState(() {
        if (_pagingController.itemList == null) {
          _pagingController.itemList = [];
        }
        _pagingController.itemList!.insert(0, newMessage);
      });

      // Clear the input field
      _controller.clear();

      // Send the message through socket
      _socketService.sendMessage(
        userid!,
        widget.chatRoom.chatRoomId,
        message,
        '',
        false,
        false,
      );

      setState(() {
        isNewConversation = false;
      });
    } catch (e) {
      print('Error sending message: $e');
      // Optionally remove the message if sending failed
      if (_pagingController.itemList != null) {
        setState(() {
          _pagingController.itemList!.removeAt(0);
        });
      }
    }
  }

  Future<void> _joinCall(String callId, String type, bool fromgroup) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('callToken');
    final channelName = prefs.getString('channelName');
    bool isvideo = type == 'video' ? true : false;

    if (token == null || channelName == null) return;

    _socketService.joinCall(callId, userid!);

    if (fromgroup) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VideoCallScreen(
                    roomId: widget.chatRoom.chatRoomId,
                    participantsMap: participantsMap,
                    currentUserId: userid!,
                    isVideoCall: isvideo,
                    token: token,
                    channel: channelName,
                    callID: callId,
                  )));
      return;
    }

    if (type == 'audio') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgoraCallService(
            channel: channelName,
            token: token,
            callID: callId,
            profile: widget.chatRoom.participants.first.profilePic == null
                ? 'assets/avatar/3.png'
                : widget.chatRoom.participants.first.profilePic!,
            name: widget.chatRoom.participants.first.name!,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgoraVidCall(
              channel: channelName,
              token: token,
              callerName: 'video call',
              call_id: callId,
              profile: widget.chatRoom.participants.first.profilePic == null
                  ? 'assets/avatar/3.png'
                  : widget.chatRoom.participants.first.profilePic!,
              name: widget.chatRoom.participants.first.name!),
        ),
      );
    }
  }

  Future<void> startCall(String toUserId, String type, bool fromgrp) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('user_token');

    if (userId == null || token == null) return;

    final response = await http.post(
      Uri.parse('${BASE_URL}api/start-call'),
      headers: {
        'userid': userId,
        'token': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "to": widget.chatRoom.chatRoomId,
        "type": type,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await prefs.setString('channelName', data['call']['channelName']);
      await prefs.setString('callToken', data['token']);
      print('Call started: ${data['message']}');

      _socketService.initiateCall(data['call']['_id'], userId, [toUserId], type);
      _joinCall(data['call']['_id'], type, fromgrp);

      // if (type == 'audio') {
      //   Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => AgoraCallService(
      //                 channel: data['call']['channelName'],
      //                 token: data['token'],
      //                 callID: data['call']['_id'],
      //               )));
      // } else {
      //   Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => AgoraVidCall(
      //                 channel: data['call']['channelName'],
      //                 token: data['token'],
      //                 callerName: 'video call',
      //                 call_id: data['call']['_id'],
      //               )));
      // }
    } else {
      print('Failed to start call');
    }
  }

  void showAddFriendsSheet(BuildContext context,
      Map<String, Participant> participantsMap, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: AddFriendsBottomSheet(
          participantsMap: participantsMap,
          onInvite: (userId) async {
            await startCall(widget.chatRoom.chatRoomId, type, true);
            // Handle invite logic here

            print('Inviting user: $userId');
            // You might want to add API call to invite user
          },
        ),
      ),
    );
  }

  void _copyAndPasteText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _controller.text = text; // Automatically set text in the input field
  }

  String truncateName(String name, {int maxLength = 10}) {
    return name.length > maxLength
        ? '${name.substring(0, maxLength)}...'
        : name;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMessagesLoaded || userid == null) {
      return CompleteChatShimmer();
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.lightText
              : AppColors.darkText,
          title: FittedBox(
            child: GestureDetector(
              onTap: () {
                if (widget.chatRoom.roomType == 'group') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Particiapntgrp(
                              chatRoomId: widget.chatRoom.chatRoomId)));
                }
              },
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(
                            builder: (context) => BottomNavBarScreen()));
                      },
                      icon: Icon(Icons.arrow_back_ios)),
                  InkWell(
                    onTap: () {
                      print(widget.chatRoom.participants.first.name);
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (widget.chatRoom.roomType == 'group') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Particiapntgrp(
                                      chatRoomId: widget.chatRoom.chatRoomId)));
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: widget.chatRoom.roomType == 'dm'
                            ? widget.chatRoom.participants.first.profilePic ==
                                    null
                                ? const AssetImage('assets/avatar/3.png')
                                    as ImageProvider
                                : NetworkImage(widget
                                    .chatRoom.participants.first.profilePic!)
                            : widget.chatRoom.groupProfile == null
                                ? const AssetImage('assets/avatar/3.png')
                                    as ImageProvider
                                : NetworkImage(widget.chatRoom.groupProfile!),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  if (widget.chatRoom.roomType == 'dm')
                    Text(
                      truncateName(widget.chatRoom.participants.first.name!),
                      style: GoogleFonts.roboto(),
                    ),
                  if (widget.chatRoom.roomType == 'group')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truncateName(widget.chatRoom.groupName!),
                          style: TextStyle(fontSize: 28.sp, color: Colors.white),
                        ),
                        Text(
                          'Group',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color.fromARGB(255, 185, 184, 184)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkText
                : AppColors.lightText,
          ),
          actions: [
            IconButton(
                onPressed: () {
                  widget.chatRoom.roomType == 'group'
                      ? showAddFriendsSheet(context, participantsMap, 'audio')
                      : startCall(widget.chatRoom.participants.first.userId,
                          "audio", false);
                },
                icon: Icon(Icons.call, color: Color(0xFF7400A5))),
            SizedBox(
              width: 8.w,
            ),
            IconButton(
                onPressed: () {
                  widget.chatRoom.roomType == 'group'
                      ? showAddFriendsSheet(context, participantsMap, 'video')
                      : startCall(widget.chatRoom.participants.first.userId,
                          "video", false);
                },
                icon: Icon(Icons.video_call, color: Color(0xFF7400A5))),
            SizedBox(
              width: 8.w,
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PagedListView<int, Message>(
                  pagingController: _pagingController,
                  reverse: true,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                      itemBuilder: (context, message, index) {
                    final isSender = message.senderId == userid;
                    return InkWell(
                      onTap: () {
                        print(
                            'Participants: ${widget.chatRoom.participants.map((p) => p.name).toList()}');
                      },
                      child: MessageBubble(
                        message: message,
                        isSender: isSender,
                        participantsMap: participantsMap,
                        currentUserId: userid!,
                      ),
                    );
      
                    // Align(
                    //   alignment:
                    //       isSender ? Alignment.centerRight : Alignment.centerLeft,
                    //   child: Container(
                    //     margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    //     padding:
                    //         EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    //     decoration: BoxDecoration(
                    //       color: isSender
                    //           ? Colors.purple.shade200
                    //           : Colors.grey[800],
                    //       borderRadius: BorderRadius.circular(20),
                    //     ),
                    //     child: Text(
                    //       message.content,
                    //       style: TextStyle(color: Colors.white, fontSize: 16),
                    //     ),
                    //   ),
                    // );
                  }, noItemsFoundIndicatorBuilder: (context) {
                    return Center(
                      child: Text(
                        'No Messages Yet. Start The Conversation',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isNewConversation
                        ? FutureBuilder<List<String>>(
                            future:
                                _randomTextFuture, // your cached future from initState
                            builder: (context, snapshot) {
                              // If it's not a new conversation, don't show anything.
                              if (!isNewConversation)
                                return const SizedBox.shrink();
      
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                // Shimmer effect with the same height as the suggestion list.
                                return SizedBox(
                                  height: 80,
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.purple[300]!,
                                    highlightColor: Colors.purple[100]!,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 3, // Show 3 placeholder items
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Container(
                                            width: 250,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors
                                                  .white, // base color for shimmer child
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return SizedBox(
                                  height: 80,
                                  child: Center(
                                      child: Text('Error: ${snapshot.error}')),
                                );
                              } else {
                                // Use an empty list if data is null.
                                final List<String> suggestions =
                                    snapshot.data ?? [];
                                if (suggestions.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header once above the list.
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 4.0),
                                        child: Text(
                                          'BondChat Suggestions',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.darkText
                                                : AppColors.lightText,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 90, // Fixed height for the list
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: suggestions.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8.0),
                                              child: GestureDetector(
                                                onTap: () => _copyAndPasteText(
                                                    suggestions[index]),
                                                child: Container(
                                                  width: 250,
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF7400A5),
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      const Icon(Icons.message,
                                                          color: Colors.white),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          suggestions[index],
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          )
                        : const SizedBox.shrink(),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[900]
                                    : Colors.grey[500],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: _controller,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type A Message...',
                                    hintStyle: GoogleFonts.poppins(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white60
                                            : AppColors.lightText),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF7400A5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers and other resources
    _pagingController.dispose();
    _controller.dispose();

    // Clear the message handler to avoid memory leaks
    //  _socketService.onMessageReceived = null;

    // Emit the "leave" event when leaving the page
    if (_socketService.isConnected) {
      _socketService.socket.emit('leave', widget.chatRoom.chatRoomId);
      print('✅ Emitted leave event for room: ${widget.chatRoom.chatRoomId}');
    }

    super.dispose();
  }
}
