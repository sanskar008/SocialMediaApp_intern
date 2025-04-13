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
import 'package:socialmedia/services/reaction_picker.dart'; // Add this import
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const DChatScreen({required this.chatRoom, super.key});

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
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    _initializeBasicData();
  }

  Future<void> _initializeBasicData() async {
    try {
      await userProvider.loadUserData();
      final prefs = await SharedPreferences.getInstance();
      userid = prefs.getString('user_id');

      if (userid == null) {
        print('Error: User ID is null');
        return;
      }

      await _ensureSocketConnection();
      await _initializeChat();

      if (mounted) {
        initParticipantsMap(widget.chatRoom.participants);
      }

      _pagingController.addPageRequestListener((pageKey) {
        _fetchPage(pageKey);
      });

      if (mounted) {
        setState(() {
          _randomTextFuture = fetchRandomText();
        });
      }

      await _fetchPage(1);
    } catch (e) {
      print('Initialization error: $e');
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

      _socketService.onMessageReceived = (data) {
        print('✅✅✅ Received message via socket: $data');
        try {
          Map<String, dynamic> messageMap;
          if (data is String) {
            messageMap = jsonDecode(data) as Map<String, dynamic>;
          } else {
            messageMap = Map<String, dynamic>.from(data);
          }

          print('Parsed message keys: ${messageMap.keys.toList()}');
          final newMessage = Message.fromJson(messageMap);
          if (newMessage.senderId != userid) {
            if (_pagingController.itemList == null) {
              _pagingController.itemList = [];
            }
            _pagingController.itemList!.insert(0, newMessage);
            _pagingController.notifyListeners();
            print('✅ New message added to list: $newMessage');
          }
        } catch (e) {
          print('🚨 Error processing socket message: $e');
        }
      };

      // Add reaction listeners
      _socketService.onMessageReaction = (data) {
        print('✅ Received reaction: $data');
        setState(() {
          final messageId = data['messageId'];
          final reaction = data['reaction'];
          final userId = data['userId'];

          final messages = _pagingController.itemList ?? [];
          final messageIndex = messages.indexWhere((m) => m.id == messageId);
          if (messageIndex != -1) {
            final message = messages[messageIndex];
            message.reactions ??= [];
            message.reactions!.add(Reaction(emoji: reaction, userId: userId));
            _pagingController.notifyListeners();
          }
        });
      };

      _socketService.onReactionRemoved = (data) {
        print('✅ Reaction removed: $data');
        setState(() {
          final messageId = data['messageId'];
          final userId = data['userId'];

          final messages = _pagingController.itemList ?? [];
          final messageIndex = messages.indexWhere((m) => m.id == messageId);
          if (messageIndex != -1) {
            final message = messages[messageIndex];
            if (message.reactions != null) {
              message.reactions!.removeWhere((r) => r.userId == userId);
              _pagingController.notifyListeners();
            }
          }
        });
      };

      print('✅ Joining room: ${widget.chatRoom.chatRoomId}');
      _socketService.joinRoom(widget.chatRoom.chatRoomId);
    } catch (e, stackTrace) {
      print('❌ Chat initialization error: $e');
      print('📜 Stack trace: $stackTrace');
    }
  }

  Future<List<String>> fetchRandomText() async {
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
      List<String> messages = topicText.split('\n').map((msg) {
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

      if (userId == null || token == null) return;

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
    String? userId = prefs.getString('user_id');
    print('yelelelelelelellee $userId');

    if (userId == null) {
      debugPrint("User ID not found in SharedPreferences");
      return;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) return;

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
        final data = json.decode(response.body);
        final List<Message> fetchedMessages = (data['messages'] as List)
            .map((msg) => Message.fromJson(msg))
            .toList();
        if (fetchedMessages.isNotEmpty) {
          isnewconversation = false;
          isNewConversation = false;
          markMessageAsSeen(data['messages'][0]['_id']);
        }
        setState(() {
          isnewconversation;
        });
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
      final newMessage = Message(
        id: DateTime.now().toString(),
        content: message,
        senderId: userid!,
        timestamp: DateTime.now(),
      );

      if (_pagingController.itemList == null) {
        _pagingController.itemList = [];
      }
      _pagingController.itemList!.insert(0, newMessage);
      _pagingController.notifyListeners();

      _controller.clear();
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
      if (_pagingController.itemList != null) {
        _pagingController.itemList!.removeAt(0);
        _pagingController.notifyListeners();
      }
    }
  }

  void _showReactionPicker(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: ReactionPicker(
          onReactionSelected: (emoji) {
            _socketService.addReaction(
              messageId,
              widget.chatRoom.chatRoomId,
              emoji,
            );
          },
        ),
      ),
    );
  }

  Future<void> _joinCall(String callId, String type, bool fromgroup) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('callToken');
    final channelName = prefs.getString('channelName');
    bool isvideo = type == 'video';

    if (token == null || channelName == null || userid == null) return;

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
          ),
        ),
      );
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
            profile: widget.chatRoom.participants.first.profilePic ??
                'assets/avatar/3.png',
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
            profile: widget.chatRoom.participants.first.profilePic ??
                'assets/avatar/3.png',
            name: widget.chatRoom.participants.first.name!,
          ),
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

      _socketService.initiateCall(
          data['call']['_id'], userId, [toUserId], type);
      _joinCall(data['call']['_id'], type, fromgrp);
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
            print('Inviting user: $userId');
          },
        ),
      ),
    );
  }

  void _copyAndPasteText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _controller.text = text;
  }

  String truncateName(String name, {int maxLength = 10}) {
    return name.length > maxLength
        ? '${name.substring(0, maxLength)}...'
        : name;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMessagesLoaded || userid == null) {
      return const CompleteChatShimmer();
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
                        chatRoomId: widget.chatRoom.chatRoomId,
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BottomNavBarScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  InkWell(
                    onTap: () {
                      print(widget.chatRoom.participants.first.name);
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
                          style:
                              TextStyle(fontSize: 28.sp, color: Colors.white),
                        ),
                        Text(
                          'Group',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color.fromARGB(255, 185, 184, 184),
                          ),
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
              icon: const Icon(Icons.call, color: Color(0xFF7400A5)),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: () {
                widget.chatRoom.roomType == 'group'
                    ? showAddFriendsSheet(context, participantsMap, 'video')
                    : startCall(widget.chatRoom.participants.first.userId,
                        "video", false);
              },
              icon: const Icon(Icons.video_call, color: Color(0xFF7400A5)),
            ),
            SizedBox(width: 8.w),
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
                      return MessageBubble(
                        message: message,
                        isSender: isSender,
                        participantsMap: participantsMap,
                        currentUserId: userid!,
                        onLongPress: () => _showReactionPicker(message.id),
                      );
                    },
                    noItemsFoundIndicatorBuilder: (context) {
                      return Center(
                        child: Text(
                          'No Messages Yet. Start The Conversation',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNewConversation)
                      FutureBuilder<List<String>>(
                        future: _randomTextFuture,
                        builder: (context, snapshot) {
                          if (!isNewConversation)
                            return const SizedBox.shrink();
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              height: 80,
                              child: Shimmer.fromColors(
                                baseColor: Colors.purple[300]!,
                                highlightColor: Colors.purple[100]!,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Container(
                                        width: 250,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
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
                            final List<String> suggestions =
                                snapshot.data ?? [];
                            if (suggestions.isEmpty)
                              return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    height: 90,
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
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7400A5),
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
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                      ),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
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
                                          : AppColors.lightText,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF7400A5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
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
    _pagingController.dispose();
    _controller.dispose();
    if (_socketService.isConnected) {
      _socketService.socket.emit('leave', widget.chatRoom.chatRoomId);
      print('✅ Emitted leave event for room: ${widget.chatRoom.chatRoomId}');
    }
    super.dispose();
  }
}
