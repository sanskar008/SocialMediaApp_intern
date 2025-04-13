import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/constants.dart';

class PostDetailsScreen extends StatefulWidget {
  final String feedId;

  const PostDetailsScreen({Key? key, required this.feedId}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? postData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPostDetails();
  }

  void navigateToCommentScreen(BuildContext context) {
    // Create a post object using available data and dummy values where needed
    final post = Post(
      // Use real data from postData where available
      id: postData!['_id'] ?? '',
      content: postData!['data']['content'] ?? '',
      media: postData!['data']['media'] as List<dynamic>?,
      agoTime: postData!['agoTime'],
      feedId: postData!['feedId'] ?? '',

      // Use real reaction data if available, otherwise provide dummy data
      reactions: postData!['reactions'] ?? [],
      commentcount: postData!['commentCount'] ?? 0,
      likecount: postData!['reactionCount'] ?? 0,

      // User data
      usrname: postData!['authorDetails']['name'] ?? '',
      userid: postData!['authorDetails']['userId'] ?? '',

      // Reaction details with dummy values if not available
      hasReacted: postData!['hasReacted'] ?? false,
      reactionType: postData!['reactionType'] ?? null,

      // Profile picture
      profilepic: postData!['authorDetails']['profilePic'] ?? null,
    );

    // Navigate to the CommentScreen with the post object
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => CommentScreen(post: post)));
  }

  void _showPostOptions() async {
    if (postData == null) return;
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final currentUserId = userProvider.userId;
    final authorId = postData!['authorDetails']['userId'];
    final isAuthor = currentUserId == authorId;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(isAuthor ? Icons.delete : Icons.report,
                    color: isAuthor ? Colors.red : Colors.orange),
                title: Text(
                  isAuthor ? 'Delete Post' : 'Report',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the modal
                  if (isAuthor) {
                    await _deletePost();
                  } else {
                    Fluttertoast.showToast(
                      msg: "Report has been sent to admin",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePost() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;
    if (userId == null || token == null || postData == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/delete-post'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: json.encode({
          "post_id": postData!['feedId'],
        }),
      );

      if (response.statusCode == 200) {
        print('Post deleted successfully');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => user_profile()));

        // Go back after deletion
      } else {
        print('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  Future<void> fetchPostDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-post-details?feedId=${widget.feedId}'),
        headers: {
          'userId': userProvider.userId!,
          'token': userProvider.userToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          postData = data['post'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load post. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching post details: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post',
          style: GoogleFonts.roboto(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              // Show post options
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child:
                      Text(errorMessage!, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildPostDetails(userProvider),
                  ),
                ),
    );
  }

  Widget _buildPostDetails(UserProviderall userProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (postData == null) {
      return Center(child: Text('No post data available.'));
    }

    final author = postData!['authorDetails'];
    final data = postData!['data'] as Map<String, dynamic>;
    final content = data['content'] as String?;
    final mediaList = data['media'] as List?;
    final timestamp = postData!['createdAt'] as int;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final agoTime = postData!['agoTime'];
    //final timeAgo = timeago.format(dateTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author information
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildProfileImage(author['profilePic']),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    print(postData);
                  },
                  child: Text(
                    author['name'] ?? 'Anonymous one',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  agoTime ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Spacer(),
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
              onPressed: () {
                _showPostOptions();
              },
            ),
          ],
        ),
        SizedBox(height: 12),

        // Post content
        if (content != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              content,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),

        // Media content
        if (mediaList != null && mediaList.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            ),
            margin: EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: mediaList.length > 1
                  ? CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        enlargeCenterPage: false,
                      ),
                      items: mediaList.map<Widget>((item) {
                        return _buildMediaItem(item);
                      }).toList(),
                    )
                  : _buildMediaItem(mediaList[0]),
            ),
          ),

        // Reaction and comment section
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Reaction button
              SizedBox(
                width: 15,
              ),
              InkWell(
                onTap: () {
                  navigateToCommentScreen(context);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 30,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                    SizedBox(width: 6),
                    Text(
                      postData!['commentCount']?.toString() ?? '0',
                      style: GoogleFonts.roboto(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: 25,
              ),
              ReactionButton(
                entityId: postData!['feedId'],
                entityType: "feed",
                userId: userProvider.userId!,
                token: userProvider.userToken!,
              ),

              // Comment button
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        color: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600]),
      );
    }

    return Image.network(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 40,
          height: 40,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 40,
          height: 40,
          color: Colors.grey[300],
          child: Icon(Icons.person, color: Colors.grey[600]),
        );
      },
    );
  }

  Widget _buildMediaItem(Map<String, dynamic> media) {
    final url = media['url'] as String;
    //  final type = media['type'] as String;
    final isVideo = url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.webm') ||
        url.toLowerCase().endsWith('.mkv');

    if (isVideo) {
      return PostVideoPlayer(url: url , shouldPlay: true,);
    } else {
      return Image.network(
        url,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.error, size: 50, color: Colors.grey[600]),
            ),
          );
        },
      );
    }

    //  else if (type == 'video') {
    //   // Return video player if you have implemented it
    //   return Container(
    //     color: Colors.grey[300],
    //     height: 300,
    //     width: double.infinity,
    //     child: Center(
    //       child: Icon(Icons.play_circle_fill, size: 50, color: Colors.grey[600]),
    //     ),
    //   );
    // } else {
    //   return Container(
    //     color: Colors.grey[300],
    //     height: 300,
    //     width: double.infinity,
    //     child: Center(
    //       child: Text('Unsupported media type'),
    //     ),
    //   );
    // }
  }
}
