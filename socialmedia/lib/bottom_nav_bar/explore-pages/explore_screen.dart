// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shimmer/shimmer.dart';  // Add this import
// import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/customappbar.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
// import 'package:socialmedia/services/user_Service_provider.dart';
// import 'package:socialmedia/users/story_section.dart';
// import 'package:http/http.dart' as http;
// import 'package:socialmedia/utils/constants.dart';
// import 'package:pull_to_refresh/pull_to_refresh.dart';

// class ExplorePage extends StatefulWidget {
//   const ExplorePage({super.key});
//   @override
//   _ExplorePageState createState() => _ExplorePageState();
// }

// class _ExplorePageState extends State<ExplorePage> {
//   RefreshController _refreshController =
//       RefreshController(initialRefresh: false);

//   String? userId;
//   String? token;
//   bool isLoading = true;
//   List<Post> posts = [];

//   final GlobalKey<StorySectionState> _storySectionKey = GlobalKey<StorySectionState>();
  
//   @override
//   void initState() {
//     super.initState();
//     fetchUserDetails();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).unfocus();
//     });
//   }

//   void _onRefresh() async {
//     await Future.delayed(Duration(milliseconds: 1000));
//     await fetchPosts();
//     _storySectionKey.currentState?.fetchStories() ?? Future.value(); 
//     _refreshController.refreshCompleted();
//   }

//   void _onLoading() async {
//     await Future.delayed(Duration(milliseconds: 1000));
//     if (mounted) setState(() {});
//     _refreshController.loadComplete();
//   }

//   Future<void> fetchUserDetails() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final fetchedUserId = prefs.getString('user_id');
//     final fetchedToken = prefs.getString('user_token');

//     if (fetchedUserId != null && fetchedToken != null) {
//       setState(() {
//         userId = fetchedUserId;
//         token = fetchedToken;
//         isLoading = false;
//       });
//       await fetchPosts();
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> fetchPosts() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${BASE_URL}api/get-home-posts'),
//         headers: {
//           'userId': userId!,
//           'token': token!,
//         },
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//         setState(() {
//           posts = (data['posts'] as List)
//               .map((post) => Post.fromJson(post))
//               .toList();
//         });
//         print('xxxxxxxx');
//         print(data);
//       }
//     } catch (e) {
//       print('Error fetching posts: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).brightness == Brightness.dark
//           ? Colors.black
//           : Colors.white,
//       appBar: CustomAppBar(),
//       body: isLoading
//           ? _buildShimmerPostItem() // Replace CircularProgressIndicator with shimmer effect
//           : (userId != null && token != null)
//               ? SmartRefresher(
//                   controller: _refreshController,
//                   onRefresh: _onRefresh,
//                   onLoading: _onLoading,
//                   enablePullUp: true,
//                   header: CustomHeader(
//                     builder: (context, mode) {
//                       Widget body;
//                       if (mode == RefreshStatus.idle) {
//                         body = CupertinoActivityIndicator(radius: 14);
//                       } else if (mode == RefreshStatus.refreshing) {
//                         body = CupertinoActivityIndicator(radius: 14);
//                       } else if (mode == RefreshStatus.canRefresh) {
//                         body = CupertinoActivityIndicator(radius: 14);
//                       } else {
//                         body = CupertinoActivityIndicator(radius: 14);
//                       }
//                       return Container(
//                         height: 40.0,
//                         child: Center(child: body),
//                       );
//                     },
//                   ),
//                   child: ListView(
//                     padding: EdgeInsets.zero,
//                     children: [
//                       // Story Section will scroll with posts
//                       StorySection(userId: userId!, token: token!, key: _storySectionKey),
//                       const SizedBox(height: 8),
//                       // Posts Section
//                       ...posts.map((post) => PostCard(post: post)).toList(),
//                     ],
//                   ),
//                 )
//               : Center(child: Text('$userId , $token')),
//     );
//   }
  
//   // Shimmer loading screen widget
//   /* Widget _buildShimmerLoading() {
//     return ListView(
//       children: [
//         // Story circles shimmer
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Shimmer.fromColors(
//             baseColor: Theme.of(context).brightness == Brightness.dark
//                         ? Colors.grey[600]!
//                         : Colors.grey[200]!,
//             highlightColor: Theme.of(context).brightness == Brightness.dark
//                         ? Colors.grey[700]!
//                         : Colors.grey[300]!,
//             child: Container(
//               height: 90,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: 5,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Column(
//                       children: [
//                         Container(
//                           width: 60,
//                           height: 60,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Container(
//                           width: 50,
//                           height: 10,
//                           color: Colors.white,
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
        
//         // Post shimmer items
//         ...List.generate(3, (index) => _buildShimmerPostItem()),
//       ],
//     );
//   }*/
  
//   // Individual shimmer post item
//   Widget _buildShimmerPostItem() {
//     return Shimmer.fromColors(
//       baseColor: Theme.of(context).brightness == Brightness.dark
//                         ? Colors.grey[600]!
//                         : Colors.grey[200]!,
      
      
//       highlightColor: Theme.of(context).brightness == Brightness.dark
//                         ? Colors.grey[700]!
//                         : Colors.grey[300]!,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 // Profile circle
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 // Username and time
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       width: 100,
//                       height: 12,
//                       color: Colors.white,
//                     ),
//                     SizedBox(height: 4),
//                     Container(
//                       width: 60,
//                       height: 10,
//                       color: Colors.white,
//                     ),
//                   ],
//                 ),
//                 Spacer(),
//                 // More options icon
//                 Container(
//                   width: 20,
//                   height: 20,
//                   color: Colors.white,
//                 ),
//               ],
//             ),
//           ),
//           // Post image
//           Container(
//             width: double.infinity,
//             height: 200,
//             color: Colors.white,
//           ),
//           // Action buttons
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Container(
//                   width: 24,
//                   height: 24,
//                   color: Colors.white,
//                 ),
//                 SizedBox(width: 16),
//                 Container(
//                   width: 24,
//                   height: 24,
//                   color: Colors.white,
//                 ),
//                 SizedBox(width: 16),
//                 Container(
//                   width: 24,
//                   height: 24,
//                   color: Colors.white,
//                 ),
//                 Spacer(),
//                 Container(
//                   width: 24,
//                   height: 24,
//                   color: Colors.white,
//                 ),
//               ],
//             ),
//           ),
//           // Caption
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: double.infinity,
//                   height: 10,
//                   color: Colors.white,
//                 ),
//                 SizedBox(height: 4),
//                 Container(
//                   width: MediaQuery.of(context).size.width * 0.7,
//                   height: 10,
//                   color: Colors.white,
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 16),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/customappbar.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/story_section.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  RefreshController _refreshController = RefreshController(initialRefresh: false);

  String? userId;
  String? token;
  bool isLoading = true;

  final GlobalKey<StorySectionState> _storySectionKey = GlobalKey<StorySectionState>();

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  void _onRefresh() async {
    // Force refresh the posts data
    if (userId != null && token != null) {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      await postsProvider.fetchPosts(userId!, token!, forceRefresh: true);
      _storySectionKey.currentState?.fetchStories() ?? Future.value();
    }
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.loadComplete();
  }

  Future<void> fetchUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final fetchedUserId = prefs.getString('user_id');
    final fetchedToken = prefs.getString('user_token');

    if (fetchedUserId != null && fetchedToken != null) {
      setState(() {
        userId = fetchedUserId;
        token = fetchedToken;
        isLoading = false;
      });

      // Initialize the posts provider with user data
      // Don't await here - let it load in the background
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      postsProvider.fetchPosts(fetchedUserId, fetchedToken);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        appBar: CustomAppBar(),
        body: isLoading
            ? _buildShimmerPostItem()
            : (userId != null && token != null)
                ? Consumer<PostsProvider>(
                    builder: (context, postsProvider, child) {
                      // If provider is loading and we have no cached data, show shimmer
                      if (postsProvider.isLoading && postsProvider.posts.isEmpty) {
                        return _buildShimmerPostItem();
                      }
      
                      return SmartRefresher(
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        onLoading: _onLoading,
                        enablePullUp: true,
                        header: CustomHeader(
                          builder: (context, mode) {
                            Widget body;
                            if (mode == RefreshStatus.idle) {
                              body = CupertinoActivityIndicator(radius: 14);
                            } else if (mode == RefreshStatus.refreshing) {
                              body = CupertinoActivityIndicator(radius: 14);
                            } else if (mode == RefreshStatus.canRefresh) {
                              body = CupertinoActivityIndicator(radius: 14);
                            } else {
                              body = CupertinoActivityIndicator(radius: 14);
                            }
                            return Container(
                              height: 40.0,
                              child: Center(child: body),
                            );
                          },
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            // Story Section will scroll with posts
                            StorySection(userId: userId!, token: token!, key: _storySectionKey),
                            const SizedBox(height: 8),
                            // Posts Section
                            ...postsProvider.posts.map((post) => PostCard(post: post)).toList(),
                          ],
                        ),
                      );
                    },
                  )
                : Center(child: Text('$userId , $token')),
      ),
    );
  }

  // Shimmer loading screen widget
  Widget _buildShimmerPostItem() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600]! : Colors.grey[200]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Profile circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                // Username and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
                Spacer(),
                // More options icon
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Post image
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
