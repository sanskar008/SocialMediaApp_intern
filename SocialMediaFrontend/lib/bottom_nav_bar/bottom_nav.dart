import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassycontainer/glassycontainer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/explore_screen.dart';
import 'package:socialmedia/bottom_nav_bar/post_Screen.dart';
import 'package:socialmedia/main.dart';
import 'package:socialmedia/users/live_stream_screen1.dart';
import 'package:socialmedia/users/notification.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class BottomNavBarScreen extends StatefulWidget {
  @override
  _BottomNavBarScreenState createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  bool _notificationDisplayed = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      await userProvider.loadUserData(); // 🔹 Load user data first
      await updateFCMToken(); // 🔹 Then call your function
    });
  }

  Future<void> updateFCMToken() async {
    final url = Uri.parse('${BASE_URL}api/edit-profile');
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final token = userProvider.userToken;
    final userId = userProvider.userId;
    print('edit porifile callhhua');
    try {
      // Get the FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $fcmToken");

      if (fcmToken == null) {
        print('FCM token is null. Cannot proceed.');
        return;
      }

      // Create a MultipartRequest
      final request = http.MultipartRequest('PUT', url)
        ..headers.addAll({
          'userId': userId!,
          'token': token!,
        });

      // Add only fcmToken to the request
      request.fields['fcmToken'] = fcmToken;

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('FCM token updated successfully.');
        print('Response: $responseBody');
      } else {
        final responseBody = await response.stream.bytesToString();
        print(
            'Failed to update FCM token. Status Code: ${response.statusCode}');
        print('Error: $responseBody');
      }
    } catch (e) {
      print('An error occurred while updating FCM token: $e');
    }
  }

  void initializeFCMListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 New Notification Received");

      // Print the full message payload
      print("🔹 Full Message: ${message.toMap()}");

      // Print notification part (if sent via notification block)
      print("🔸 Title: ${message.notification?.title}");
      print("🔸 Body: ${message.notification?.body}");

      // Print custom data payload
      print("📦 Data: ${message.data}");

      var androidDetails = const AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notificationn',
      );

      var iosDetails = const DarwinNotificationDetails();
      var generalDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      localNotifications.show(
        0,
        message.notification?.title ?? 'No Title',
        message.notification?.body ?? 'No Body',
        generalDetails,
      );
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print("Notification clicked: ${message.notification?.title}");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("User clicked notification: ${message.notification?.title}");
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // List of pages to be displayed in the body
  final List<Widget> _pages = [
    ExplorePage(),
    ChatScreen(),
    DarkScreenWithBottomModal(),
    NotificationsPage(),
    user_profile(),
  ];

  bool showNotificationDot = false;
  Timer? _timer;

  int _selectedIndex = 0; // Index to track the selected tab

  // This function is triggered when a tab is tapped
  void _onItemTapped(int index) {
    if (index == 2) {
    showCustomBottomSheet(context); // Open your custom modal here
  } else {
    setState(() {
      _selectedIndex = index;
    });
  }
  }

  void showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.lightText
          : AppColors.darkText,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context);
            return false;
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Choose Option",
                        style: GoogleFonts.poppins(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PostScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.darkText,
                      side: BorderSide(
                        color: Color(0xFF7400A5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Make a Post",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
// Go Live Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LiveStreamScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromARGB(19, 255, 255, 255)
                              : AppColors.darkText,
                      side: BorderSide(
                        color: Colors.greenAccent,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Go Live",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (Navigator.canPop(context)) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color activeColor = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFF7400A5)
        : Colors.deepPurpleAccent;
    final Color inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;

    // Determine background color based on theme
    final Color bgColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);

    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      extendBody: true, // This allows content to be visible behind the navigation bar
      bottomNavigationBar: Stack(
        children: [
          // Blurred background
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SafeArea(
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Navigation items
          SizedBox(
            height: 80.h,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                      icon: Iconsax.home,
                      label: '',
                      index: 0,
                      isnotif: false,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor),
                  _buildNavItem(
                      icon: Iconsax.message,
                      label: '',
                      index: 1,
                      isnotif: false,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor),
                  _buildNavItem(
                      icon: Iconsax.add_circle,
                      label: '',
                      index: 2,
                      isnotif: false,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor),
                  _buildNavItem(
                      icon: Iconsax.notification,
                      label: '',
                      index: 3,
                      isnotif: true,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor),
                  _buildNavItem(
                      icon: Icons.circle,
                      label: '',
                      index: 4,
                      isnotif: true,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildNavItem(
  //     {required IconData icon,
  //     required String label,
  //     required int index,
  //     required bool isnotif,
  //     required Color activeColor,
  //     required Color inactiveColor}) {
  //   bool isSelected = _selectedIndex == index;

  //   return Expanded(
  //     child: InkWell(
  //       onTap: () => _onItemTapped(index),
  //       splashColor: activeColor.withOpacity(0.1),
  //       highlightColor: activeColor.withOpacity(0.05),
  //       child: ZoomTapAnimation(
  //         onTap: () => _onItemTapped(index),
  //         child: Container(
  //           height: double.infinity,
  //           child: Stack(
  //             alignment: Alignment.center,
  //             clipBehavior: Clip.none,
  //             children: [
  //               Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Icon(
  //                     icon,
  //                     color: isSelected ? activeColor : Colors.white,
  //                     size: 30.sp,
  //                   ),
  //                   SizedBox(height: 4),
  //                   Text(
  //                     label,
  //                     style: GoogleFonts.roboto(
  //                       color: isSelected ? activeColor : inactiveColor,
  //                       fontSize: 12.sp,
  //                       fontWeight:
  //                           isSelected ? FontWeight.bold : FontWeight.normal,
  //                     ),
  //                     overflow: TextOverflow.ellipsis,
  //                     maxLines: 1,
  //                     softWrap: false,
  //                   ),
  //                 ],
  //               ),
  //               if (isnotif && showNotificationDot)
  //                 Positioned(
  //                   top: 10.h,
  //                   right: MediaQuery.of(context).size.width * 0.09,
  //                   child: Container(
  //                     width: 10.w,
  //                     height: 10.h,
  //                     decoration: BoxDecoration(
  //                       color: Colors.red,
  //                       shape: BoxShape.circle,
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isnotif, required Color activeColor, required Color inactiveColor}) {
    bool isSelected = _selectedIndex == index;
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    // Special handling for profile icon (index 4)
    if (index == 4) {
      return Expanded(
        child: InkWell(
          onTap: () => _onItemTapped(index),
          splashColor: activeColor.withOpacity(0.1),
          highlightColor: activeColor.withOpacity(0.05),
          child: ZoomTapAnimation(
            onTap: () => _onItemTapped(index),
            child: Container(
             // height: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18.sp,
                        backgroundColor: isSelected ? activeColor : Colors.transparent,
                        child: CircleAvatar(
                          radius: 15.3.sp,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          child: CircleAvatar(
                            radius: 13.sp,
                            backgroundImage: userProvider.userProfile != null ? NetworkImage(userProvider.userProfile!) : const AssetImage('assets/avatar/2.png') as ImageProvider,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        label,
                        style: GoogleFonts.roboto(
                          color: isSelected ? activeColor : inactiveColor,
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ],
                  ),
                  if (isnotif && showNotificationDot)
                    Positioned(
                      top: 10.h,
                      right: MediaQuery.of(context).size.width * 0.09,
                      child: Container(
                        width: 10.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Original implementation for other icons
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        splashColor: activeColor.withOpacity(0.1),
        highlightColor: activeColor.withOpacity(0.05),
        child: ZoomTapAnimation(
          onTap: () => _onItemTapped(index),
          child: Container(
            height: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Theme.of(context).brightness == Brightness.dark ?  (isSelected ? activeColor : Colors.white) : (isSelected ? activeColor : Colors.black),
                      size: 30.sp,
                    ),
                    SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.roboto(
                        color: isSelected ? activeColor : inactiveColor,
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ],
                ),
                if (isnotif && showNotificationDot)
                  Positioned(
                    top: 10.h,
                    right: MediaQuery.of(context).size.width * 0.09,
                    child: Container(
                      width: 10.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// DarkScreenWithBottomModal class remains unchanged
class DarkScreenWithBottomModal extends StatefulWidget {
  const DarkScreenWithBottomModal({Key? key}) : super(key: key);

  @override
  _DarkScreenWithBottomModalState createState() =>
      _DarkScreenWithBottomModalState();
}

class _DarkScreenWithBottomModalState extends State<DarkScreenWithBottomModal> {
  @override
  void initState() {
    super.initState();
    // Delay to show the modal after the screen is loaded
    Future.delayed(Duration(milliseconds: 500), () {
      showCustomBottomSheet(context);
    });
  }

  void showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.lightText
          : AppColors.darkText,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottomNavBarScreen()),
            );
            return false;
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Choose Option",
                        style: GoogleFonts.poppins(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBarScreen())),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PostScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.darkText,
                      side: BorderSide(
                        color: Color(0xFF7400A5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Make a Post",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
// Go Live Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LiveStreamScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromARGB(19, 255, 255, 255)
                              : AppColors.darkText,
                      side: BorderSide(
                        color: Colors.greenAccent,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Go Live",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (Navigator.canPop(context)) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : Colors.white38,
        // Dark background
      ),
    );
  }
}





// import 'dart:async';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:glassycontainer/glassycontainer.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:in_app_notification/in_app_notification.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/explore_screen.dart';
// import 'package:socialmedia/bottom_nav_bar/post_Screen.dart';
// import 'package:socialmedia/users/live_stream_screen1.dart';
// import 'package:socialmedia/users/notification.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:socialmedia/utils/colors.dart';
// import 'package:socialmedia/utils/constants.dart';

// class BottomNavBarScreen extends StatefulWidget {
//   @override
//   _BottomNavBarScreenState createState() => _BottomNavBarScreenState();
// }

// class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
//   bool _notificationDisplayed = false;
//   @override
//   void initState() {
//     super.initState();
//     // Delay to show the modal after the screen is loaded
//     _startPolling();
//   }

//   void _startPolling() {
//     _timer = Timer.periodic(Duration(seconds: 5), (timer) {
//       _checkNotifications();
//     });
//   }

//   Future<void> _checkNotifications() async {
//     try {
//       // Fetch userId and token from SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? userId = prefs.getString('user_id');
//       String? token = prefs.getString('user_token');

//       if (userId == null || token == null) {
//         print('User ID or Token is missing');
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('${BASE_URL}api/notificationDot'),
//         headers: {
//           'Content-Type': 'application/json',
//           'token': token,
//           'userId': userId, // Pass userId in headers
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         print('Notification API called');

//         bool shouldShowDot = data['hasUnseen'] ?? false;

//         if (mounted) {
//           setState(() {
//             showNotificationDot = shouldShowDot;
//           });
//         }

//         // Reset the _notificationDisplayed flag if there are no unseen notifications.
//         if (!shouldShowDot && _notificationDisplayed) {
//           _notificationDisplayed = false;
//         }

//         // Only show notification if there are unseen notifications and if we haven't already shown one.
//         if (shouldShowDot && mounted && !_notificationDisplayed) {
//           Future.microtask(() {
//             try {
//               final navigatorContext = Navigator.of(context).context;
//               InAppNotification.show(
//                 context: navigatorContext,
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.purpleAccent,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Text(
//                     'You have a new notification!',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                 ),
//                 duration: const Duration(seconds: 3),
//               );
//               // Mark that we've displayed a notification for the current unseen state.
//               _notificationDisplayed = true;
//             } catch (e) {
//               print('Error showing notification: $e');
//             }
//           });
//         }
//       } else {
//         print('Failed to fetch notifications: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching notifications: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//   PageController _pageController = PageController();
//   Set<int> _visitedTabs = {
//     0
//   };
//   // List of pages to be displayed in the body
//   final List<Widget> _pages = [
//     DarkScreenWithBottomModal(),
//     ExplorePage(),
//     ChatScreen(),
//     NotificationsPage(),
//   ];

//   bool showNotificationDot = false;
//   Timer? _timer;

//   int _selectedIndex = 1; // Index to track the selected tab

//   // This function is triggered when a tab is tapped
//   void _onItemTapped(int index) {
//     bool firstVisit = !_visitedTabs.contains(index);
//     setState(() {
//       _selectedIndex = index;
//       _visitedTabs.add(index);
//     });
//     _pageController.jumpToPage(index);
//   }

  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_selectedIndex], // Display the selected page
//       bottomNavigationBar: GlassyContainer(
//         height: 75,
//         width: double.infinity,
//         color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade900,
//         blur: 90,
//         child: Padding(
//           padding: const EdgeInsets.only(left: 16, right: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildNavItem(icon: Icons.add_circle_rounded, label: 'Post', index: 0, isnotif: false),
//               _buildNavItem(icon: Icons.explore, label: 'Explore', index: 1, isnotif: false),
//               _buildNavItem(icon: Icons.chat, label: 'Activity', index: 2, isnotif: false),
//               _buildNavItem(icon: Icons.notifications, label: 'Notifications', index: 3, isnotif: true),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isnotif}) {
//     bool isSelected = _selectedIndex == index;
//     return isnotif == false
//         ? Expanded(
//             // Use Expanded to distribute space evenly
//             child: GestureDetector(
//               behavior: HitTestBehavior.opaque, // Increase entire area's touch sensitivity
//               onTap: () => _onItemTapped(index),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     icon,
//                     color: isSelected
//                         ? Theme.of(context).brightness == Brightness.dark
//                             ? Colors.purple
//                             : Colors.deepPurpleAccent
//                         : Theme.of(context).brightness == Brightness.dark
//                             ? Colors.white70
//                             : Colors.black54,
//                     size: 30,
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     label,
//                     style: GoogleFonts.roboto(
//                       color: isSelected
//                           ? Theme.of(context).brightness == Brightness.dark
//                               ? Colors.purple
//                               : Colors.deepPurpleAccent
//                           : Theme.of(context).brightness == Brightness.dark
//                               ? Colors.white70
//                               : Colors.black54,
//                       fontSize: 12.sp,
//                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )
//         : Expanded(
//             // Use Expanded to distribute space evenly
//             child: GestureDetector(
//               behavior: HitTestBehavior.opaque,
//               onTap: () => _onItemTapped(index),
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Column(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         icon,
//                         color: isSelected
//                             ? Theme.of(context).brightness == Brightness.dark
//                                 ? Colors.purple
//                                 : Colors.deepPurpleAccent
//                             : Theme.of(context).brightness == Brightness.dark
//                                 ? Colors.white70
//                                 : Colors.black54,
//                         size: 30,
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         label,
//                         style: GoogleFonts.roboto(
//                           color: isSelected
//                               ? Theme.of(context).brightness == Brightness.dark
//                                   ? Colors.purple
//                                   : Colors.deepPurpleAccent
//                               : Theme.of(context).brightness == Brightness.dark
//                                   ? Colors.white70
//                                   : Colors.black54,
//                           fontSize: 12.sp,
//                           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (showNotificationDot)
//                     Positioned(
//                       top: 2,
//                       right: 46,
//                       child: Container(
//                         width: 10,
//                         height: 8,
//                         decoration: BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//   }
// }

// // DarkScreenWithBottomModal class remains unchanged
// class DarkScreenWithBottomModal extends StatefulWidget {
//   const DarkScreenWithBottomModal({Key? key}) : super(key: key);

//   @override
//   _DarkScreenWithBottomModalState createState() => _DarkScreenWithBottomModalState();
// }

// class _DarkScreenWithBottomModalState extends State<DarkScreenWithBottomModal> {
//   @override
//   void initState() {
//     super.initState();
//     // Delay to show the modal after the screen is loaded
//     Future.delayed(Duration(milliseconds: 500), () {
//       showCustomBottomSheet(context);
//     });
//   }

//   void showCustomBottomSheet(BuildContext context) {
//     showModalBottomSheet(
//       backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async {
//             Navigator.pushReplacementReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => BottomNavBarScreen()),
//             );
//             return false;
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "What’s Plan",
//                       style: GoogleFonts.roboto(
//                         fontSize: 20.sp,
//                         fontWeight: FontWeight.w500,
//                         color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
//                       ),
//                     ),
//                     OutlinedButton(
//                       onPressed: () => Navigator.pushReplacementReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen())),
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(color: Colors.grey),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: Text(
//                         "cancel",
//                         style: GoogleFonts.roboto(
//                           color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 // Make a Post Button
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (context) => PostScreen()),
//                     );
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[900],
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.post_add,
//                           color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
//                         ),
//                         const SizedBox(width: 10),
//                         Text(
//                           "Make a Post",
//                           style: GoogleFonts.roboto(
//                             fontSize: 16,
//                             color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.darkText,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 // Go Live Button
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         // builder: (context) => LiveStreamScreen(),
//                         builder: (context) => BottomNavBarScreen(),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     width: double.infinity,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[900],
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.wifi, color: Colors.greenAccent),
//                         const SizedBox(width: 10),
//                         Text(
//                           "Go Live",
//                           style: GoogleFonts.roboto(
//                             fontSize: 16,
//                             color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.darkText,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         Navigator.pushReplacementReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : Colors.white38,
//         // Dark background
//       ),
//     );
//   }
// }