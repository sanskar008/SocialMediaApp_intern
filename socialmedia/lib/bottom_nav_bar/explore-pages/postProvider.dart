import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';

class PostsProvider with ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;

  // Getters
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  DateTime? get lastFetchTime => _lastFetchTime;

  // Check if data is stale (older than 5 minutes)
  bool get isDataStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!).inMinutes > 5;
  }

  // Initialize with empty posts
  PostsProvider() {
    _posts = [];
    _isLoading = true;
    _hasError = false;
  }

  // Method to fetch posts from API
  Future<void> fetchPosts(String userId, String token, {bool forceRefresh = false}) async {
    // If data is already loaded and not stale, and we're not forcing a refresh, return
    if (_posts.isNotEmpty && !isDataStale && !forceRefresh) {
      return;
    }

    try {
      _isLoading = true;
      _hasError = false;
      notifyListeners();

      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-home-posts'),
        headers: {
          'userId': userId,
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        _posts = (data['posts'] as List).map((post) => Post.fromJson(post)).toList();

        _lastFetchTime = DateTime.now();
        _isLoading = false;
        _hasError = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Server error: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Error fetching posts: $e';
      notifyListeners();
      print('Error fetching posts: $e');
    }
  }

  // Update a post (for likes, comments, etc.)
  void updatePost(Post updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  // Update comment count for a post
  void updateCommentCount(String postId, int newCount) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      _posts[index].commentcount = newCount;
      notifyListeners();
    }
  }

  // Clear posts data (useful for logout)
  void clearPosts() {
    _posts = [];
    _lastFetchTime = null;
    notifyListeners();
  }
}
