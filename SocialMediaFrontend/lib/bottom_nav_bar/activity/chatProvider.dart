import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/utils/constants.dart';

class ChatProvider with ChangeNotifier {
  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> _filteredChatRooms = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatRoom> get filteredChatRooms => _filteredChatRooms;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Filter chat rooms based on search query
  void filterChatRooms(String searchQuery) {
    if (searchQuery.isEmpty) {
      _filteredChatRooms = List.from(_chatRooms);
    } else {
      final query = searchQuery.toLowerCase().trim();
      _filteredChatRooms = _chatRooms.where((room) {
        if (room.roomType == 'dm') {
          return room.participants.any((participant) => participant.name?.toLowerCase().contains(query) ?? false);
        } else if (room.roomType == 'group') {
          return room.groupName?.toLowerCase().contains(query) ?? false;
        }
        return false;
      }).toList();
    }
    notifyListeners();
  }

  // Get direct message count
  int getDMCount() {
    return _chatRooms.where((room) => room.roomType == 'dm').length;
  }

  // Get group count
  int getGroupCount() {
    return _chatRooms.where((room) => room.roomType == 'group').length;
  }

  // Fetch chat rooms from API
  Future<void> fetchChatRooms() async {
    // REMOVE THIS CONDITION to allow refreshing data
    // if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String? userid = prefs.getString('user_id');
    String? token = prefs.getString('user_token');

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-all-chat-rooms'),
        headers: {
          'userId': userid!,
          'token': token!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _chatRooms = (data['chatRooms'] as List)
            .where((room) => !room['participants'].any(
                (participant) => participant['userId'] == '67d3bf8914c75ee094e30bfa'))
            .map((room) => ChatRoom.fromJson(room))
            .toList();

        _filteredChatRooms = List.from(_chatRooms);
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching chat rooms: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void addNewChatRoom(ChatRoom newChatRoom) {
    // Check if the chat room already exists to avoid duplicates
    if (!_chatRooms.any((room) => room.id == newChatRoom.id)) {
      _chatRooms.insert(0, newChatRoom); // Add to the beginning of the list
      _filteredChatRooms = List.from(_chatRooms);
      notifyListeners();
    }
  }

  // You can keep this method but it's essentially the same as fetchChatRooms now
  Future<void> refreshChatRooms() async {
    return fetchChatRooms();
  }
}