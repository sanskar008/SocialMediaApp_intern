import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket socket;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  Function(int)? onViewerCountUpdated;
  Function()? onStreamEnded;
  Function(dynamic)? onUserJoinedStream;
  Function(dynamic)? onMessageReaction; // New callback for reactions
  Function(dynamic)? onReactionRemoved; // New callback for reaction removal

  // Add these variables to track connection state
  final bool _isConnecting = false;
  final int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 10;
  static const int RECONNECT_INTERVAL = 3; // seconds

  Function(dynamic)? onMessageReceived;
  Function(dynamic)? onCallReceived;
  Function(dynamic)? onCallEnded;
  Function(dynamic)? onUserJoined;
  Function(dynamic)? onUserLeft;

  Function(dynamic)? onSocketError;

  SocketService._internal();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) {
      print('Socket already connected');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final socketToken = prefs.getString('socketToken');
      final userId = prefs.getString('user_id');

      if (socketToken == null || userId == null) {
        print('Missing credentials for socket connection');
        return;
      }

      socket = IO.io(
          BASE_URL,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .setAuth({'token': socketToken})
              .enableAutoConnect()
              .enableReconnection()
              .setReconnectionAttempts(double.infinity)
              .setReconnectionDelay(1000)
              .build());

      socket.onConnect((_) {
        print('Socket Connected');
        _isConnected = true;
        socket.emit('openCall', userId);
        _startPingTimer();
        _setupMessageListeners();
        _setupLiveStreamListeners();
      });

      socket.onDisconnect((_) {
        print('Socket Disconnected');
        _isConnected = false;
        _scheduleReconnect();
      });

      socket.onError((error) {
        print('Socket Error: $error');
        _isConnected = false;
        _scheduleReconnect();
      });

      socket.onReconnect((_) {
        print('Socket Reconnected');
        _isConnected = true;
        socket.emit('openCall', userId);
      });

      // Connect the socket
      socket.connect();
    } catch (e) {
      print('Socket connection error: $e');
      _scheduleReconnect();
    }
  }

  //LIVES SOCKET IMPLEMENTATION

  void _setupLiveStreamListeners() {
    socket.off('viewerCount');
    socket.on('viewerCount', (count) {
      print('👁 Viewer Count Updated: $count');
      if (onViewerCountUpdated != null) onViewerCountUpdated!(count);
    });

    socket.off('ended');
    socket.on('ended', (data) {
      if (onStreamEnded != null) onStreamEnded!();
    });

    socket.off('joined');
    socket.on('joined', (data) {
      if (onUserJoinedStream != null) onUserJoinedStream!(data);
    });
  }

  void openStream(String streamId) {
    if (!_isConnected) return;
    print('broadcaster live join kar raha hai');
    socket.emit('openStream', streamId);
  }

  void joinStream(String streamId) {
    if (!_isConnected) return;
    print('user join kar raha hai');
    socket.emit('joinStream', streamId);
  }

  void leaveStream() {
    if (!_isConnected) return;
    socket.emit('leaveStream');
  }

  void endStream(String streamId) {
    if (!_isConnected) return;
    socket.emit('endStream', {'streamId': streamId});
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        socket.emit('ping');
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  //Reaction File added
  void _setupMessageListeners() {
    print('calllll huaaaaa');
    socket.off('receiveMessage');
    socket.off('messageReaction');
    socket.off('reactionRemoved');

    socket.on('receiveMessage', (data) {
      print('✅ Socket received message: $data');
      try {
        var messageData = data;
        if (data is String) {
          messageData = jsonDecode(data);
        }
        if (messageData != null) {
          print('Processing received message: $messageData');
          if (onMessageReceived != null) {
            onMessageReceived!(messageData);
          }
        }
      } catch (e) {
        print('Error processing received message: $e');
      }
    });

    socket.on('messageReaction', (data) {
      print('✅ Received reaction: $data');
      if (onMessageReaction != null) {
        onMessageReaction!(data);
      }
    });

    socket.on('reactionRemoved', (data) {
      print('✅ Reaction removed: $data');
      if (onReactionRemoved != null) {
        onReactionRemoved!(data);
      }
    });
  }

  void addReaction(String messageId, String entityId, String reaction) {
    if (!_isConnected) {
      print('Socket not connected. Cannot add reaction.');
      return;
    }
    socket.emit('reactToMessage', {
      'messageId': messageId,
      'entityId': entityId,
      'reaction': reaction,
    });
  }

  void removeReaction(String messageId, String entityId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot remove reaction.');
      return;
    }
    socket.emit('removeReaction', {
      'messageId': messageId,
      'entityId': entityId,
    });
  }

  void _setupErrorHandling() {
    socket.on('error', (error) {
      print('Socket Error: $error');
      if (onSocketError != null) {
        onSocketError!(error);
      }
    });

    socket.onDisconnect((_) {
      print('Socket Disconnected');
      _isConnected = false;
      _scheduleReconnect();
    });

    socket.onError((error) {
      print('Socket Error: $error');
      _isConnected = false;
      _scheduleReconnect();
    });
  }

  void initiateCall(
      String callId, String userId, List<String> otherId, String type) {
    if (!_isConnected) {
      print('Socket not connected. Cannot initiate call.');
      return;
    }

    socket.emit('callInit', {
      'callId': callId,
      'userId': userId,
      'otherIds': otherId,
      'type': type
    });
  }

  void joinCall(String callId, String userId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot join call.');
      return;
    }

    socket.emit('joinCall', {'callId': callId, 'userId': userId});
  }

  void endCall(String callId, String userId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot end call.');
      return;
    }

    socket.emit('endCall', {'callId': callId, 'userId': userId});
  }

  void addParticipant(String callId, String userId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot add participant.');
      return;
    }

    socket.emit('add', {'callId': callId, 'userId': userId});
  }

  void joinRoom(String roomId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot join room.');
      connect().then((_) {
        socket.emit('join', roomId);
        print('Joining room after reconnect: $roomId');
      });
      return;
    }
    socket.emit('join', roomId);
    print('Joining room: $roomId');
  }

  void sendMessage(String senderId, String roomId, String content,
      String entity, bool isbot, bool isSpeakerOn,
      {String? voice}) {
    if (!_isConnected) {
      print('Socket not connected. Cannot send message.');
      return;
    }

    final messageData = {
      'senderId': senderId,
      'entityId': roomId,
      'content': content,
      'entity': entity,
      'isBot': isbot,
      'voice': voice,
      'isSpeakerOn': isSpeakerOn,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('Sending message: $messageData');
    socket.emit('sendMessage', jsonEncode(messageData));
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}
