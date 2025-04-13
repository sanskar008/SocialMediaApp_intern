// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:socialmedia/api_service/user_provider.dart';
// import 'package:socialmedia/pages/onboarding_screens/avatar_selection.dart';
// import 'package:socialmedia/pages/onboarding_screens/avatar_selection_anony.dart';
// import 'package:socialmedia/pages/onboarding_screens/interests.dart';
// import 'package:socialmedia/users/editprofilescreens/avatar_selec.dart';
// import 'package:socialmedia/users/editprofilescreens/interetsforedit.dart';
// import 'package:socialmedia/users/profile_screen.dart';
// import 'package:socialmedia/utils/constants.dart';

// class EditProfileScreen extends StatefulWidget {
//   final String avatar;
//   final List<String> selectedInterests;

//   const EditProfileScreen({super.key, required this.avatar, required this.selectedInterests});

//   @override
//   _EditProfileScreenState createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();
//   late UserProviderall userProvider;

//   bool _isLoading = false;

//   Future<void> _updateProfile() async {
//     final String userId = "user_id"; // Replace with actual user ID
//     final String token = "user_token"; // Replace with actual token
//     final userProvider = Provider.of<UserProviderall>(context, listen: false);

//     Map<String, dynamic> formData = {};

//     if (_usernameController.text.isNotEmpty) {
//       formData["name"] = _usernameController.text;
//     }
//     if (_emailController.text.isNotEmpty) {
//       formData["bio"] = _emailController.text;
//     }
//     if(widget.avatar != ''){
//       formData["avatar"] = widget.avatar.toString();
//     }

//     if (widget.selectedInterests.isNotEmpty) {
//     formData["interests"] = jsonEncode(widget.selectedInterests); // Convert Set to List
// }

//     print(widget.avatar);
//     print(widget.selectedInterests);
//     print(userProvider.userId!);
//     print(userProvider.userToken!);

//     if (formData.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Fill at least one field to update")),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final response = await http.put(
//         Uri.parse("${BASE_URL}api/edit-profile"),
//         headers: {
//           "Content-Type": "application/json",
//           "token": userProvider.userToken!,
//           "userId": userProvider.userId!,
//         },
//         body: jsonEncode(formData),
//       );

//       if (response.statusCode == 200) {
//         Fluttertoast.showToast(
//         msg: "Profile updated successfully",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.green,
//         textColor: Colors.white,
//       );
//       print(widget.selectedInterests);
//       Navigator.pushReplacementReplacement(context, MaterialPageRoute(builder: (context)=> user_profile()));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to update profile")),
//         );
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Failed to update profile",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void initState() {
//     // TODO: implement initState
//     void initState() {
//     super.initState();
//     userProvider = Provider.of<UserProviderall>(context, listen: false);
//     userProvider.loadUserData().then((_) {
//       setState(() {}); // Refresh UI after loading data
//     });
//   }

//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: TextButton(
//               onPressed: () => Navigator.pop(context),
//               style: TextButton.styleFrom(
//                 side: const BorderSide(color: Colors.red),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 "cancel", // Keeping typo as per the images
//                 style: GoogleFonts.roboto(color: Colors.red, fontSize: 14),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Container(

//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.black, Color(0xFF0A0E21)], // Black to dark blue
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Edit Profile",
//                 style: GoogleFonts.roboto(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "What should we call you?",
//                 style: GoogleFonts.roboto(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               _buildTextField("user name", _usernameController),
//               const SizedBox(height: 16),
//               _buildTextField("bio", _emailController),
//               const SizedBox(height: 16),
//               _buildButton('Choose Avatar', (){
//                 Navigator.pushReplacementReplacement(context, MaterialPageRoute(builder: (context)=> AvatarSelectionScreenforsetting()));
//               } ,widget.avatar ),
//               const SizedBox(height: 16),
//               _buildButtonForInterest('Choose Interests', (){
//                 Navigator.pushReplacementReplacement(context, MaterialPageRoute(builder: (context)=> Interestsforsetting(avatar: widget.avatar,)));
//               } ,widget.selectedInterests ),

//               const Spacer(),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _updateProfile,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 100, vertical: 16),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.black)
//                       : Text(
//                           "save",
//                           style: GoogleFonts.roboto(
//                             fontSize: 16,
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String hint, TextEditingController controller,
//       {IconData? icon}) {
//     return TextField(
//       controller: controller,
//       style: GoogleFonts.roboto(color: Colors.white),
//       maxLines: null,
//       inputFormatters: [
//         LengthLimitingTextInputFormatter(150), // Limits input to 150 characters
//       ],
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: GoogleFonts.roboto(color: Colors.grey),
//         filled: true,
//         fillColor: Colors.black,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: Colors.grey),
//         ),
//         prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
//       ),
//     );
//   }

//   Widget _buildButton(
//   String text,
//   VoidCallback onPressed,
//   String imageUrl // Added imageUrl as an optional parameter
// ) {
//   return Column(
//     children: [
//       if (imageUrl != '') ...[
//         CircleAvatar(
//           radius: 40, // Adjust size
//           backgroundImage: NetworkImage(imageUrl),
//           backgroundColor: Colors.grey[800], // Placeholder color
//         ),
//         SizedBox(height: 8),
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: Colors.black,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey),
//           ),
//           child: Text(
//             'Avatar Selected',
//             style: GoogleFonts.roboto(
//               color: Colors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//         SizedBox(height: 10),
//       ],
//       ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.black,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(color: Colors.grey),
//           ),
//           padding: EdgeInsets.symmetric(vertical: 14), // Adjust padding
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               text,
//               style: GoogleFonts.roboto(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }

// Widget _buildButtonForInterest(
//   String text,
//   VoidCallback onPressed,
//   final List<String> selectedInterests // Takes selected interests as a parameter
// ) {
//   return Column(
//     children: [

//       ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.black,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(color: Colors.grey),
//           ),
//           padding: EdgeInsets.symmetric(vertical: 14), // Adjust padding
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               text,
//               style: GoogleFonts.roboto(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//       SizedBox(height: 20,),
//       if (selectedInterests.isNotEmpty) ...[
//         Wrap(
//           spacing: 10,
//           runSpacing: 8,
//           children: selectedInterests.map((interest) {
//             return Container(
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: Colors.deepPurpleAccent),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     interest,
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(width: 6),
//                   GestureDetector(
//                     onTap: () {
//                       // Handle interest removal
//                       selectedInterests.remove(interest);
//                     },
//                     child: Icon(Icons.close, color: Colors.deepPurpleAccent, size: 18),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//         SizedBox(height: 10),
//       ],
//     ],
//   );
// }

// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection_anony.dart';
import 'package:socialmedia/pages/onboarding_screens/interests.dart';
import 'package:socialmedia/users/editprofilescreens/avatar_selec.dart';
import 'package:socialmedia/users/editprofilescreens/interetsforedit.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  final String avatar;
  final List<String> selectedInterests;

  const EditProfileScreen({super.key, required this.avatar, required this.selectedInterests});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController(); // Renamed from _emailController for clarity
  late UserProviderall userProvider;
  String _currentAvatar = '';
  List<String> _currentInterests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
     // fetchUserData();
      setState(() {}); // Refresh UI after loading data
    });
     WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchProfile();
    });

    // Initialize with the values passed to the widget
    _currentAvatar = widget.avatar;
    _currentInterests = List.from(widget.selectedInterests);
  }

  Future<void> fetchProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userid = prefs.getString('user_id');
    final String? token = prefs.getString('user_token');

    if (userid == null || token == null) {
      print('User ID or token is missing');
      return;
    }

    final Uri url = Uri.parse('${BASE_URL}api/showProfile?other=$userid');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'userid': userid,
      'token': token,
    };

    try {
      final http.Response response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['result'] != null && responseData['result'] is List && responseData['result'].isNotEmpty) {
          final userDetails = responseData['result'][0];

          // Update the controllers with fetched data
          _usernameController.text = userDetails['name'] ?? '';
          _bioController.text = userDetails['bio'] ?? '';
          _currentAvatar = userDetails['profilePic'] ?? '';

          // Parse interests (assuming they come as a JSON string)
          if (userDetails['interests'] != null) {
            try {
              _currentInterests = List<String>.from(jsonDecode(userDetails['interests']));
            } catch (e) {
              print('Error parsing interests: $e');
              _currentInterests = [];
            }
          } else {
            _currentInterests = [];
          }

          setState(() {}); // Refresh the UI
        } else {
          print('No user details found in the response');
        }
      } else {
        print('Failed to fetch profile. Status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching profile: $error');
    }
  }



  Future<void> _updateProfile() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    Map<String, dynamic> formData = {};

    if (_usernameController.text.isNotEmpty) {
      formData["name"] = _usernameController.text;
    }
    if (_bioController.text.isNotEmpty) {
      formData["bio"] = _bioController.text;
    }
    if (_currentAvatar.isNotEmpty) {
      formData["avatar"] = _currentAvatar;
    }

    if (_currentInterests.isNotEmpty) {
      formData["interests"] = jsonEncode(_currentInterests);
    }

    if (formData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text("Fill at least one field to update"))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse("${BASE_URL}api/edit-profile"),
        headers: {
          "Content-Type": "application/json",
          "token": userProvider.userToken!,
          "userId": userProvider.userId!,
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Profile updated successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => user_profile()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Center(child: Text("Failed to update profile"))),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update profile",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to select avatar without losing state
  // Future<void> _selectAvatar() async {
  //   // Save current form values
  //   final String username = _usernameController.text;
  //   final String bio = _bioController.text;

  //   final result = await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AvatarSelectionScreenforsetting()));

  //   if (result != null && result is String) {
  //     setState(() {
  //       _currentAvatar = result;
  //       // Restore form values
  //       _usernameController.text = username;
  //       _bioController.text = bio;
  //     });
  //   }
  // }
  // In EditProfileScreen
  Future<void> _selectAvatar() async {
    // Save current form values
    final String username = _usernameController.text;
    final String bio = _bioController.text;

    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AvatarSelectionScreenforsetting()));

    if (result != null && result is String) {
      setState(() {
        _currentAvatar = result;
        // Restore form values
        _usernameController.text = username;
        _bioController.text = bio;
      });
    }
  }

  // Method to select interests without losing state
  // Future<void> _selectInterests() async {
  //   // Save current form values
  //   final String username = _usernameController.text;
  //   final String bio = _bioController.text;

  //   final result = await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Interestsforsetting(avatar: _currentAvatar)));

  //   if (result != null && result is List<String>) {
  //     setState(() {
  //       _currentInterests = result;
  //       // Restore form values
  //       _usernameController.text = username;
  //       _bioController.text = bio;
  //     });
  //   }
  // }
  // In EditProfileScreen
  Future<void> _selectInterests() async {
    // Save current form values
    final String username = _usernameController.text;
    final String bio = _bioController.text;

    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => Interestsforsetting(avatar: widget.avatar)));

    if (result != null && result is List<String>) {
      setState(() {
        // Update interests with the result
        // Restore form values
        _usernameController.text = username;
        _bioController.text = bio;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                "cancel",
                style: GoogleFonts.roboto(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark ? AppColors.darkGradient : AppColors.lightGradient,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Profile",
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
               SizedBox(height: 8.h),
              Text(
                "What Should We Call You?",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
               SizedBox(height: 24.h),
              _buildTextField("User Name", _usernameController),
               SizedBox(height: 16.h),
              _buildTextField("Bio", _bioController),
               SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _bioController,
                    builder: (context, value, child) {
                      return Text(
                        '${value.text.length}/150',
                        style: GoogleFonts.roboto(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
               SizedBox(height: 16.h),
              _buildButton('Choose Avatar', _selectAvatar, _currentAvatar),
               SizedBox(height: 16.h),
              _buildButtonForInterest('Choose Interests', _selectInterests, _currentInterests),
              const Spacer(),
              Padding(
                padding:  EdgeInsets.only(bottom: 20.h),
                child: Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7400A5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            "Save",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
               SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildTextField(String hint, TextEditingController controller, {IconData? icon}) {
  //   return TextField(
  //     controller: controller,
  //     style: GoogleFonts.roboto(color: Colors.white),
  //     maxLines: null,
  //     inputFormatters: [
  //       LengthLimitingTextInputFormatter(150),
  //     ],
  //     decoration: InputDecoration(
  //       hintText: hint,
  //       hintStyle: GoogleFonts.roboto(color: Colors.grey),
  //       filled: true,
  //       fillColor: Colors.black,
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: Colors.grey),
  //       ),
  //       prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
  //     ),
  //   );
  // }
  Widget _buildTextField(String hint, TextEditingController controller, {IconData? icon}) {
    bool isBio = hint.toLowerCase() == "bio";

    return TextField(
      controller: controller,
      style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
      maxLines: isBio ? 5 : 1, // Multiple lines for bio
      maxLength: isBio ? 150 : null, // Character limit for bio
      inputFormatters: [
        LengthLimitingTextInputFormatter(isBio ? 150 : null),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.grey),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        counterText: isBio ? "" : null, // Hide default counter for bio
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.sp),
          borderSide: const BorderSide(color: Color(0xFF7400A5)),
        ),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        // Custom suffix for bio field to show character count
        // suffix: isBio
        //     ? ValueListenableBuilder<TextEditingValue>(
        //         valueListenable: controller,
        //         builder: (context, value, child) {
        //           return Text(
        //             '${value.text.length}/150',
        //             style: GoogleFonts.roboto(
        //               color: Colors.grey,
        //               fontSize: 12,
        //             ),
        //           );
        //         },
        //       )
        //     : null,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, String imageUrl) {
    return Column(
      children: [
        if (imageUrl.isNotEmpty) ...[
          CircleAvatar(
            radius: 40.sp,
            backgroundImage: NetworkImage(imageUrl),
            backgroundColor: Colors.grey[800],
          ),
           SizedBox(height: 8.h),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(20.sp),
              border: Border.all(color: Color(0xFF7400A5)),
            ),
            child: Text(
              'Avatar Selected',
              style: GoogleFonts.roboto(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
           SizedBox(height: 10.h),
        ],
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.sp),
              side: const BorderSide(color: Color(0xFF7400A5)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonForInterest(String text, VoidCallback onPressed, List<String> selectedInterests) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.sp),
              side: const BorderSide(color: Color(0xFF7400A5)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
         SizedBox(height: 20.h),
        if (selectedInterests.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: selectedInterests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20.sp),
                  border: Border.all(color: Colors.deepPurpleAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interest,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                     SizedBox(width: 6.h),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedInterests.remove(interest);
                        });
                      },
                      child: const Icon(Icons.close, color: Colors.deepPurpleAccent, size: 18),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
           SizedBox(height: 10.h),
        ],
      ],
    );
  }
}
