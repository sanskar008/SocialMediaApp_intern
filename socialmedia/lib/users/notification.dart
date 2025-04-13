import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/user_apis/acceptrequest.dart';
import 'package:socialmedia/user_apis/fetch_notification.dart';
import 'package:socialmedia/user_apis/rejectrequest.dart';
import 'package:socialmedia/users/listtype_shimmer.dart';
import 'package:socialmedia/users/searched_userprofile.dart';
import 'package:socialmedia/users/show_post_content.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:tab_container/tab_container.dart';
import 'package:http/http.dart' as http;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> friendRequests;
  late Future<List<dynamic>> notificationsList;
  late Future<List<dynamic>> combinedNotifications;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    markNotificationsAsSeen();
  }

  Future<void> markNotificationsAsSeen() async {
    try {
      // Fetch userId and token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? token = prefs.getString('user_token');

      if (userId == null || token == null) {
        print('User ID or Token is missing');
        return;
      }

      // API Endpoint
      final url = Uri.parse('${BASE_URL}api/mark-as-seen');

      // Request Body
      Map<String, dynamic> body = {
        'markAll': "true",
      };

      // Make POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'userId': userId, // Include userId in headers
        },
        body: jsonEncode(body),
      );

      // Handle Response
      if (response.statusCode == 200) {
        print('Notifications marked as seen successfully');
      } else {
        print('Failed to mark notifications as seen: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notifications as seen: $e');
    }
  }

  void fetchNotifications() {
    setState(() {
      friendRequests = fetchFriendRequests();
      notificationsList = fetchAllNotifications();
      combinedNotifications = _getCombinedNotifications();
    });
  }

  Future<List<dynamic>> fetchAllNotifications() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-notifications?page=1&limit=10'),
        headers: {
          'Content-Type': 'application/json',
          'token': userProvider.userToken ?? '', // Assuming token is a Bearer token
          'userId': userProvider.userId ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("oyeyeyeyeyeyeye");
        return data['notifications'] ?? [];
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<List<dynamic>> _getCombinedNotifications() async {
    try {
      final requests = await friendRequests;
      final notifications = await notificationsList;

      // Prepare friend requests with uniform format
      final formattedRequests = requests.map((request) {
        return {
          '_id': request['_id'],
          'type': 'friendRequest',
          'sender': {
            'id': request['_id'],
            'name': request['name'],
            'profilePic': request['profilePic']
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch, // Use current time if no timestamp available
          'requestData': request
        };
      }).toList();

      // Combine both lists
      List<dynamic> combined = [
        ...formattedRequests,
        ...notifications
      ];

      // Sort by timestamp in descending order (newest first)
      combined.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      return combined;
    } catch (e) {
      print('Error combining notifications: $e');
      return [];
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
    } catch (e) {}
  }

  Future<void> _refreshNotifications() async {
    fetchNotifications();
  }

  void handleAccept(String id) async {
    await acceptRequest(id);
    await _startChat(id);
    fetchNotifications();
  }

  void handleDecline(String id) async {
    await rejectRequest(id);
    fetchNotifications();
  }

  String capitalizeEachWord(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
        appBar: AppBar(
          title: Text(
            "Notifications",
            style: GoogleFonts.roboto(fontSize: 18.sp),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomNavBarScreen(),
                ),
              );
            },
          ),
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.more_vert),
          //     onPressed: () {},
          //   ),
          // ],
        ),
        body: TabContainer(
          tabMaxLength: 100,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300,
          selectedTextStyle: GoogleFonts.roboto(
            fontSize: 18.sp,
          ),
          unselectedTextStyle: GoogleFonts.roboto(
            fontSize: 16.sp,
          ),
          tabs: [
            Text('All', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Requests', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Calls', style: TextStyle(fontWeight: FontWeight.bold))
          ],
          children: [
            combinedNotificationsList(context),
            friendrequestlist(context),
            callloglist(context)
          ],
        ));
  }

  Container combinedNotificationsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkGradient
              : [
                  Colors.white,
                  Colors.white
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
        backgroundColor: Colors.purple,
        child: FutureBuilder<List<dynamic>>(
          future: combinedNotifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ShimmerList(
                isNotification: true,
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No Notifications",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemType = item['type'];

                // Format timestamp to readable date
                final timestamp = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
                final formattedTime = DateFormat('MMM d, h:mm a').format(timestamp);

                // If it's a friend request
                if (itemType == 'friendRequest') {
                  final request = item['requestData'];
                  final String profile = item['sender']['profilePic'];
                  return GestureDetector(
                    onTap: () {
                      print(item);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: item['_id'])));
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8.r),
                      child: Card(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
                        // borderOnForeground: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(profile),
                            radius: 24.r,
                          ),
                          title: Text(
                            "${request['name']}",
                            style: GoogleFonts.roboto(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  handleAccept(request['_id']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF7400A5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 12.w,
                                  ),
                                ),
                                child: Text(
                                  "+ Accept",
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 10.w,
                                  ),
                                ),
                                onPressed: () {
                                  handleDecline(request['_id']);
                                },
                                child: Text(
                                  "Decline",
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 12.sp, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (itemType == 'call') {
                  final String notificationText = capitalizeEachWord(item['details']['notificationText']) ?? 'New notification';
                  final String callby = capitalizeEachWord(item['sender']['name']) ?? '';
                  final String typeofcall = capitalizeEachWord(item['details']['callDetails']['type']) ?? '';
                  String profile = '';
                  if (item['sender']['profilePic'] != null) {
                    profile = item['sender']['profilePic'];
                  }

                  return Padding(
                    padding: EdgeInsets.all(2.r),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(userId: item['sender']['id']),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundImage: profile == '' ? AssetImage('assets/avatar/8.png') : NetworkImage(profile),
                            radius: 24.r,
                          ),
                        ),
                        title: Text(
                          '$typeofcall $notificationText - $callby',
                          style: GoogleFonts.roboto(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        trailing: itemType == 'like'
                            ? Icon(Icons.favorite, color: Colors.red)
                            : itemType == 'comment'
                                ? Icon(Icons.comment, color: Color(0xFF7400A5))
                                : null,
                      ),
                    ),
                  );
                }
                // If it's a regular notification (like, comment, etc.)

                else {
                  final String notificationText = capitalizeEachWord(item['details']['notificationText']) ?? 'New notification';
                  final String content = item['details']['content'] ?? '';
                  final String profile = item['sender']['profilePic'] ?? '';
                  final feedid = item['details']['entity']['feedId'];

                  return Padding(
                    padding: EdgeInsets.all(2.r),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
                      // borderOnForeground: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailsScreen(feedId: feedid)));
                        },
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(userId: item['sender']['id']),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(profile),
                              radius: 24.r,
                            ),
                          ),
                          title: Text(
                            notificationText,
                            style: GoogleFonts.roboto(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (content.isNotEmpty)
                                Text(
                                  content,
                                  style: TextStyle(fontSize: 12.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          trailing: itemType == 'like'
                              ? Icon(Icons.favorite, color: Colors.red)
                              : itemType == 'comment'
                                  ? Icon(Icons.comment, color: Color(0xFF7400A5))
                                  : null,
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Container callloglist(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkGradient
              : [
                  Colors.white,
                  Colors.white
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
        backgroundColor: Colors.purple,
        child: FutureBuilder<List<dynamic>>(
          future: getCallLogs(), // Filtered call logs
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No Calls",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            final callItems = snapshot.data!;

            return ListView.builder(
              itemCount: callItems.length,
              itemBuilder: (context, index) {
                final item = callItems[index];

                // Debugging: Print the received call data
                print('Call Item: ${item}');

                final timestamp = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
                final formattedTime = DateFormat('MMM d, h:mm a').format(timestamp);

                final String notificationText = capitalizeEachWord(item['details']['notificationText']) ?? 'New call';
                final String callBy = capitalizeEachWord(item['sender']['name']) ?? '';
                final String callType = capitalizeEachWord(item['details']['callDetails']['type']) ?? '';

                String profile = item['sender']['profilePic'] ?? '';

                return Padding(
                  padding: EdgeInsets.all(2.r),
                  child: Card(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: item['sender']['id']),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage: (profile.isNotEmpty) ? NetworkImage(profile) : AssetImage('assets/avatar/8.png') as ImageProvider,
                          radius: 24.r,
                        ),
                      ),
                      title: Text(
                        '$callType Call - $callBy',
                        style: GoogleFonts.roboto(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                        ),
                      ),
                      subtitle: Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Function to filter only calls from combinedNotifications
  Future<List<dynamic>> getCallLogs() async {
    final allNotifications = await combinedNotifications;
    final callLogs = allNotifications.where((item) => item['type'] == 'call').toList();
    

    // Debugging: Print the number of filtered calls
    print('Filtered Call Logs Count: ${callLogs.length}');
    return callLogs;
  }

  Container friendrequestlist(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkGradient
              : [
                  Colors.white,
                  Colors.white
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
        backgroundColor: Colors.purple,
        child: FutureBuilder<List<dynamic>>(
          future: friendRequests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No New Requests",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            final requests = snapshot.data!;
            final items = snapshot.data!;
            // return ListView.builder(
            //   itemCount: requests.length,
            //   itemBuilder: (context, index) {
            //     final request = requests[index];
            //     final item = items[index];
            //     String profile = 'https://example.com/default-profile.png'; // Default image
            //     if (item != null && item['sender'] != null && item['sender']['profilePic'] != null) {
            //       profile = item['sender']['profilePic'];
            //     }
            //     return Padding(
            //       padding: EdgeInsets.all(8.r), // Responsive padding
            //       child: Card(
            //         color: Colors.transparent,
            //         // borderOnForeground: true,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(15.r),
            //           side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
            //         ),
            //         child: ListTile(
            //           leading: GestureDetector(
            //             // onTap: () {
            //             //   Navigator.pushReplacement(
            //             //     context,
            //             //     MaterialPageRoute(
            //             //       builder: (context) => UserProfileScreen(userId: item['sender']['id']),
            //             //     ),
            //             //   );
            //             // },
            //             child: CircleAvatar(
            //               backgroundImage: NetworkImage(profile),
            //               radius: 24.r,
            //             ),
            //           ),
            //           title: Text(
            //             "${request['name']}",
            //             overflow: TextOverflow.ellipsis,
            //             style: GoogleFonts.roboto(
            //               color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            //               fontWeight: FontWeight.w400,

            //               fontSize: 16.sp, // Responsive text size
            //             ),
            //           ),
            //           trailing: Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               ElevatedButton(
            //                 onPressed: () {
            //                   handleAccept(request['_id']);
            //                 },
            //                 style: ElevatedButton.styleFrom(
            //                   backgroundColor: Color(0xFF7400A5),
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(20.r),
            //                   ),
            //                   padding: EdgeInsets.symmetric(
            //                     vertical: 8.h,
            //                     horizontal: 12.w,
            //                   ), // Responsive padding
            //                 ),
            //                 child: Text(
            //                   "+ Accept",
            //                   style: GoogleFonts.roboto(
            //                     color: Colors.white,
            //                     fontSize: 12.sp, // Responsive font size
            //                   ),
            //                 ),
            //               ),
            //               SizedBox(width: 8.w), // Responsive spacing
            //               OutlinedButton(
            //                 style: OutlinedButton.styleFrom(
            //                   side: BorderSide(color: Colors.red),
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(20),
            //                   ),
            //                   padding: EdgeInsets.symmetric(
            //                     vertical: 8.h,
            //                     horizontal: 10.w,
            //                   ),
            //                 ),
            //                 onPressed: () {
            //                   handleDecline(request['_id']);
            //                 },
            //                 child: Text(
            //                   "Decline",
            //                   style: TextStyle(
            //                     color: Colors.red,
            //                     fontSize: 12.sp, // Responsive font size
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     );
            //   },
            // );
            
            // final item = items[index];
            
            
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemType = item['type'];
                final request = items[index];
                final String profile = request['profilePic'];
                // Format timestamp to readable date
                final timestamp = DateTime.now();
                final formattedTime = DateFormat('MMM d, h:mm a').format(timestamp);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: request['_id'])));
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.r),
                    child: Card(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
                      // borderOnForeground: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                        side: BorderSide(color: Color(0xFF7400A5), width: 1.5),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(profile),
                          radius: 24.r,
                        ),
                        title: Text(
                          "${request['name']}",
                          style: GoogleFonts.roboto(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                handleAccept(request['_id']);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7400A5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 8.h,
                                  horizontal: 12.w,
                                ),
                              ),
                              child: Text(
                                "+ Accept",
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 8.h,
                                  horizontal: 10.w,
                                ),
                              ),
                              onPressed: () {
                                handleDecline(request['_id']);
                              },
                              child: Text(
                                "Decline",
                                style: TextStyle(color: Colors.red, fontSize: 12.sp, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );

          },
        ),
      ),
    );
  }
}
