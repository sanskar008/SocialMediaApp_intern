import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postcard.dart';
import 'package:socialmedia/community/communityListView.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/settings.dart';
import 'package:socialmedia/users/show_post_content.dart';
import 'package:socialmedia/users/userfollowinglist.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:switcher_button/switcher_button.dart';
import 'package:tab_container/tab_container.dart';
import 'package:video_player/video_player.dart';

class user_profile extends StatefulWidget {
  const user_profile({
    super.key,
  });

  @override
  State<user_profile> createState() => _user_profileState();
}

class _user_profileState extends State<user_profile> {
  String? Username;
  List<Map<String, dynamic>> posts = []; // State to hold the posts
  String? selectedImageUrl; // State to track the selected image for preview
  String? selectedImageContent;
  int followers = 0;
  int following = 0;
  int postlength = 0;
  bool isLoadingpost = true;
  bool privacychecker = false;
  bool isloadingprivacy = false;
  bool isprofileloaded = false;
  String? profilepic;
  bool isonpost = true;
  String bio = '';
  late UserProviderall userProvider;
  List<dynamic> interests = [];
  bool showAllInterests = false;

  @override
  void initState() {
    super.initState();
    //getusername();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {}); // Refresh UI after loading data
    });
    await fetchProfile(); // This will set the initial switch state
    await fetchPosts();
    //await _loadPrivacyState(); // This will load from SharedPreferences as fallback
    setState(() {
      isprofileloaded = true;
    });
  }

  Future<void> _loadPrivacyState() async {
    final prefs = await SharedPreferences.getInstance();
  }

  Future<void> _savePrivacyState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_switch_value', value);
  }

  // Future<void> getusername() async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();

  //   setState(() {
  //     username = prefs.getString('user_name');
  //   });
  // }

  void _rebuildScreen() {
    //setState(() {});
    _initializeProfile();
  }

  Future<void> changeProfile(
      BuildContext context, String userId, String token, String name) async {
    final ImagePicker _picker = ImagePicker();
    XFile? pickedFile;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(
                  'Take A Photo',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () async {
                  pickedFile =
                      await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context);
                  if (pickedFile != null) {
                    print('yaha gya phele');
                    print(pickedFile);
                    uploadImage(File(pickedFile!.path), userId, token, name);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose From Gallery',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () async {
                  pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context);
                  if (pickedFile != null) {
                    uploadImage(File(pickedFile!.path), userId, token, name);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> uploadImage(
      File imageFile, String userId, String token, String name) async {
    var uri = Uri.parse("${BASE_URL}api/edit-profile");
    //var request = http.MultipartRequest('POST', uri);

    // Add headers
    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll({
        'userId': userId,
        'token': token,
      });

    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    // Add name as a form field
    request.fields['name'] = name;

    // Send request
    var response = await request.send();
    var responseString =
        await response.stream.bytesToString(); // Read response body

    print("Status Code: ${response.statusCode}");
    print("Response: $responseString");

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => user_profile()));
      print("Image uploaded successfully");
    } else {
      print("Failed to upload image");
    }
  }

  //TOGGLE SWITCH HANDLER

  Future<void> _updatePrivacyLevel(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      final headers = {
        'Content-Type': 'application/json',
        'token': token,
        'userId': userId,
      };

      final body = {
        'privacyLevel': value ? 1 : 0,
      };

      final response = await http.put(
        Uri.parse('${BASE_URL}api/edit-profile'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update privacy level: ${response.body}');
      }

      await _savePrivacyState(value);

      // Parse response to confirm update
    } catch (e) {
      print("Error updating privacy level: $e");
      rethrow; // Rethrow to handle in the onChange
    }
  }

  //////////////////

  Future<void> fetchPosts() async {
    final String url = '${BASE_URL}api/get-posts';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('User ID or Token is missing.'))),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'userid': userid,
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Filter posts to only include those with media
        final List<Map<String, dynamic>> allPosts =
            List<Map<String, dynamic>>.from(data['posts']);
        final List<Map<String, dynamic>> mediaOnlyPosts = allPosts
            .where((post) =>
                post['data']['media'] != null &&
                post['data']['media'].isNotEmpty)
            .toList();

        setState(() {
          posts = allPosts; // Store all posts in the state variable
          // posts = mediaOnlyPosts;
          // postlength = mediaOnlyPosts.length;

          // Sort posts by `createdAt` in descending order
          posts.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
          isLoadingpost = false;
        });
      } else {
        print('Failed to fetch posts: ${response.statusCode}');

        setState(() {
          isLoadingpost = false;
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Center(child: Text('An error occurred while fetching posts.'))),
      );
      setState(() {
        isLoadingpost = false;
      });
    }
  }

  Map<String, dynamic>? profileData; // State variable to store profile data
  bool isLoading = false;

  Future<void> fetchProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      print('User ID or token is missing');
      return;
    }

    // API URL with query parameter
    final Uri url = Uri.parse('${BASE_URL}api/showProfile?other=$userid');

    // Define the headers
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'userid': userid,
      'token': token,
    };

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      // Make the GET request
      final http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print(responseData);
        if (responseData['result'] != null &&
            responseData['result'] is List &&
            responseData['result'].isNotEmpty) {
          final userDetails = responseData['result'][0];
          print('lereeeeeeee bhaiiiii ${userDetails['privacyLevel']}');

          followers = userDetails['followers'] ?? 0;
          following = userDetails['followings'] ?? 0;
          Username = userDetails['name'];
          profileData = userDetails; // Store the fetched user details
          privacychecker = userDetails['privacyLevel'] == 1 ? true : false;
          isloadingprivacy = true;
          profilepic = userDetails['profilePic'];
          final int public = userDetails['public'] ?? 1;
          userProvider.setPublicStatus(public);
          bio = userDetails['bio'];
          interests = userDetails['interests'] ?? [];
          print(
              '(((((((((((((((((((((((((((((((((((((((((((((((((((((())))))))))))))))))))))))))))))))))))))))))))))))))))))');
          print(interests);
          // Parse interests
          // if (userDetails['interests'] != null && userDetails['interests'] is List) {
          //   profileData!['interests'] = List<String>.from(userDetails['interests']);
          // } else {
          //   profileData!['interests'] = [];
          // }

          setState(() {
            Username;
          });
        } else {
          print('No user details found in the response.');
        }
        print(privacychecker);

        print('Profile fetched successfully: $responseData');
      } else {
        print('Failed to fetch profile. Status code: ${response.statusCode}');
        print('Error: ${response.body}');
      }
    } catch (error) {
      print('An error occurred: $error');
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  void _showImagePreview(String imageUrl, String content) {
    setState(() {
      selectedImageUrl = imageUrl;
      selectedImageContent = content;
    });
  }

  void _closeImagePreview() {
    setState(() {
      selectedImageUrl = null;
    });
  }

  Widget _buildThoughtsTab() {
    final thoughtPosts = posts
        .where((post) =>
            post['data']['media'] == null || (post['data']['media'].isEmpty))
        .toList();
    print("yelele $thoughtPosts");

    return SizedBox.expand(
      child: isLoadingpost
          ? Center(
              child: Text(
                'Loading thoughts...',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          : thoughtPosts.isEmpty
              ? Center(
                  child: Text(
                    'No thoughts to show',
                    style: GoogleFonts.roboto(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: thoughtPosts.length,
                  itemBuilder: (context, index) {
                    final post = thoughtPosts[index];
                    final content = post['data']['content'] ?? 'No content';
                    final createdAt = post['createdAt'] != null
                        ? DateTime.fromMillisecondsSinceEpoch(
                            post['createdAt'] * 1000)
                        : null;
                    final formattedDate = createdAt != null
                        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                        : '';
                    final profilePic = post['profilePic'] ?? '';
                    final name = post['name'] ?? 'Unknown';

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFF2A2A3A),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(profilePic),
                                  radius: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  name,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.roboto(
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              content,
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.favorite_border,
                                    color: Colors.grey, size: 18.sp),
                                const SizedBox(width: 4),
                                Text(
                                  post['reactionCount'].toString(),
                                  style: GoogleFonts.roboto(
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.comment_outlined,
                                    color: Colors.grey, size: 18.sp),
                                const SizedBox(width: 4),
                                Text(
                                  post['commentCount'].toString(),
                                  style: GoogleFonts.roboto(
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.lightText
              : AppColors.darkText,
          body: isprofileloaded
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkGradient
                            : AppColors.lightGradient),
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        leading: IconButton(
                            icon: Icon(Icons.arrow_back_ios,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText),
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        BottomNavBarScreen()))),
                        actions: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  print('lereeeeee bhaiii $privacychecker');
                                },
                                child: Text(
                                  'Go Anonymous',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12.sp,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Padding(
                                  padding: EdgeInsets.only(right: 20.w),
                                  child: isloadingprivacy
                                      ? SwitcherButton(
                                          offColor: Colors.grey.shade600,
                                          onColor: Colors.white,
                                          value: privacychecker,
                                          onChange: (value) async {
                                            await _updatePrivacyLevel(value);
                                            Future.delayed(
                                                Duration(milliseconds: 200),
                                                () {
                                              _rebuildScreen();
                                            });
                                          },
                                        )
                                      : CircularProgressIndicator()),
                            ],
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 50),
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    changeProfile(
                                        context,
                                        userProvider.userId!,
                                        userProvider.userToken!,
                                        userProvider.userName!);
                                  },
                                  child: Container(
                                    height: 100.h,
                                    width: 100.w,
                                    child: CircleAvatar(
                                        radius: 50,
                                        backgroundImage: profilepic == null
                                            ? AssetImage('assets/avatar/2.png')
                                            : NetworkImage(profilepic!)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkText
                                            : AppColors.lightText,
                                        size: 20.sp),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              child: Text(
                                Username ?? 'Loading...',
                                style: GoogleFonts.roboto(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                bio,
                                style: GoogleFonts.roboto(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FollowerFollowingScreen(
                                                    initialTabIndex: 0,
                                                  )));
                                    },
                                    child:
                                        _buildStat('Followers', '$followers')),
                                SizedBox(width: 32),
                                InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FollowerFollowingScreen(
                                                    initialTabIndex: 1,
                                                  )));
                                    },
                                    child:
                                        _buildStat('Following', '$following')),
                                SizedBox(width: 25),
                                InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SettingsScreen(
                                                    privacyLev: privacychecker,
                                                  )));
                                    },
                                    child: Icon(Icons.settings, size: 28))
                              ],
                            ),
                            SizedBox(height: 20.h),
                            interests.isEmpty
                                ? SizedBox()
                                : Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2A2A3A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            ...(!showAllInterests
                                                    ? interests.take(3)
                                                    : interests)
                                                .map((interest) {
                                              return Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                    vertical: 8.0),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF7400A5),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
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
                                            if (interests.length > 3)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    showAllInterests =
                                                        !showAllInterests;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 8.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
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
                              height: MediaQuery.of(context).size.height *
                                  0.6, // Fixed height for tab container
                              child: TabContainer(
                                
                                color: Colors.transparent,
                                selectedTextStyle: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7400A5),
                                   // decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF7400A5),
                                    decorationThickness: 2),
                                unselectedTextStyle: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                ),
                                children: [
                                  _buildPostsTab(),
                                  _buildThoughtsTab(),
                                  // _buildThoughtsTab(),
                                  _buildCommunitiesTab(),
                                ],
                                tabs: [
                                  Text('Posts',
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      )),
                                  Text('Quotes',
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      )),
                                  Text('Community',
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ))
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: LoadingAnimationWidget.twistingDots(
                      leftDotColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                      rightDotColor: Colors.purple,
                      size: 20),
                )),
    );
  }

  Widget _buildPostsTab() {
    return SizedBox.expand(
      // Ensures the tab fills the available space
      child: isLoadingpost
          ? Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.4),
              child: Center(
                  child: Text(
                'No Posts to show',
                style: GoogleFonts.roboto(
                    fontSize: 16.sp, fontWeight: FontWeight.w400),
              )),
            )
          : CustomScrollView(
              physics: NeverScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(8),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    delegate: _buildGridDelegate(),
                  ),
                ),
              ],
            ),
    );
  }



  Widget _buildCommunitiesTab() {
    return CommunitiesListView();
  }

  SliverChildBuilderDelegate _buildGridDelegate() {
    final mediaPosts = posts.where((post) {
      final mediaList = post['data']['media'];
      return mediaList != null && mediaList.isNotEmpty;
    }).toList();

    return SliverChildBuilderDelegate(
      (context, index) {
        if (mediaPosts.isEmpty || index >= mediaPosts.length) {
          return Container();
        }

        final post = mediaPosts[index];
        final mediaList = post['data']['media'];
        final mediaUrl = mediaList.isNotEmpty ? mediaList[0]['url'] : null;

        if (mediaUrl == null) {
          return Container();
        }

        bool isVideo = mediaUrl.toLowerCase().endsWith('.mp4') ||
            mediaUrl.toLowerCase().endsWith('.mov') ||
            mediaUrl.toLowerCase().endsWith('.webm') ||
            mediaUrl.toLowerCase().contains('video');

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailsScreen(feedId: post['feedId']),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideo
                ? PostVideoPlayer(
                    url: mediaUrl,
                    shouldPlay: false,
                  )
                : Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey,
                        child: Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
      childCount: mediaPosts.length,
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkText
                  : AppColors.lightText,
              fontSize: 15.sp,
              fontWeight: FontWeight.w400),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkText
                : AppColors.lightText,
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String text, {bool isSelected = false}) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              text,
              style: GoogleFonts.roboto(
                  color: isSelected
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.yellow
                          : AppColors.lightButton
                      : Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.lightText,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(
              width: 5,
            ),
            if (text == 'Posts')
              Text(
                postlength.toString(),
                style: GoogleFonts.roboto(
                    color: isSelected
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.yellow
                            : AppColors.lightButton
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkText
                            : AppColors.lightText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
        SizedBox(height: 4),
        if (isSelected)
          Container(
              height: 2,
              width: 40,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.yellow
                  : AppColors.lightButton),
      ],
    );
  }
}
