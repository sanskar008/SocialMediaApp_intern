import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/services/live_message_handler.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

const appId = "da20a837fb44462fa7ad25129c429270";

class LiveAyush extends StatefulWidget {
  final bool isboradcaster;
  final String token;
  final String channel;

  const LiveAyush({
    Key? key,
    required this.token,
    required this.channel,
    required this.isboradcaster,
  }) : super(key: key);

  @override
  _LiveAyushState createState() => _LiveAyushState();
}

class Message {
  final Map<String, dynamic> senderInfo;
  final String message;
  final DateTime timestamp;
  final bool isCurrentUser;

  Message({
    required this.senderInfo,
    required this.message,
    required this.timestamp,
    required this.isCurrentUser,
  });
}

class _LiveAyushState extends State<LiveAyush> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  late IO.Socket _socket;
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;
  int _viewerCountfinal = 0;
  String? _currentUserId;
  Timer? _cacheRefreshTimer;

  @override
  void initState() {
    super.initState();
    initAgora();
    _initSocket();
    _getCurrentUserId();

    // Set up cache refresh timer (every 8 minutes to be safe with 10-minute expiry)
    _cacheRefreshTimer = Timer.periodic(Duration(minutes: 8), (timer) {
      if (_isConnected) {
        // Refresh cache by rejoining
        if (widget.isboradcaster) {
          _socket.emit('openStream', widget.channel);
        } else {
          _socket.emit('joinStream', widget.channel);
        }
      }
    });
    SocketService().onViewerCountUpdated = (count) {
      setState(() {
        _viewerCountfinal = count;
        print("here is the count $count");
      });
    };

    SocketService().onStreamEnded = () {
      // Show alert or navigate back
      Navigator.pop(context);
    };

    if (widget.isboradcaster) {
      SocketService().openStream(widget.channel);
    } else {
      SocketService().joinStream(widget.channel);
    }
  }

  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
  }

  void _initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final socketToken = prefs.getString('socketToken');

    _socket = IO.io(
        BASE_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': socketToken})
            .enableAutoConnect()
            .build());

    _socket.onConnect((_) {
      debugPrint('Socket Connected: ${_socket.id}');
      setState(() => _isConnected = true);

      if (widget.isboradcaster) {
        _socket.emit('openStream', widget.channel);
      } else {
        _socket.emit('joinStream', widget.channel);
      }
    });

    // Handle incoming messages with proper event name
    _socket.on('receive', (data) {
      // Changed from 'receive' to 'message'
      debugPrint('Received message data: $data');
      print('ye le bhai $data');
      if (mounted && data != null) {
        try {
          final senderInfo = data['senderInfo'] ?? {'username': 'Unknown User'};
          final isCurrentUser = senderInfo['_id'] == _currentUserId;

          setState(() {
            _messages.add(Message(
              senderInfo: Map<String, dynamic>.from(senderInfo),
              message: data['message'] ?? '',
              timestamp: DateTime.now(),
              isCurrentUser: isCurrentUser,
            ));
          });
        } catch (e) {
          print('Error processing received message: $e');
        }
      }
    });

    // Send a test message to verify connection
    _socket.on('connect', (_) {
      print('Connected to socket server');
    });

    // Handle errors with more detailed logging
    _socket.on('error', (data) {
      debugPrint('Socket error: $data');
      if (mounted) {
        String errorMessage = 'An error occurred';
        if (data is Map) {
          errorMessage = data['message'] ?? errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Center(child: Text(errorMessage))),
        );
      }
    });

    _socket.onDisconnect((_) {
      debugPrint('Socket Disconnected');
      setState(() => _isConnected = false);
    });
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      final messageData = {
        'streamId': widget.channel,
        'message': message.trim(),
      };

      print('Sending message: $messageData'); // Debug log

      // Add message to local list immediately for better UX
      // setState(() {
      //   _messages.add(Message(
      //     senderInfo: {'username': 'You'}, // Local user
      //     message: message.trim(),
      //     timestamp: DateTime.now(),
      //     isCurrentUser: true,
      //   ));
      // });

      // Emit message event
      _socket.emit('send', messageData);
      _messageController.clear();

      // Add delivery status check
      Future.delayed(Duration(seconds: 2), () {
        if (_socket.connected) {
          print('Message sent successfully');
        } else {
          print('Message might not have been delivered - socket disconnected');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Center(
                      child: Text('Message might not have been delivered'))),
            );
          }
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Center(
                  child: Text('Failed to send message: ${e.toString()}'))),
        );
      }
    }
  }

  void _endStream() async {
    if (widget.isboradcaster) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('user_id');
        String? token = prefs.getString('user_token');

        if (userId == null || token == null) {
          debugPrint('UserId or Token is missing!');
          return;
        }

        final response = await http.post(
          Uri.parse('${BASE_URL}api/end-live-stream'),
          headers: {
            'Content-Type': 'application/json',
            'userId': userId,
            'token': token,
          },
        );

        if (response.statusCode != 200) {
          debugPrint('Failed to end live stream on server');
          debugPrint('Status Code: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        if (response.statusCode == 200) {
          print('live ended');
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
        }
      } catch (e) {
        debugPrint('Error ending live stream: $e');
      }

      _socket.emit('endStream', {
        'streamId': widget.channel,
      });
    }

    _dispose();
  }

  @override
  void dispose() {
    _cacheRefreshTimer?.cancel();
    _dispose();
    super.dispose();
  }

  Future<void> initAgora() async {
    try {
      if (widget.isboradcaster) {
        await [Permission.microphone, Permission.camera].request();
      }

      _engine = await createAgoraRtcEngine();

      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Successfully joined channel: ${widget.channel}');
            setState(() {
              _localUserJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Remote user joined: $remoteUid');
        //    _viewerCount++;
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: $err - $msg');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Center(child: Text('Error: $msg'))),
            );
          },
        ),
      );

      await _engine.enableVideo();

      if (widget.isboradcaster) {
        await _engine.startPreview();
      }

      // Set client role before joining channel
      await _engine.setClientRole(
          role: widget.isboradcaster
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience);

      // Join channel with error handling
      try {
        await _engine.joinChannel(
          token: widget.token,
          channelId: widget.channel,
          uid: 0,
          options: ChannelMediaOptions(
            clientRoleType: widget.isboradcaster
                ? ClientRoleType.clientRoleBroadcaster
                : ClientRoleType.clientRoleAudience,
            publishCameraTrack: widget.isboradcaster,
            publishMicrophoneTrack: widget.isboradcaster,
            autoSubscribeVideo: true,
            autoSubscribeAudio: true,
          ),
        );
      } catch (e) {
        print('Error joining channel: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Center(child: Text('Failed to join channel: $e'))),
        );
      }
    } catch (e) {
      print('Error initializing Agora: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Failed to initialize: $e'))),
      );
    }
  }

  Future<void> _dispose() async {
    _messages.clear();
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen video
            Positioned.fill(
              child: _buildVideoStream(),
            ),

            // Header overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _buildHeader(),
              ),
            ),

            // Floating messages - now only showing last 3
            Positioned(
              left: 0,
              right: 0,
              bottom: 80, // Position above input field
              child: _buildFloatingMessages(),
            ),

            // Message input at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _buildMessageInput(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMessages() {
    // Get only the last 3 messages
    final lastThreeMessages = _messages.length > 3
        ? _messages.sublist(_messages.length - 3)
        : _messages;

    return Container(
      height: 200, // Fixed height for messages area
      child: ListView.builder(
        reverse: true,
        itemCount: lastThreeMessages.length,
        itemBuilder: (context, index) {
          final message = lastThreeMessages[index];

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: AssetImage(message.senderInfo['avatar'] ??
                        'assets/avatar/default.png'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.senderInfo['name'] ?? 'Anonymous',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          message.message,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: userProvider.userProfile != null
                    ? NetworkImage(userProvider.userProfile!)
                    : AssetImage('assets/avatar/1.png') as ImageProvider,
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye,
                        color: Colors.white70,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${_viewerCountfinal -1}',
                        style: GoogleFonts.roboto(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          if (widget.isboradcaster) ...[
            // Mic toggle
            GestureDetector(
              onTap: () async {
                setState(() {
                  _isMuted = !_isMuted;
                });
                await _engine.muteLocalAudioStream(_isMuted);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 20),

            // Switch camera button
            GestureDetector(
              onTap: () async {
                try {
                  await _engine.switchCamera();
                } catch (e) {
                  print("Error switching camera: $e");
                }
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cameraswitch_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            SizedBox(width: 20),
          ],

          // Leave button
          GestureDetector(
            onTap: () async {
              widget.isboradcaster ? _endStream() : Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
              ),
              child: Text(
                'Leave',
                style: GoogleFonts.roboto(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Send Message...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStream() {
    if (!_localUserJoined) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.black87,
      child: widget.isboradcaster
          ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: 0),
              ),
            )
          : _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channel),
                  ),
                )
              : Center(
                  child: Text(
                    'Waiting for broadcaster...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
    );
  }
}
