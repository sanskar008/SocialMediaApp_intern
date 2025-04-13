import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/apiservice1.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/activity/detailed_chat_page.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/community/communityDetailedScreen.dart';
import 'package:socialmedia/community/communityListView.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/user_apis/acceptrequest.dart';
import 'package:socialmedia/users/show_post_content.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:story_view/story_view.dart';
import 'package:http/http.dart' as http;

class UserProfileScreen extends StatefulWidget {
  final String userId; // ID of the profile we're viewing

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  List<dynamic> _posts = [];
  Map<String, List<dynamic>>? _stories;
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  String? _error;
  String? user__Id;
  String? __token;
  late TabController _tabController;
  int _currentTabIndex = 0;
  late UserProviderall userProvider;
  List<dynamic> interests = [];
  bool showAllInterests = false;
  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {}); // Refresh UI after loading data
    });
    _loadPreferences();
    initializeApiServiceAndLoadProfile();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> blockUser(BuildContext context, String blockedUserId) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    final url = Uri.parse('${BASE_URL}api/block-user');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'userid': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
        },
        body: jsonEncode({'blocked': blockedUserId}),
      );

      if (response.statusCode == 200) {
        debugPrint('User blocked successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('User blocked',
                  style: TextStyle(fontFamily: 'Poppins'))),
        );
      } else {
        debugPrint('Failed to block user: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to block user',
                  style: TextStyle(fontFamily: 'Poppins'))),
        );
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Something went wrong',
                style: TextStyle(fontFamily: 'Poppins'))),
      );
    }
  }

  Future<void> _startChat(String participantId) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('${BASE_URL}api/start-message'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
        },
        body: json.encode({
          'userId2': participantId,
        }),
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final chatRoom = ChatRoom.fromJson(jsonResponse['chatRoom']);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DChatScreen(chatRoom: chatRoom)));
      } else {
        throw Exception('Failed to start chat');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        'Error starting chat: ${e.toString()}',
        style: GoogleFonts.roboto(),
      )));
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      user__Id = prefs.getString('user_id'); // Fetch userId
      __token = prefs.getString('user_token'); // Fetch token
    });
  }

  Future<void> initializeApiServiceAndLoadProfile() async {
    try {
      await _apiService.initialize();
      await _loadProfile();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> sendFriendRequest(String userId, BuildContext context) async {
    try {
      // Show loading indicator while sending the request
      setState(() {
        _isLoading = true;
      });

      // Make the POST request to send a friend request
      final response = await _apiService.makeRequest(
        path: 'api/sendRequest',
        method: 'POST',
        body: {
          'sentTo': userId, // Pass the userId of the profile being viewed
        },
      );

      // Handle successful response
      if (response['message'] != null) {
        Fluttertoast.showToast(
          msg: "Request Sent",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER, // 👈 Display in the center
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      // Handle errors
      Fluttertoast.showToast(
        msg: "Already Sent",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER, // 👈 Display in the center
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      await _apiService.initialize();
      final response = await _apiService.makeRequest(
        path: 'api/showProfile?other=${widget.userId}',
        method: 'GET',
      );

      setState(() {
        _profileData = response['result'][0];
        interests = _profileData!['interests'] ?? [];
        _isLoading = false;
      });
      print(interests);

      if (_profileData?['public'] == 1) {
        _loadPosts();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final response = await _apiService.makeRequest(
        path: 'api/get-posts?userId=${widget.userId}',
        method: 'GET',
      );
      setState(() {
        _posts = List<dynamic>.from(response['posts']);
        print('hullulululu $_posts');
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadStories() async {
    try {
      final response = await _apiService.makeRequest(
        path: 'api/get-story-for-user',
        method: 'GET',
      );
      if (response['stories'] != null) {
        setState(() {
          _stories = Map<String, List<dynamic>>.from(response['stories']);
        });
        _showStories();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Center(child: Text('Failed to load stories: ${e.toString()}'))),
      );
    }
  }

  Future<List<Community>> _fetchUserCommunities(String userId) async {
    if (userId.isEmpty) return [];

    try {
      // Get token from SharedPreferences or user provider
      final token = userProvider.userToken ?? '';
      final currentUserId = userProvider.userId ?? '';

      // Set headers with authorization token
      final headers = {
        'token': token,
        'userid': currentUserId,
        'Content-Type': 'application/json',
      };

      // First fetch the user profile to get community IDs
      final Uri profileUrl =
          Uri.parse('${BASE_URL}api/showProfile?other=$userId');
      final profileResponse = await http.get(
        profileUrl,
        headers: headers,
      );

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        final communityIds =
            List<String>.from(profileData['result'][0]['communities'] ?? []);

        if (communityIds.isEmpty) {
          return [];
        }

        // Now fetch details for each community
        List<Community> fetchedCommunities = [];
        for (String communityId in communityIds) {
          await _fetchCommunityInfo(communityId, headers, fetchedCommunities);
        }

        return fetchedCommunities;
      } else {
        print('Error: ${profileResponse.statusCode} - ${profileResponse.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching communities: $e');
      return [];
    }
  }

  Future<void> _fetchCommunityInfo(String communityId,
      Map<String, String> headers, List<Community> fetchedCommunities) async {
    try {
      final Uri communityUrl =
          Uri.parse('${BASE_URL_COMMUNITIES}api/communities/$communityId');
      final communityResponse = await http.get(
        communityUrl,
        headers: headers,
      );

      if (communityResponse.statusCode == 200) {
        final communityData = json.decode(communityResponse.body);
        fetchedCommunities.add(Community.fromJson(communityData));
      } else {
        print(
            'Error fetching community $communityId: ${communityResponse.statusCode} - ${communityResponse.body}');
      }
    } catch (e) {
      print('Error fetching community $communityId: $e');
    }
  }

  // Future<void> fetchStoriesForUser() async {
  //   const String url = '${BASE_URL}api/get-story-for-user';

  //   try {
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'userId': user__Id!,
  //         'token': __token!,
  //       },
  //       body: json.encode({
  //         'userId': widget.userId,
  //       }),
  //     );

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       if (data['stories'] != null) {
  //         setState(() {
  //           _stories = Map<String, List<dynamic>>.from(data['stories']);
  //         });
  //         _showStories();
  //       }
  //     } else {
  //       throw Exception('Failed to fetch stories: ${response.body}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching stories: $e');
  //   }
  // }

  void _showStories() {
    if (_stories == null || !_stories!.containsKey(widget.userId)) return;

    final storyItems = _stories![widget.userId]!.map((story) {
      return StoryItem.pageImage(
        url: story['url'],
        caption: story['ago_time'],
        controller: StoryController(),
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryView(
          storyItems: storyItems,
          controller: StoryController(),
          onComplete: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          GestureDetector(
            child: CustomProfileAvatar(
                profilePicUrl: _profileData!['profilePic'],
                matchScore: _profileData!['compatibility'] ?? "0"),
          ),
          SizedBox(height: 16.h),
          Text(
            _profileData?['name'] ?? '',
            style: GoogleFonts.roboto(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkText
                  : AppColors.lightText,
              fontSize: 20.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.transparent
                              : Colors.white,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 34.h),
                      side: BorderSide(
                        color: Color(0xFF7400A5),
                      ),
                    ),
                    onPressed: () {
                      if (_profileData?['isFollowing'] == true) {
                        _startChat(widget.userId);
                      } else {
                        Fluttertoast.showToast(
                          msg: "You need to follow this user to message them",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          backgroundColor: Colors.black87,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                    },
                    child: Text(
                      'Message',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF7400A5),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7400A5),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 34.h),
                    ),
                    onPressed: () async {
                      print('yele 1');
                      if (_profileData?['requestSent'] == true) return;

                      // Case 2: User is already following - handle unfollow
                      print('yele 2');

                      if (_profileData?['requestPending'] == true) {
                        try {
                          final response = await http.put(
                            Uri.parse("${BASE_URL}api/acceptRequest"),
                            headers: {
                              'userid': userProvider.userId ?? '',
                              'token': userProvider.userToken ?? '',
                              "Content-Type": "application/json",
                            },
                            body: jsonEncode({
                              "otherId": widget.userId,
                            }),
                          );

                          if (response.statusCode == 200) {
                            setState(() {
                              _profileData?['requestPending'] = false;
                            });
                            Fluttertoast.showToast(
                              msg: "Request accepted successfully",
                              toastLength: Toast.LENGTH_SHORT,
                            );
                            _loadPosts(); // Reload posts since user is now following
                          }
                        } catch (e) {
                          print("Error accepting request: $e");
                          Fluttertoast.showToast(
                            msg: "Failed to accept request",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        }
                        return;
                      }

                      if (_profileData?['isFollowing'] == true) {
                        return;
                      }

                      print('yee;ele 2.5');

                      print('yele 3');

                      // Case 3: Handle pending request (Accept)

                      // Case 4: Handle follow back (user is a follower but not following)
                      print('yele 4');

                      // Case 5: Default case - Send friend request
                      try {
                        final response = await http.post(
                          Uri.parse("${BASE_URL}api/sendRequest"),
                          headers: {
                            'userId': userProvider.userId ?? '',
                            'token': userProvider.userToken ?? '',
                            "Content-Type": "application/json",
                          },
                          body: jsonEncode({
                            "sentTo": widget.userId, // Pass otherId as JSON
                          }),
                        );

                        if (response.statusCode == 200) {
                          setState(() {
                            _profileData?['requestSent'] = true;
                          });
                          Fluttertoast.showToast(
                            msg: "Friend request sent",
                            toastLength: Toast.LENGTH_SHORT,
                          );
                        }
                      } catch (e) {
                        print("Error sending friend request: $e");
                        Fluttertoast.showToast(
                          msg: "Failed to send friend request",
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      }
                    },
                    child: Text(
                      _getButtonText(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn(
                  'Followers', '${_profileData?['followers'] ?? 0}'),
              SizedBox(width: 32.w),
              _buildStatColumn(
                  'Following', '${_profileData?['followings'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_profileData?['requestSent'] == true) {
      return 'Requested';
    } else if (_profileData?['requestPending'] == true) {
      return 'Accept';
    } else if (_profileData?['isFollowing'] == true) {
      return 'Following';
    } else {
      return 'Add Friend';
    }
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey
                  : Colors.black,
              fontSize: 14.sp),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    // Only show posts if user is following
    if (_profileData?['public'] == 0) {
      return Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
          ),
          Center(
            child: Column(
              children: [
                Text(
                  'Private Account',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                  ),
                ),
                if (_profileData?['isFollower'] == true)
                  Text(
                    'Follow back to see their posts',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final postsWithMedia = _posts.where((post) {
      return post['data']['media'] != null &&
         // post['data']['media'] is List &&
          post['data']['media'].isNotEmpty;
    }).toList();
    print('tungtungtung $postsWithMedia');

    if (postsWithMedia.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.35),
          child: Text(
            'No posts yet',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 2,
        ),
        itemCount: postsWithMedia.length,
        itemBuilder: (context, index) {
          final post = postsWithMedia[index];
          final List<dynamic> mediaList = post['data']['media'];
          final String imageUrl =
              mediaList.isNotEmpty ? mediaList[0]['url'] : '';

          return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PostDetailsScreen(feedId: post['feedId'])));
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16.sp),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.sp),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width * 0.8,
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey)),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget _buildCommunitiesTab() {
  //   return Column(
  //     children: [
  //       SizedBox(
  //         height: MediaQuery.of(context).size.height * 0.2,
  //       ),
  //       Center(
  //         child: Text(
  //           'Communities Feature Coming Soon',
  //           style: TextStyle(
  //             color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
  //             fontSize: 16,
  //           ),
  //         ),
  //       ),
  //      // CommunitiesListView(),
  //     ],
  //   );
  // }
  Widget _buildCommunitiesTab() {
    return FutureBuilder<List<Community>>(
      future: _fetchUserCommunities(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.twistingDots(
                leftDotColor: Colors.white,
                rightDotColor: Color(0xFF7400A5),
                size: 20),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading communities: ${snapshot.error}',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          );
        }

        final communities = snapshot.data ?? [];

        if (communities.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.35),
              child: Text(
                'No Communities Joined Yet',
                style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];

            return Padding(
              padding: EdgeInsets.only(left: 10.0.w, top: 10.h, right: 10.0.w),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    border: Border.all(
                      color: Color(0xFF7400A5),
                    )),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: community.profilePicture != null
                        ? NetworkImage(community.profilePicture!)
                        : AssetImage('assets/avatar/2.png') as ImageProvider,
                    backgroundColor: Colors.purple.shade100,
                  ),
                  title: Text(
                    community.name,
                    style: GoogleFonts.roboto(
                      color: Color(0xFF7400A5),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    community.description ?? 'No description',
                    style: GoogleFonts.roboto(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${community.membersCount} Members',
                    style: GoogleFonts.roboto(
                      color: Colors.grey,
                      fontSize: 12.sp,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CommunityDetailScreen(communityId: community.id),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '${_profileData?['name']}',
            style: GoogleFonts.leagueSpartan(
                fontSize: 24.sp, fontWeight: FontWeight.w400),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'block') {
                    // Handle block user logic
                    blockUser(context, widget.userId);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> BottomNavBarScreen()));
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'block',
                    child: Text(
                      'Block User',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_horiz, color: Colors.white),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interests',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: [
                                // Display first 3 interests
                                ...(!showAllInterests
                                        ? interests.take(3)
                                        : interests)
                                    .map((interest) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF7400A5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      interest,
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  );
                                }).toList(),

                                // Show more/less button as the last element
                                if (interests.length > 3)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        showAllInterests = !showAllInterests;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        showAllInterests
                                            ? 'Show Less'
                                            : 'Show +${interests.length - 3}',
                                        style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Container(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        child: TabBar(
                          indicatorColor: Color(0xFF7400A5),
                          labelStyle: GoogleFonts.poppins(
                            color: Color(0xFF7400A5),
                          ),
                          unselectedLabelColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                          unselectedLabelStyle: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                          ),
                          dividerColor: Colors.transparent,
                          controller: _tabController,
                          tabs: const [
                            Tab(text: "Posts"),
                            Tab(text: "Community"),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPostsGrid(),
                            _buildCommunitiesTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomProfileAvatar extends StatelessWidget {
  final String? profilePicUrl;
  final String matchScore;

  const CustomProfileAvatar({
    Key? key,
    this.profilePicUrl,
    required this.matchScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Circular border with gradient
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFF7400A5),
                Color(0xFF7400A5),
              ],
            ),
          ),
        ),

        // Profile Picture or Placeholder
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.grey.shade200,
                width: 3),
            image: profilePicUrl != null
                ? DecorationImage(
                    image: NetworkImage(profilePicUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: profilePicUrl == null
              ? Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey.shade600,
                )
              : null,
        ),

        // Match Score Indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF7400A5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${matchScore}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
