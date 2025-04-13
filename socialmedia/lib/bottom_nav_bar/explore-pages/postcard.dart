// post_model.dart
import 'dart:convert';
import 'dart:ffi';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/utilities/hero_dialog_route.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/chatrrom_send_post.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/comments_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

class Post {
  final String id;
  final String content;
  final List<dynamic>? media;
  final String agoTime;
  final String feedId;
  final List<dynamic> reactions;
  int commentcount;
  int likecount;
  final String usrname;
  final String userid;
  bool hasReacted;
  String? reactionType;
  String? profilepic;

  Post(
      {required this.id,
      required this.content,
      this.media,
      required this.agoTime,
      required this.feedId,
      required this.reactions,
      required this.usrname,
      required this.commentcount,
      required this.likecount,
      required this.hasReacted,
      required this.userid,
      this.reactionType,
      this.profilepic});

  factory Post.fromJson(Map<String, dynamic> json) {
    List<dynamic> extractComments = [];
    List<dynamic> extractReactions = [];

    if (json['reactions'] != null && json['reactions'].isNotEmpty) {
      extractReactions = json['reactions'][0]['reactions'];
    }
    final reaction = json['reaction'] ?? {};
    final hasReacted =
        reaction['hasReacted'] ?? false; // Default to false if null
    final reactionType = reaction['reactionType']; // can be null

    return Post(
        id: json['_id'],
        content: json['data']['content'] ?? '',
        media: json['data']['media'] is List && json['data']['media'].isNotEmpty
            ? json['data']['media'] // Store full media list
            : null,
        agoTime: json['ago_time'],
        feedId: json['feedId'],
        reactions: extractReactions,
        usrname: json['name'],
        commentcount: json['commentCount'] ?? 0,
        likecount: json['reactionCount'] ?? 0,
        hasReacted: hasReacted,
        reactionType: reactionType,
        profilepic: json['profilePic'] ?? '',
        userid: json['author']);
  }
}

// comment_screen.dart

// post_card.dart
class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Map<String, dynamic>? _reactions;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  bool _isLiking = false;
  String? _userReactionType;

  @override
  void initState() {
    super.initState();
  }

  // Helper getter to check if post is liked
  bool get isLiked =>
      widget.post.reactions.any((r) => r['reaction_type'] == 'like');

  void _handleComment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          post: widget.post, // Pass the entire post object
          //comments: widget.post.comments,
        ),
      ),
    );
  }

  // Inside _PostCardState class
  void _updateCommentCount(int newCount) {
    setState(() {
      widget.post.commentcount = newCount;
    });

    // Also update in the provider
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updateCommentCount(widget.post.id, newCount);
  }

// Any other methods that modify the post (like reactions) should also update the provider
// For example, after successfully posting a reaction:
  void _afterReactionUpdate() {
    // Update the provider with the latest version of this post
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);
    postsProvider.updatePost(widget.post);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    final bool isLiked =
        widget.post.reactions.any((r) => r['reaction_type'] == 'like');

    final mediaList =
        widget.post.media is List ? widget.post.media as List : [];

    final firstMediaUrl = mediaList.isNotEmpty ? mediaList.first['url'] : '';
    final isVideo = firstMediaUrl.toLowerCase().endsWith('.mp4');

    // List<dynamic> mediaList =
    //     widget.post.media != null && widget.post.media is List
    //         ? widget.post.media as List<dynamic> // ✅ Correct way
    //         : [];

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          border: Border(
            bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900.withOpacity(0.8)
                    : Colors.grey.shade300.withOpacity(0.8),
                width: 2),
          )),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserProfileScreen(userId: widget.post.userid),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundImage: widget.post.profilepic == ''
                  ? AssetImage('assets/avatar/4.png')
                  : NetworkImage(widget.post.profilepic!),
              radius: 17,
            ),
            title: Text(
              '${widget.post.usrname}',
              style: GoogleFonts.roboto(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkText
                    : AppColors.lightText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: ThreeDotsMenu(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          if (widget.post.content.isNotEmpty && mediaList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(widget.post.content,
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.lightText,
                      fontSize: 14)),
            ),
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: mediaList.length > 1
                  ? Stack(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: isVideo ? 400 : 350,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                          ),
                          items: mediaList.map((media) {
                            final url = media['url'];
                            final isVideo = url.toLowerCase().endsWith('.mp4');
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isVideo
                                  ? PostVideoPlayer(url: url , shouldPlay: true,)
                                  : CachedNetworkImage(
                                      imageUrl: media['url'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder: (context, url) => Container(
                                        height: 350,
                                        color: Colors.grey[200],
                                        child: Center(
                                            child:
                                                CupertinoActivityIndicator()),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    ),
                            );
                          }).toList(),
                        ),

                        // **Indicator at Top-Right Corner**
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors
                                        .lightText, // Semi-transparent black background
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.view_carousel,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.lightText
                                    : AppColors.darkText,
                              )),
                        ),
                      ],
                    )
                  : isVideo
                      ? PostVideoPlayer(url: firstMediaUrl , shouldPlay: true,)
                      : CachedNetworkImage(
                          imageUrl: firstMediaUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 350,
                          placeholder: (context, url) => Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: const Center(
                                child: CupertinoActivityIndicator()),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _handleComment,
                        child: Container(
                            height: 26,
                            width: 26,
                            child: SvgPicture.asset(
                                'assets/icons/comment-dark.svg')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentcount}',
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                            fontSize: 13),
                      ),
                      const SizedBox(width: 16),

                      // add like icon functionality her
                      // FbReactionBox(),
                      ReactionButton(
                          entityId: widget.post.feedId,
                          entityType: "feed",
                          userId: userProvider.userId!,
                          token: userProvider.userToken!),

                      const SizedBox(width: 8),
                      IconButton(
                          onPressed: () =>
                              showChatRoomSheet(context, widget.post),
                          // onPressed: () =>
                          icon: Icon(Icons.send)),
                      const Spacer(),
                      Text(
                        widget.post.agoTime,
                        style:
                             TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post.content.isNotEmpty && widget.post.media != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.post.content,
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                          fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThreeDotsMenu extends StatelessWidget {
  const ThreeDotsMenu({Key? key}) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        // PopupMenuItem<String>(
        //   value: 'delete',
        //   child: Row(
        //     children: [
        //       Icon(Icons.delete, color: Colors.white),
        //       SizedBox(width: 8),
        //       Text(
        //         'Delete',
        //         style: GoogleFonts.roboto(
        //           fontSize: 14,
        //           color: Theme.of(context).brightness == Brightness.dark
        //               ? Colors.white
        //               : Colors.black87,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag, color: Color(0xFF7400A5)),
              SizedBox(width: 8),
              Text(
                'Report to Admin',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          // case 'delete':
          //   // Empty function for delete
          //   break;
          case 'report':
            _showToast("Report has been sent to admin");
            break;
          // case 'share':
          //   // Empty function for share
          //   break;
        }
      },
    );
  }
}

class PostVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio; // e.g., 0.8 (4:5) or 0.5625 (9:16)
  final bool shouldPlay;

  const PostVideoPlayer(
      {Key? key,
      required this.url,
      this.aspectRatio = 0.7625, // Default: 9:16 (vertical)
      required this.shouldPlay})
      : super(key: key);

  @override
  _PostVideoPlayerState createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasEnded = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.network(widget.url);

    try {
      await _controller.initialize();

      if (!mounted) return;
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration &&
            !_controller.value.isPlaying &&
            !_controller.value.isBuffering) {
          setState(() {
            _hasEnded = true;
          });
        }
      });

      setState(() {
        _isLoading = false;
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: false,
          looping: false,
          showControls: false,
          allowFullScreen: true,
          allowMuting: true,
          aspectRatio: widget.aspectRatio,
          placeholder: Container(color: Colors.black),
          // customControls: const MinimalControls(),
        );
      });
    } catch (e) {
      print("Video error: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_chewieController != null && _controller.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
              ),
            ),
          ),
          if (!_controller.value.isPlaying || _hasEnded)
            GestureDetector(
              onTap: () {
                if (widget.shouldPlay) {
                  _chewieController?.seekTo(Duration.zero);
                  _chewieController?.play();
                  setState(() {
                    _hasEnded = false;
                  });
                }
              },
              child: Container(
                decoration:  BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child:  Icon(
                  Icons.play_arrow,
                  size: 
                  widget.shouldPlay ?
                  48 : 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: const Center(
        child: Text(
          'Unable to load video',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
