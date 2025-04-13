import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:socialmedia/auth_apis/setorupdatepass.dart';
import 'package:intl/intl.dart';

import '../../utils/colors.dart';

class UserInputFields extends StatefulWidget {
  final String userid;
  final String token;
  const UserInputFields({super.key, required this.userid, required this.token});

  @override
  State<UserInputFields> createState() => _UserInputFieldsState();
}

class _UserInputFieldsState extends State<UserInputFields> {
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController bio = TextEditingController();
  TextEditingController dob = TextEditingController();
  bool _isLoading = false;

  void _setpassword() async {
    setState(() {
      _isLoading = true; // Show the loader
    });

    try {
      await setPassword(context, password.text, widget.userid, widget.token);
    } catch (e) {
      // Handle any error that might occur
      print("Error sending OTP: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide the loader
      });
    }
  }

  // Future<void> _selectDate() async {
  //   DateTime? pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(1900),
  //     lastDate: DateTime.now(),
  //     builder: (context, child) {
  //       return Theme(
  //         data: Theme.of(context).copyWith(
  //           colorScheme: const ColorScheme.light(
  //             primary: Colors.blue, // Header background color
  //             onPrimary: Colors.white, // Header text color
  //             onSurface: Colors.black, // Body text color
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );

  //   if (pickedDate != null) {
  //     // Format the date
  //     String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
  //     setState(() {
  //       dob.text = formattedDate; // Set the formatted date to the TextField
  //       print(dob.text);
  //     });
  //   }
  // }
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // ~18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Calculate age
      final today = DateTime.now();
      final age = today.year - pickedDate.year - (today.month < pickedDate.month || (today.month == pickedDate.month && today.day < pickedDate.day) ? 1 : 0);

      if (age < 18) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Center(child: Text('You must be at least 18 years old to register'))),
        );
        return;
      }

      // Format the date and set it if age is valid
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      setState(() {
        dob.text = formattedDate;
      });
    }
  }
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark ? AppColors.darkGradient : AppColors.lightGradient,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 38.w),
                  child: Text(
                    'Welcome to\nBondBridge',
                    style: GoogleFonts.montserrat(fontSize: 30.sp, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  height: 16.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 38.w),
                  child: Text(
                    'Enter Info',
                    style: GoogleFonts.montserrat(fontSize: 20.sp, fontWeight: FontWeight.w400, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF999999) : Colors.grey.shade600),
                  ),
                ),
                SizedBox(
                  height: 48.h,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: TextField(
                    controller: username,
                    decoration: InputDecoration(
                        //prefixIcon: const Icon(Icons.phone, color: Colors.white),
                        hintText: "Username",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 16.sp,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.lightText,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF7400A5),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF7400A5), // Blue border when focused
                                    width: 2,
                                  ),
                                )
                                ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(
                  height: 23.h,
                ),

                ///EMAIL FIELD
                // Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 38.w),
                //   child: TextField(
                //     controller: email,
                //     decoration: InputDecoration(
                //         //prefixIcon: const Icon(Icons.phone, color: Colors.white),
                //         hintText: "Email",
                //         hintStyle: GoogleFonts.montserrat(
                //           fontSize: 16.sp,
                //           color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.lightText,
                //         ),
                //         filled: true,
                //         fillColor: const Color.fromARGB(129, 85, 85, 85),
                //         border: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(22.sp),
                //           borderSide: BorderSide(color: Color(0xFF999999)),
                //         ),
                //         enabledBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(22.sp),
                //           borderSide: BorderSide(color: Color(0xFF999999)),
                //         ),
                //         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22.sp), borderSide: BorderSide(color: Colors.white))),
                //     style: TextStyle(
                //       color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                //     ),
                //   ),
                // ),
                SizedBox(
                  height: 23.h,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: TextField(
                    maxLines: 4,
                    maxLength: 150,
                    inputFormatters: [
                     // LengthLimitingTextInputFormatter(150),
                    ],
                    controller: bio,
                    decoration: InputDecoration(
                        //prefixIcon: const Icon(Icons.phone, color: Colors.white),
                        hintText: "Bio",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 16.sp,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.lightText,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF7400A5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF7400A5), // Blue border when focused
                            width: 2,
                          ),
                        )
                        ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(
                  height: 23.h,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: TextField(
                    controller: dob,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                        //prefixIcon: const Icon(Icons.phone, color: Colors.white),
                        hintText: "(D.O.B) dd/mm/yyyy",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 16.sp,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.lightText,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF7400A5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF7400A5), // Blue border when focused
                            width: 2,
                          ),
                        )
                        ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                SizedBox(
                  height: 23.h,
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 38.w),
                  child: StatefulBuilder(builder: (context, setState) {
                    
                    return TextField(
                      controller: password,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 16.sp,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.lightText,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF7400A5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF7400A5), // Blue border when focused
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                            color: _passwordVisible ? Color(0xFF7400A5) : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      ),
                    );
                  }),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 45.h),
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(350.w, 56.h),
                        backgroundColor: Color(0xFF7400A5),
                      ),
                      onPressed: () async {
                        final DateFormat format = DateFormat('dd/MM/yyyy');
                        try {
                          final DateTime birthDate = format.parse(dob.text);
                          final DateTime today = DateTime.now();

                          int age = today.year - birthDate.year;
                          if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
                            age--;
                          }

                          if (age < 18) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  backgroundColor: Color(0xFF7400A5),
                                  content: Center(
                                    child: Text(
                                      'You must be at least 18 years old to register',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                            );
                            return;
                          }

                          // Proceed with form submission
                          final prefs_username = await SharedPreferences.getInstance();
                          await prefs_username.setString('username', username.text);
                          await prefs_username.setString('dateofbirth', dob.text);
                          await prefs_username.setString('bio', bio.text);
                          _setpassword();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Center(child: Text('Please enter a valid date of birth'))),
                          );
                        }

                        // final prefs_username =
                        //     await SharedPreferences.getInstance();
                        // await prefs_username.setString(
                        //     'username', username.text);
                        // await prefs_username.setString('dateofbirth', dob.text);
                        // await prefs_username.setString('bio', bio.text);
                        // _setpassword();
                      },
                      child: _isLoading
                          ? SimpleCircularProgressBar(
                              size: 20,
                              progressStrokeWidth: 4,
                              backStrokeWidth: 0,
                              progressColors: [
                                Colors.white,
                                Colors.yellow
                              ],
                            )
                          : Text(
                              'Let\'s Go',
                              style: GoogleFonts.montserrat(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}




// ElevatedButton(
//   onPressed: () async {
//     // Parse the date
//     final DateFormat format = DateFormat('dd/MM/yyyy');
//     try {
//       final DateTime birthDate = format.parse(dob.text);
//       final DateTime today = DateTime.now();
      
//       int age = today.year - birthDate.year;
//       if (today.month < birthDate.month || 
//           (today.month == birthDate.month && today.day < birthDate.day)) {
//         age--;
//       }
      
//       if (age < 18) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('You must be at least 18 years old to register')),
//         );
//         return;
//       }
      
//       // Proceed with form submission
//       final prefs_username = await SharedPreferences.getInstance();
//       await prefs_username.setString('username', username.text);
//       await prefs_username.setString('dateofbirth', dob.text);
//       await prefs_username.setString('bio', bio.text);
//       _setpassword();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter a valid date of birth')),
//       );
//     }
//   },
//   child: Text('Lets go'),
// )
