import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/community/communityApiService.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityScreen extends StatefulWidget {
  final String communityId;

  const CommunityScreen({
    Key? key,
    required this.communityId,
  }) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<Map<String, dynamic>> futureCommunity;
  late Future<Map<String, dynamic>> futureCommunityPosts;
  late Future<bool> futureIsJoined;
  bool isJoined = false;

  @override
  void initState() {
    super.initState();
    futureCommunity = fetchCommunity(widget.communityId);
    futureCommunityPosts = fetchCommunityPosts(widget.communityId);
    _checkIfUserJoined();
  }

  Future<void> _checkIfUserJoined() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      futureIsJoined = checkIfUserJoined(userId, widget.communityId);
      futureIsJoined.then((value) {
        setState(() {
          isJoined = value;
        });
      });
    }
  }


  Future<bool> checkIfUserJoined(String userId, String communityId) async {
    try {
      final response = await http.post(
        Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/isUserJoined'),
        headers: {
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'userId': userId,
          'communityId': communityId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isJoined'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking if user joined: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchCommunity(String communityId) async {
    final response = await http.get(
      Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/$communityId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load community');
    }
  }

  Future<Map<String, dynamic>> fetchCommunityPosts(String communityId) async {
    final response = await http.get(
      Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/$communityId/post'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load community posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            futureCommunity,
            futureCommunityPosts
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.purple));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data found.', style: TextStyle(color: Colors.white)));
            }

            final communityData = snapshot.data![0];
            final postsData = snapshot.data![1];
            final allPosts = postsData['posts'] as List;

            // Filter posts by communityId
            final posts = allPosts.where((post) => post['communityId'] == widget.communityId).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: CommunityHeader(
                    communityData: communityData,
                    isJoined: isJoined,
                    onJoinPressed: () {
                      setState(() {
                        isJoined = !isJoined;
                      });
                    },
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return PostWidget(
                        post: post,
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CommunityHeader extends StatelessWidget {
  final Map<String, dynamic> communityData;
  final bool isJoined;
  final VoidCallback onJoinPressed;

  const CommunityHeader({
    Key? key,
    required this.communityData,
    required this.isJoined,
    required this.onJoinPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Column(
          children: [
            Stack(
              clipBehavior: Clip.none, // Allow child to be drawn outside the stack
              children: [
                // Background image container
                Padding(
                  padding:  EdgeInsets.all(12.0..w),
                  child: Container(
                    height: 160.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(communityData['backgroundImage'] ?? 'https://via.placeholder.com/500x120'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                ),
                // Positioned CircleAvatar with yellow background and purple chevron icon
                 Positioned(
                  bottom: -20, // Adjust this value to make the circle overlap more
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30.sp,
                      backgroundImage: communityData['profilePicture'] != null ? NetworkImage(communityData['profilePicture']) : null,
                    ),
                  ),
                ),
              ],
            ),
             SizedBox(height: 20.h), // Add space for the overlapping CircleAvatar
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Text(
                    communityData['name'] ?? 'Sports',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Column(
                        children: [
                          Text('Posts', style: TextStyle(color: Colors.grey)),
                          Text(communityData['postCount'].toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(width: 30),
                       Column(
                        children: [
                          Text('Members', style: TextStyle(color: Colors.grey)),
                          Text(communityData['memberCount'].toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                       SizedBox(width: 30.h),
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('user_id');
                          if (userId != null) {
                            final communityId = communityData['_id'];
                            final action = isJoined ? 'remove' : 'join';

                            // Show loading indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Center(child: Text('${isJoined ? 'Leaving' : 'Joining'} community...')),
                                duration: const Duration(seconds: 1),
                              ),
                            );

                            // Call the service
                            final CommunityService communityService = CommunityService();
                            final success = await communityService.joinOrLeaveCommunity(userId, communityId, action);

                            if (success) {
                              onJoinPressed(); // Toggle the isJoined state
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Center(child: Text('Successfully ${isJoined ? 'left' : 'joined'} community')),
                                  backgroundColor: Colors.white,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Center(child: Text('Failed to ${isJoined ? 'leave' : 'join'} community')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            // Handle case where user is not logged in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to join communities'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7400A5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        ),
                        child: Text(
                          isJoined ? 'Leave' : 'Join',
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTag('Rock'),
                  const SizedBox(width: 8),
                  _buildTag('Fashion'),
                  const SizedBox(width: 8),
                  _buildTag('Motor Cycles'),
                  const SizedBox(width: 8),
                  _buildTag('Show +5'),
                ],
              ),
              const SizedBox(height: 12),
              ReadMoreText(
                'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical',
                trimLines: 2,
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
                colorClickableText: Color(0xFF7400A5),
                trimMode: TrimMode.Line,
                trimCollapsedText: ' Read More',
                trimExpandedText: ' Show Less',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostWidget({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime createdAt = DateTime.parse(post['createdAt']);
    final timeAgo = timeago.format(createdAt);
    final hasMedia = post['mediaUrls'] != null && (post['mediaUrls'] as List).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // CircleAvatar(
              //   radius: 15,
              //   backgroundColor: Colors.grey,
              //   child: Icon(Icons.person, size: 18, color: Colors.white),
              // ),
              // SizedBox(width: 10),
              // Text(
              //   'comm 1',
              //   style: TextStyle(
              //     fontWeight: FontWeight.bold,
              //     color: Colors.white,
              //   ),
              // ),
              // Spacer(),
              // IconButton(
              //   icon: Icon(Icons.more_horiz, color: Colors.white),
              //   onPressed: () {},
              // ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['content'] ?? 'No content',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              // if (post['content'] != null && post['content'].toString().length > 50)
              //   TextButton(
              //     onPressed: () {},
              //     style: TextButton.styleFrom(
              //       padding: EdgeInsets.zero,
              //       minimumSize: const Size(50, 20),
              //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //     ),
              //     child: const Text(
              //       'Read more',
              //       style: TextStyle(
              //         color: Colors.blue,
              //         fontSize: 14,
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
        if (hasMedia)
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: CachedNetworkImage(
              imageUrl: (post['mediaUrls'] as List).first,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.purple)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
              // SizedBox(width: 5),
              // Text('2k', style: TextStyle(color: Colors.white)),
              // SizedBox(width: 20),
              // Icon(Icons.favorite_border, size: 20, color: Colors.white),
              // SizedBox(width: 5),
              // Text('2.1k', style: TextStyle(color: Colors.white)),
              const Spacer(),
              Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: Colors.grey[800]),
      ],
    );
  }
}
