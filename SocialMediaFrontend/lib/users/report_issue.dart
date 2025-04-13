import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/users/profile_screen.dart';
import 'package:socialmedia/utils/colors.dart';

class ReportIssueScreen extends StatelessWidget {
  final TextEditingController _issueController = TextEditingController();

  void _submitIssue(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Issue reported successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => user_profile()));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final profileimage = userProvider.userProfile;
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkGradient[0] : AppColors.lightGradient[0],
        appBar: AppBar(
          backgroundColor: Colors.black26,
          elevation: 0,
          leading: IconButton(
            icon:  Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.support_agent, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              SizedBox(width: 8.w),
              Text(
                "Customer Support",
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600 ,color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Info
              CircleAvatar(
                radius: 40.sp,
                backgroundImage: NetworkImage(profileimage!),
              ),
              const SizedBox(height: 10),
              Text(
                userProvider.userName!,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      
              const SizedBox(height: 20),
      
              // Issue Description Input
              TextField(
                controller: _issueController,
                maxLines: 5,
                style: GoogleFonts.roboto(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Describe Your Issue",
                  hintStyle: GoogleFonts.roboto(color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                    
                  ),
                ),
              ),
              const SizedBox(height: 10),
      
              // Add Photo Button
              Row(
                children: [
                   Icon(Icons.add_photo_alternate, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                   SizedBox(width: 5.w),
                  Text(
                    "Add Photo",
                    style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                  ),
                ],
              ),
               SizedBox(height: 30.h),
      
              // Support Info
              Text(
                "You Can Also Reach Out To Us 👋",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
               SizedBox(height: 10.h),
              Text(
                "Support Email:\n info@bondbridge.ai",
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Text(
              //   "support phone:\n +011 98765 43201\n +011 98865 43201",
              //   textAlign: TextAlign.center,
              //   style: GoogleFonts.roboto(
              //     fontSize: 14,
              //     color: Colors.grey,
              //   ),
              // ),
              const SizedBox(height: 40),
      
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _submitIssue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7400A5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
