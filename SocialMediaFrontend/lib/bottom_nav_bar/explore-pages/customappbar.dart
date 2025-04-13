import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/searchpage.dart';
import 'package:socialmedia/users/Bondchat.dart';
import 'package:socialmedia/users/profile_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late UserProviderall userProvider;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {}); // Refresh UI after loading data
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black45.withOpacity(0.7)
                : Colors.white,
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // InkWell(
                    //   onTap: () {
                    //     Navigator.pushReplacement(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (context) => user_profile()),
                    //     );
                    //   },
                    //   child: CircleAvatar(
                    //     backgroundImage: userProvider.userProfile != null
                    //         ? NetworkImage(userProvider.userProfile!)
                    //         : const AssetImage(
                    //             'assets/avatar/2.png'), // Default image
                    //   ),
                    // ),
                    Row(
                      children: [
                        Padding(
                          padding:  EdgeInsets.only(bottom: 5.0.h),
                          child: SizedBox(
                                height: 40.h,
                                child: SvgPicture.asset(
                                  'assets/images/bondlogog.svg', // Use the SVG file path
                                  width: 10.w, // Adjust size as needed
                                  height: 35.h,
                                )
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text.rich(
                          TextSpan(
                            text: "BondBridge",
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 28.sp, // Adjust based on your needs
                              fontWeight: FontWeight.w800,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: [
                                    Color(0xFF3B01B7), // Dark purple (bottom left)
                                    Color(0xFF5E00FF), // Purple
                                    Color(0xFFBA19EB), // Pink-purple
                                    Color(0xFFDD0CC8), // Pink (top right)
                                  ],
                                  // stops: [1.0, 0.69, 0.34, 0.0]
                                ).createShader(
                                  const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    Spacer(),
                    Row(
                      children: [
                        Container(
                          //  height: 31.h,
                          width: 140.w,

                          child: FittedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    BondChatScreen()));
                                      },
                                      child: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? SvgPicture.asset(
                                              'assets/images/bondchatsvggg.svg', // Ensure correct asset path
                                              width: 180.w, // Set desired width
                                              height: 180.h, // Set desired height
                                              //fit: BoxFit.contain,
                                            )
                                          : SvgPicture.asset(
                                              'assets/images/bondchatlogowithboundary.svg', // Ensure correct asset path
                                              width: 180.w, // Set desired width
                                              height: 180.h, // Set desired height
                                              //fit: BoxFit.contain,
                                            )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.4.w),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserSearchScreen()),
                            );
                          },
                          icon: Icon(Icons.search),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
