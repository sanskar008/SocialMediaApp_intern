import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';

class CommentScreen extends StatefulWidget {
  final Post post;

  const CommentScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _fetchedComments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      final response = await http.post(
        Uri.parse('${BASE_URL}api/getCommentsForPostId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'userId': userId,
        },
        body: jsonEncode({
          'feedId': widget.post.feedId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _fetchedComments = data['comments'];
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch comments.');
        }
      } else {
        throw Exception('Failed to fetch comments: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Error fetching comments: $e'))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.initialize();
      await _apiService.makeRequest(
        path: 'api/comment',
        method: 'POST',
        body: {
          'comment': _commentController.text,
          'postId': widget.post.feedId,
        },
      );

      _fetchComments(); // Refresh comments after adding
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Failed to add comment: $e'))),
      );
    } finally {
      _commentController.clear();
      setState(() => _isLoading = false);
    }
  }

  Widget _buildParentPost() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[400]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.post.profilepic == null ? AssetImage('assets/avatar/4.png') : NetworkImage(widget.post.profilepic!),
                radius: 16,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.post.usrname}',
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.post.agoTime,
                    style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.post.content.isNotEmpty)
            Text(
              widget.post.content,
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 15),
            ),
          if (widget.post.media != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.post.media![0]['url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ))
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_fetchedComments.length} replies',
                style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                '${widget.post.reactions.length} likes',
                style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Your custom navigation logic
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
        // Return true to allow the pop
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          title: Text(
            'Post',
            style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildParentPost(),
                  if (_fetchedComments.isEmpty && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No comments yet.',
                        style: GoogleFonts.roboto(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 70),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _fetchedComments.length,
                      itemBuilder: (context, index) {
                        final comment = _fetchedComments[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  print(comment);
                                },
                                child: CircleAvatar(
                                  backgroundImage: comment['user']['profilePic'] == null ? AssetImage('assets/avatar/4.png') : NetworkImage(comment['user']['profilePic']),
                                  radius: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment['user']['name'],
                                          style: GoogleFonts.roboto(
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          comment['agoTime'],
                                          style: GoogleFonts.roboto(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['comment'],
                                      style: GoogleFonts.roboto(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/avatar/4.png'),
                        radius: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Reply to ${widget.post.usrname}',
                            hintStyle: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.send, color: Colors.purple),
                        onPressed: _isLoading ? null : _addComment,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
