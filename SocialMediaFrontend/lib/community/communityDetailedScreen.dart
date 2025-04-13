// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:socialmedia/bottom_nav_bar/post_Screen.dart';
// import 'package:socialmedia/utils/constants.dart';

// class CommunityDetailScreen extends StatefulWidget {
//   final String communityId;

//   const CommunityDetailScreen({Key? key, required this.communityId}) : super(key: key);

//   @override
//   _CommunityDetailScreenState createState() => _CommunityDetailScreenState();
// }

// class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
//   bool isLoading = true;
//   Map<String, dynamic> communityData = {};
//   List<dynamic> communityPosts = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchCommunityDetails();
//   }

//   Future<void> fetchCommunityDetails() async {
//     try {
//       // Fetch community details
//       final Uri communityUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/${widget.communityId}');
//       final communityResponse = await http.get(communityUrl);

//       if (communityResponse.statusCode == 200) {
//         final data = json.decode(communityResponse.body);

//         // Fetch community posts
//         final Uri postsUrl = Uri.parse('${BASE_URL_COMMUNITIES}api/communities/${widget.communityId}/posts');
//         final postsResponse = await http.get(postsUrl);

//         setState(() {
//           communityData = data['result'];
//           communityPosts = postsResponse.statusCode == 200 ? json.decode(postsResponse.body)['result'] : [];
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load community details');
//       }
//     } catch (e) {
//       print('Error fetching community details: $e');
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           isLoading ? 'Loading...' : communityData['name'] ?? 'Community',
//           style: GoogleFonts.roboto(),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.more_vert),
//             onPressed: () {
//               // Show community options menu
//               showModalBottomSheet(
//                 context: context,
//                 builder: (context) => CommunityOptionsSheet(
//                   communityId: widget.communityId,
//                   isMember: true, // You might want to determine this from API
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Community header with info
//                 CommunityHeader(communityData: communityData),

//                 // Posts list
//                 Expanded(
//                   child: communityPosts.isEmpty
//                       ? Center(
//                           child: Text(
//                             'No posts in this community yet',
//                             style: GoogleFonts.roboto(color: Colors.grey),
//                           ),
//                         )
//                       : ListView.builder(
//                           itemCount: communityPosts.length,
//                           itemBuilder: (context, index) {
//                             final post = communityPosts[index];
//                             return PostCard(post: post);
//                           },
//                         ),
//                 ),
//               ],
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Navigate to create post screen
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//             builder: (context) => PostScreen(),
//             ),
//           );
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }

// class CommunityHeader extends StatelessWidget {
//   final Map<String, dynamic> communityData;

//   const CommunityHeader({Key? key, required this.communityData}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 4,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 40,
//                 backgroundImage: communityData['profilePic'] != null ? NetworkImage(communityData['profilePic']) : AssetImage('assets/avatar/2.png') as ImageProvider,
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       communityData['name'] ?? 'Community',
//                       style: GoogleFonts.roboto(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       '${communityData['membersCount'] ?? 0} members',
//                       style: GoogleFonts.roboto(
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           Text(
//             communityData['description'] ?? 'No description',
//             style: GoogleFonts.roboto(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PostCard extends StatelessWidget {
//   final Map<String, dynamic> post;

//   const PostCard({Key? key, required this.post}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Padding(
//         padding: EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundImage: post['authorProfilePic'] != null ? NetworkImage(post['authorProfilePic']) : AssetImage('assets/avatar/2.png') as ImageProvider,
//                 ),
//                 SizedBox(width: 8),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       post['authorName'] ?? 'Unknown',
//                       style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       _formatDate(post['createdAt']),
//                       style: GoogleFonts.roboto(
//                         color: Colors.grey,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//             Text(
//               post['content'] ?? '',
//               style: GoogleFonts.roboto(),
//             ),
//             if (post['mediaUrl'] != null) ...[
//               SizedBox(height: 8),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   post['mediaUrl'],
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                 ),
//               ),
//             ],
//             SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildActionButton(
//                   icon: Icons.thumb_up_outlined,
//                   label: '${post['likes'] ?? 0}',
//                   onPressed: () {
//                     // Like post
//                   },
//                 ),
//                 _buildActionButton(
//                   icon: Icons.comment_outlined,
//                   label: '${post['comments'] ?? 0}',
//                   onPressed: () {
//                     // View comments
//                   },
//                 ),
//                 _buildActionButton(
//                   icon: Icons.share_outlined,
//                   label: 'Share',
//                   onPressed: () {
//                     // Share post
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//   }) {
//     return TextButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//     );
//   }

//   String _formatDate(String? dateString) {
//     if (dateString == null) return 'Unknown date';
//     try {
//       final date = DateTime.parse(dateString);
//       final now = DateTime.now();
//       final difference = now.difference(date);

//       if (difference.inDays > 0) {
//         return '${difference.inDays}d ago';
//       } else if (difference.inHours > 0) {
//         return '${difference.inHours}h ago';
//       } else if (difference.inMinutes > 0) {
//         return '${difference.inMinutes}m ago';
//       } else {
//         return 'Just now';
//       }
//     } catch (e) {
//       return dateString;
//     }
//   }
// }

// class CommunityOptionsSheet extends StatelessWidget {
//   final String communityId;
//   final bool isMember;

//   const CommunityOptionsSheet({
//     Key? key,
//     required this.communityId,
//     required this.isMember,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             leading: Icon(Icons.info_outline),
//             title: Text('Community Info'),
//             onTap: () {
//               Navigator.pop(context);
//               // Navigate to community info screen
//             },
//           ),
//           if (isMember)
//             ListTile(
//               leading: Icon(Icons.exit_to_app),
//               title: Text('Leave Community'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Show leave confirmation dialog
//               },
//             )
//           else
//             ListTile(
//               leading: Icon(Icons.group_add),
//               title: Text('Join Community'),
//               onTap: () {
//                 Navigator.pop(context);
//                 // Join community
//               },
//             ),
//           ListTile(
//             leading: Icon(Icons.report),
//             title: Text('Report Community'),
//             onTap: () {
//               Navigator.pop(context);
//               // Show report dialog
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;


class CommunityDetailScreen extends StatefulWidget {
  final String communityId;

  const CommunityDetailScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  _CommunityDetailScreenState createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic> communityData = {};
  List<dynamic> communityPosts = [];

  @override
  void initState() {
    super.initState();
    fetchCommunityDetails();
  }

  // Future<void> fetchCommunityDetails() async {
  //   try {
  //     // Fetch community details
  //     final Uri communityUrl = Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/${widget.communityId}');
  //     final communityResponse = await http.get(communityUrl);

  //     if (communityResponse.statusCode == 200) {
  //       final data = json.decode(communityResponse.body);

  //       // Fetch community posts
  //       final Uri postsUrl = Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/${widget.communityId}/post');
  //       final postsResponse = await http.get(postsUrl);

  //       if (postsResponse.statusCode == 200) {
  //         final postsData = json.decode(postsResponse.body);

  //         setState(() {
  //           communityData = data;
  //           communityPosts = postsData['posts'] ?? [];
  //           isLoading = false;
  //         });
  //       } else {
  //         throw Exception('Failed to load community posts');
  //       }
  //     } else {
  //       throw Exception('Failed to load community details');
  //     }
  //   } catch (e) {
  //     print('Error fetching community details: $e');
  //     setState(() => isLoading = false);
  //   }
  // }
  Future<void> fetchCommunityDetails() async {
    try {
      // Fetch community details
      final Uri communityUrl = Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/${widget.communityId}');
      final communityResponse = await http.get(communityUrl);

      if (communityResponse.statusCode == 200) {
        final data = json.decode(communityResponse.body);

        // Fetch community posts
        final Uri postsUrl = Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/${widget.communityId}/post');
        final postsResponse = await http.get(postsUrl);

        if (postsResponse.statusCode == 200) {
          final postsData = json.decode(postsResponse.body);

          // Filter posts by communityId
          List<dynamic> allPosts = postsData['posts'] ?? [];
          List<dynamic> filteredPosts = allPosts.where((post) => post['communityId'] == widget.communityId).toList();

          setState(() {
            communityData = data;
            communityPosts = filteredPosts;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load community posts');
        }
      } else {
        throw Exception('Failed to load community details');
      }
    } catch (e) {
      print('Error fetching community details: $e');
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: isLoading
            ? Text('Loading...', style: GoogleFonts.roboto(color: Colors.white))
            : Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.amber,
                    backgroundImage: communityData['profilePicture'] != null ? NetworkImage(communityData['profilePicture']) : null,
                    radius: 16,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        communityData['name'] ?? 'Community',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${communityData['memberCount'] ?? 0} members',
                        style: GoogleFonts.roboto(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Color(0xFF333333),
                builder: (context) => _buildOptionsSheet(),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : communityPosts.isEmpty
              ? Center(child: Text('No posts in this community', style: GoogleFonts.roboto(color: Colors.white)))
              : ListView.builder(
                  itemCount: communityPosts.length,
                  itemBuilder: (context, index) {
                    final post = communityPosts[index];
                    return PostWidget(post: post);
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 10.h, // Accounts for keyboard + extra padding
            left: 8.0,
            right: 8.0,
            top: 8.0,
          ),
          child: Container(
            color: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 12.h), // Use .h for vertical padding
            child: Text(
              'Only Community Admins Can Message',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: Colors.white70,
                fontSize: 14.sp, // Use .sp for font size
              ),
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildOptionsSheet() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.white),
            title: Text('Leave', style: GoogleFonts.roboto(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.report, color: Colors.white),
            title: Text('Report', style: GoogleFonts.roboto(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// class PostWidget extends StatelessWidget {
//   final Map<String, dynamic> post;

//   const PostWidget({
//     Key? key,
//     required this.post,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final DateTime createdAt = DateTime.parse(post['createdAt']);
//     final timeAgo = timeago.format(createdAt);
//     final hasMedia = post['mediaUrls'] != null && (post['mediaUrls'] as List).isNotEmpty;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Row(
//             children: [
//               // CircleAvatar(
//               //   radius: 15,
//               //   backgroundColor: Colors.grey,
//               //   backgroundImage: post['authorProfilePic'] != null ? NetworkImage(post['authorProfilePic']) : null,
//               // ),
//               // SizedBox(width: 10),
//               // Text(
//               //   post['authorName'] ?? 'User',
//               //   style: TextStyle(
//               //     fontWeight: FontWeight.bold,
//               //     color: Colors.white,
//               //   ),
//               // ),
//               // Spacer(),
//               // IconButton(
//               //   icon: Icon(Icons.more_horiz, color: Colors.white),
//               //   onPressed: () {},
//               // ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 post['content'] ?? 'No content',
//                 style: TextStyle(fontSize: 14, color: Colors.white),
//               ),
//               // if (post['content'] != null && post['content'].toString().length > 50)
//               //   TextButton(
//               //     onPressed: () {},
//               //     style: TextButton.styleFrom(
//               //       padding: EdgeInsets.zero,
//               //       minimumSize: Size(50, 20),
//               //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               //     ),
//               //     child: Text(
//               //       'Read more',
//               //       style: TextStyle(
//               //         color: Colors.blue,
//               //         fontSize: 14,
//               //       ),
//               //     ),
//               //   ),
//             ],
//           ),
//         ),
//         if (hasMedia)
//           Container(
//             width: double.infinity,
//             height: 200,
//             margin: const EdgeInsets.symmetric(vertical: 8.0),
//             child: CachedNetworkImage(
//               imageUrl: (post['mediaUrls'] as List).first,
//               fit: BoxFit.cover,
//               placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.purple)),
//               errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white),
//             ),
//           ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: Row(
//             children: [
//               // Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
//               // SizedBox(width: 5),
//               // Text(post['commentsCount']?.toString() ?? '0', style: TextStyle(color: Colors.white)),
//               // SizedBox(width: 20),
//               // Icon(Icons.favorite_border, size: 20, color: Colors.white),
//               // SizedBox(width: 5),
//               // Text(post['likesCount']?.toString() ?? '0', style: TextStyle(color: Colors.white)),
//               Spacer(),
//               Text(
//                 timeAgo,
//                 style: TextStyle(
//                   color: Colors.grey[400],
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Divider(height: 1, thickness: 0.5, color: Colors.grey[800]),
//       ],
//     );
//   }
// }


class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostWidget({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final DateTime createdAt = DateTime.parse(widget.post['createdAt']);
    final timeAgo = timeago.format(createdAt);
    final hasMedia = widget.post['mediaUrls'] != null && (widget.post['mediaUrls'] as List).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // CircleAvatar and other row content
              // CircleAvatar(
              //   radius: 15,
              //   backgroundColor: Colors.grey,
              //   backgroundImage: post['authorProfilePic'] != null ? NetworkImage(post['authorProfilePic']) : null,
              // ),
              // SizedBox(width: 10),
              // Text(
              //   post['authorName'] ?? 'User',
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
                widget.post['content'] ?? 'No content',
                style: TextStyle(fontSize: 14, color: Colors.white),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (!_expanded && (widget.post['content'] ?? '').toString().length > 70) // Approximate length that might exceed 2 lines
                TextButton(
                  onPressed: () {
                    setState(() {
                      _expanded = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50, 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Read more',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasMedia)
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: CachedNetworkImage(
              imageUrl: (widget.post['mediaUrls'] as List).first,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.purple)),
              errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Icons and other row content
              // Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
              // SizedBox(width: 5),
              // Text(post['commentsCount']?.toString() ?? '0', style: TextStyle(color: Colors.white)),
              // SizedBox(width: 20),
              // Icon(Icons.favorite_border, size: 20, color: Colors.white),
              // SizedBox(width: 5),
              // Text(post['likesCount']?.toString() ?? '0', style: TextStyle(color: Colors.white)),
              Spacer(),
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
