import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/pages/onboarding_screens/signup_screen.dart';
import 'package:vibration/vibration.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  double _slideProgress = 0.0;
  bool _isSliding = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _slideProgress += details.delta.dx / (MediaQuery.of(context).size.width - 100);
      _slideProgress = _slideProgress.clamp(0.0, 1.0);
      
      if (_slideProgress > 0.95 && !_isSliding) {
        _isSliding = true;
        Vibration.vibrate(duration: 50);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignupScreen()),
        );
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_slideProgress < 0.95) {
      setState(() {
        _slideProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      //const Color(0xFF0E111B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.50,
                width: double.infinity,
                child: Padding(
                    padding: EdgeInsets.only(
                      left: 10.w,
                      right: 10.w,
                    ),
                    child: Image.asset('assets/images/home_front_final.png',
                        fit: BoxFit.cover)),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Column(
                  children: [
                    SizedBox(
                      height: 52.h,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 31.w, right: 30.w),
                      child: SizedBox(
                        height: 90.h,
                        width: 339.w,
                        child: RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: const TextStyle(height: 1.4),
                            children: [
                              TextSpan(
                                  text: 'Welcome to ',
                                  style: GoogleFonts.leagueSpartan(
                                      fontSize: 30.sp,
                                      fontWeight: FontWeight.w500)),
                              TextSpan(
                                text: "BondBridge, ",
                                style: GoogleFonts.leagueSpartan(
                                  fontSize:
                                      30.sp, // or use 45.sp if you're using ScreenUtil
                                  fontWeight: FontWeight.w700,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [
                                        // #E25FB2
                                        Color(0xFF7E6DF1),
                                        Color(0xFF7E6DF1),
                                        Color(0xFF7E6DF1),
                                        Color(0xFF7E6DF1),
                                        Color(0xFF7E6DF1), // #7E6DF1
                                        Color(0xFFE25FB2),
                                      ],
                                    ).createShader(
                                      // Adjust these coordinates as needed for the best gradient placement
                                      const Rect.fromLTWH(
                                          0.0, 0.0, 315.0, 70.0),
                                    )
                                    // Outline style
                                    ..strokeWidth = 2, // Outline thickness
                                ),
                              ),
                              TextSpan(
                                  text: 'a\nnew way to connect ',
                                  style: GoogleFonts.leagueSpartan(
                                      fontSize: 30.sp,
                                      fontWeight: FontWeight.w500)),
                              TextSpan(
                                text: "online",
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 30.sp, // or 45.sp if using ScreenUtil
                                  fontWeight: FontWeight.w700,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [
                                        Color(0xFF7E6DF1),
                                        Color(0xFF7E6DF1),
                                        Color(0xFF7E6DF1),
                                        Color(0xFF7E6DF1),
                                        Color(0xFFE25FB2),
                                        Color(0xFFE25FB2),
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 480,
                                          50), // Adjust these values as needed
                                    )
                                    ..strokeWidth = 2,
                                ),
                              )

                              // TextSpan(
                              //     text: '',
                              //     style: GoogleFonts.leagueSpartan(
                              //         fontSize: 32.sp,
                              //         fontWeight: FontWeight.w500)),
                              // TextSpan(

                              //     text: 'interacting',
                              //     style: GoogleFonts.leagueSpartan(

                              //         fontSize: 32.sp,
                              //         foreground: Paint()
                              //           ..shader = LinearGradient(
                              //             colors: [
                              //               Colors.purple,
                              //               Colors.deepPurpleAccent,
                              //               Colors.purpleAccent
                              //             ],
                              //           ).createShader(Rect.fromLTWH(
                              //               0.0, 0.0, 200.0, 70.0)),
                              //         fontStyle: FontStyle.italic,
                              //         fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    /*  Text('Interacting',
                    style: GoogleFonts.leagueSpartan(
                                    
                                      fontSize: 30.sp,
                                     // color: Colors.white,
                                      foreground: Paint()
                                        ..shader = LinearGradient(
                                          colors: [
                                            Colors.purple,
                                            Colors.deepPurpleAccent,
                                            Colors.purpleAccent
                                          ],
                                        ).createShader(Rect.fromLTWH(
                                            0.0, 0.0, 200.0, 70.0)),
                                      //fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500),
                    ),*/
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 10),
                      child: SizedBox(
                          height: 100,
                          child: SvgPicture.asset(
                            'assets/images/bondlogog.svg', // Use the SVG file path
                            width: 130, // Adjust size as needed
                            height: 130,
                          )
                          ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.w),
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        height: 80.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1E1F25),
                              Color(0xFF121318),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: GestureDetector(
                          onHorizontalDragUpdate: _onHorizontalDragUpdate,
                          onHorizontalDragEnd: _onHorizontalDragEnd,
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  "Swipe To Connect",
                                  style: TextStyle(
                                    color: const Color(0xff9C9C9C),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: _slideProgress * (MediaQuery.of(context).size.width - 140.w),
                                child: Container(
                                  height: 80.h,
                                  width: 70.sp,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF7E6DF1),
                                        Color(0xFFE25FB2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
