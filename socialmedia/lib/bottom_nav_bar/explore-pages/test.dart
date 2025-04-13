// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/bottom_nav_bar/explore-pages/searchpage.dart';
// import 'package:socialmedia/users/Bondchat.dart';

// import 'package:socialmedia/users/profile_screen.dart';
// import 'package:socialmedia/utils/colors.dart';

// class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
//   CustomAppBar({
//     super.key,
//   });

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
  
//   @override
//   // TODO: implement preferredSize
//   Size get preferredSize => throw UnimplementedError();
// }

// class _CustomAppBarState extends State<CustomAppBar> {
  
  
//   @override
//   Size get preferredSize => Size.fromHeight(70);

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProviderall>(context, listen: false);
//     return ClipRRect(
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           height: 110,
//           decoration: BoxDecoration(
//               color: Theme.of(context).brightness == Brightness.dark
//                   ? Colors.black45.withOpacity(0.7)
//                   : Colors.white),
//           child: AppBar(
//             automaticallyImplyLeading: false,
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             flexibleSpace: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     SizedBox(
//                       width: 1.9.w,
//                     ),
//                     Row(
//                       children: [
//                         InkWell(
//                           onTap: () {
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => user_profile()));
//                           },
//                           child: Container(
//                             //height: 36.h,
//                             width: 36.w,
//                             decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(41.sp)),
//                             child: CircleAvatar(
//                                 backgroundImage:
//                                     NetworkImage(userProvider.userProfile!)
//                                 //radius: 41,
//                                 ),
//                           ),
//                         ),
//                         SizedBox(width: 8.w),
//                         Text.rich(TextSpan(
//                             text: 'BondBridge',
//                             style: GoogleFonts.leagueSpartan(
//                                 foreground: Paint()
//                                   ..shader = LinearGradient(
//                                     colors: [
//                                       Color(0xFF8A23F5), // Deep purple
//                                       Color(0xFFB83AF8), // Bright purple
//                                     ],
//                                   ).createShader(
//                                       Rect.fromLTWH(40.0, 0.0, 70.0, 120.0)),
//                                 fontSize: 24.sp,
//                                 fontWeight: FontWeight.w500))),
//                         /*SizedBox(
//                           height: 80,
//                             width: 50,
//                             child: Image.asset('assets/images/BondBridge_finaltxt.png' , fit: BoxFit.),
//                         )*/
//                       ],
//                     ),
//                     Spacer(),
//                     Row(
//                       children: [
//                         Container(
//                           //  height: 31.h,
//                           width: 120.w,

//                           child: FittedBox(
//                             child: Padding(
//                               padding: const EdgeInsets.all(2.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   InkWell(
//                                       onTap: () {
//                                         // Navigator.push(
//                                         //     context,
//                                         //     MaterialPageRoute(
//                                         //         builder: (context) =>
//                                         //             ChatScreen()));
//                                       },
//                                       child: Theme.of(context).brightness ==
//                                               Brightness.dark
//                                           ? Image.asset(
//                                               'assets/images/last_finalbondchat.png',
//                                               fit: BoxFit.contain,
//                                             )
//                                           : Image.asset(
//                                               'assets/images/bondchatwhite.png',
//                                               fit: BoxFit.contain,
//                                             )),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 2.4.w),
//                         IconButton(
//                           onPressed: () {
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => UserSearchScreen()));
//                           },
//                           icon: Icon(
//                             Icons.search,
//                             color:
//                                 Theme.of(context).brightness == Brightness.dark
//                                     ? Colors.grey[300]
//                                     : Colors.black,
//                             size: 25.sp,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


