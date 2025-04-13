import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:socialmedia/auth_apis/send_otp.dart';
import 'package:socialmedia/auth_apis/verify_otp.dart';
import 'package:pinput/pinput.dart';
import 'package:socialmedia/utils/colors.dart';

class OtpScreen extends StatefulWidget {
  final String number;
  final String countrycode;
  const OtpScreen({super.key, required this.number, required this.countrycode});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final int otpLength = 6; // Total OTP length
  String finalotp = '';
  late List<FocusNode> _focusNodes;
  String? mobile;
  bool _isLoading = false;

  void _verifyotp() async {
    setState(() {
      _isLoading = true; // Show the loader
    });

    try {
      await verifyOtp(mobile.toString(), widget.countrycode, finalotp, context);
    } catch (e) {
      // Handle any error that might occur
      print("Error sending OTP: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide the loader
      });
    }
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      mobile = widget.number;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setotp(String a) {
    setState(() {
      finalotp = a;
    });
    print(finalotp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkGradient
                : AppColors.lightGradient,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 63.h,
            ),
            // Padding(
            //   padding: EdgeInsets.only(left: 34.w),
            //   child: SizedBox(
            //     height: 40.h,
            //     width: 40.w,
            //     child: InkWell(
            //       onTap:() {
            //         Navigator.pop(context);
            //       },
            //       child: Icon(
            //         Icons.arrow_back_ios_new_outlined,
            //         color: Colors.white,
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(
              height: 67.h,
            ),
            Padding(
              padding: EdgeInsets.only(left: 40.w),
              child: SizedBox(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter OTP',
                    style: GoogleFonts.montserrat(
                        fontSize: 30.sp,
                        color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,

                        fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Text(
                        "Sent to $mobile ",
                        style: GoogleFonts.montserrat(
                            fontSize: 18.sp,
                            color: 
                            Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFF999999)
                        : Colors.grey.shade600,

                            
                            fontWeight: FontWeight.w400),
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Edit',
                          style: GoogleFonts.montserrat(
                              fontSize: 18.sp,
                              color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,

                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white),
                        ),
                      )
                    ],
                  )
                ],
              )),
            ),
            SizedBox(
              height: 48.h,
            ),
            // ElevatedButton(onPressed: (){
            //   print('$mobile');
            //   print('00000');
            //   print(getFullOtp());
            // }, child: Text('Print')),

            Center(
              child: Pinput(
                length: 6,
                closeKeyboardWhenCompleted: true,
                defaultPinTheme: PinTheme(
                  width: 56,
                  height: 60,
                  textStyle: TextStyle(
                      fontSize: 25,
                      color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,

                      fontWeight: FontWeight.w600),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,
),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onCompleted: (pin) => setotp(pin),
              ),
            ),

            /*Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(otpLength, (index) {
                  return Container(
                    width: 40.w,
                    height: 56.h,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focusNodes[index].hasFocus
                            ? Colors.white
                            : Colors.grey,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                   
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      maxLength: 1,
                      decoration: const InputDecoration(
                        counterText: "", // Hides the character counter
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => _handleInput(value, index),
                    ),
                  );
                }),
              ),
            ),*/
            SizedBox(
              height: 25.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't get the code?  ",
                  style: GoogleFonts.montserrat(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkText
                        : AppColors.lightText,
),
                ),
                InkWell(
                  onTap: () {
                    //country code change kro
                    OTPApiService().sendOtp(
                        mobile.toString(), widget.countrycode, context);
                  },
                  child: Text(
                    "Resend it",
                    style: GoogleFonts.montserrat(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: 
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFBE75FF)
                        : Colors.purple,

                        ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 48.h,
            ),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(350.w, 56.h),
                    backgroundColor: Color(0xFF7400A5),
                  ),
                onPressed: () {
                  //country code change krna h
                  _verifyotp();
                },
                child: _isLoading
                    ? LoadingAnimationWidget.inkDrop(
                        color: Colors.white, size: 30)
                    : Text(
                        'Verify OTP',
                        style: GoogleFonts.montserrat(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,

                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
