import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/user_apis/post_api.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';
import 'package:video_player/video_player.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({
    super.key,
  });
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage; // To store the selected image
  String? userid;
  String? token;
  String? username;
  List<XFile> _selectedImages = [];
  late UserProviderall userProvider;
  bool _isLoadingbond = false; // Loading state
  int _characterCount = 0;
  bool _isLoading = false; // To manage the loading state
  double _keyboardHeight = 0.0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChange);
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {}); // Refresh UI after loading data
    });
    FilePicker.platform;
    getuseridandtoken();
  }

  bool isVideo(XFile file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi');
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Keyboard is open
    } else {
      // Keyboard is closed
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _keyboardHeight = bottomInset;
    });
  }

  void _selectAndRewriteText() async {
    if (_controller.text.isEmpty) return;

    // Select all text
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );

    setState(() => _isLoading = true); // Show loading

    try {
      // Make API Call
      final response = await http.post(
        Uri.parse("${BASE_URL}api/reWriteWithBond"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"caption": _controller.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _controller.text = data["rewritten"]; // Update controller text
        });
      } else {
        print("Failed to fetch rewritten text");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false); // Hide loading
    }
  }

  void _post() async {
    setState(() => _isLoading = true);

    try {
      await submitPost(
        context: context,
        mediaFiles: _selectedImages.map((xfile) => File(xfile.path)).toList(),
        userid: userid!,
        token: token!,
        content: _controller.text,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedImages); // Add to the existing images
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<void> pickOneMinuteVideos() async {
    try {
      final XFile? videoFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );

      if (videoFile != null) {
        final controller = VideoPlayerController.file(File(videoFile.path));
        await controller.initialize();
        final duration = controller.value.duration.inSeconds;
        await controller.dispose();

        if (duration <= 60) {
          // Allow videos ≤ 60s
          setState(() {
            _selectedImages.add(videoFile);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Videos longer than 1 minute are not allowed.")),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Error picking videos: $e');
      debugPrint('🪵 Stack trace: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick video: $e")),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> getuseridandtoken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userid = prefs.getString('user_id');
      token = prefs.getString('user_token');
    }); // Retrieve the 'username' key
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // onWillPop: () async {
      //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
      //   return false;
      // },
      onWillPop: () async {
        // Check if there's unsaved content
        if (_controller.text.isNotEmpty || _selectedImages.isNotEmpty) {
          // Show confirmation dialog
          bool? shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Discard message'),
                content: Text('You have unsaved changes, do you want to discard?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Cancel
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));  
                    },
                    child: Text('Discard'),
                  ),
                ],
              );
            },
          );

          if (shouldDiscard == true) {
            // Navigate to previous screen
           // Navigator.push(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));  
          }
          return false; // Prevent default back behavior
        } else {
          // No unsaved changes, navigate normally
         // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBarScreen()));  
          return false;
        }
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: true, // Ensure keyboard adjusts the layout
          // SafeArea will ensure layout respects system insets
          body: SafeArea(
            // Use bottom: false to ensure content can extend to the bottom edge
            bottom: false,
            child: Stack(
              children: [
                // Gradient Background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkGradient
                            : AppColors.lightGradient),
                  ),
                ),
                // Main Content with Footer Space
                Column(
                  children: [
                    // Top Bar
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10, // Reduced from 50 since we're using SafeArea
                          bottom: 18,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  NetworkImage(userProvider.userProfile!),
                            ),
                            SizedBox(width: 8),
                            FittedBox(
                              child: Text(
                                'Make a Post',
                                style: GoogleFonts.roboto(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: InkWell(
                                onTap: () async {
                                      if (userid == null || token == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Center(
                                                  child: Text(
                                                      'Something went wrong'))),
                                        );
                                        return;
                                      };
                                      if(
                                          _controller.text.isEmpty &&
                                          _selectedImages.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Please add a caption or image'),
                                          ),
                                        );
                                        return;
                                      };
                                      _post();
                                    },
                                child: Container(
                                  height: 35.h,
                                  width: 65.w,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF7400A5),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? LoadingAnimationWidget.waveDots(
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : Text(
                                            'Post',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? AppColors.darkText
                                                      : AppColors.darkText,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    
                    // Text Input Area with space for bottom buttons
                    Expanded(
                      child: Column(
                        children: [
                          // Scrollable content area
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    maxLength: 150, // Add this line to limit to 150 characters
                                    maxLengthEnforcement: MaxLengthEnforcement.enforced, // Add this to enforce the limit
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(150),
                                    ],
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkText
                                          : AppColors.lightText,
                                    ),
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      hintText: 'What\'s On Your Mind...',
                                      hintStyle: GoogleFonts.roboto(
                                        color: Colors.grey[600],
                                        fontSize: 14.sp,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(16),
                                      counterText: '$_characterCount/150',
                                    ),
                                    onChanged: (text) {
                                        setState(() {
                                          _characterCount = text.length;
                                        });
                                      }
                                  ),
        
                                  if (_selectedImages.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Column(
                                        children: [
                                          CarouselSlider(
                                            options: CarouselOptions(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.40,
                                              viewportFraction: 1.0,
                                              enableInfiniteScroll: false,
                                              autoPlay: false,
                                            ),
                                            items: _selectedImages
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final index = entry.key;
                                              final file = entry.value;
        
                                              return Builder(
                                                builder: (BuildContext context) {
                                                  if (isVideo(file)) {
                                                    // Display video with VideoPlayer
                                                    return VideoPlayerWidget(
                                                        videoFile: file);
                                                  } else {
                                                    // Display image
                                                    return Stack(
                                                      children: [
                                                        Image.file(
                                                          File(file.path),
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                        ),
                                                        Positioned(
                                                          right: 10,
                                                          top: 10,
                                                          child: GestureDetector(
                                                            onTap: () =>
                                                                _removeImage(
                                                                    index),
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                      4),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.5),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: Icon(
                                                                  Icons.close,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                },
                                              );
                                            }).toList(),
                                          ),
                                          // Image count indicator
                                          if (_selectedImages.length > 1)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      '${_selectedImages.length} Photos',
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.white,
                                                        fontSize: 12.sp,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
        
                                  // Display Selected Image (if any)
                                  if (_selectedImage != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.40,
                                        width: MediaQuery.of(context).size.width,
                                        child: Image.file(
                                          File(_selectedImage!.path),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
        
                          // Bottom Action Buttons - Fixed at bottom
                          Container(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom > 0
                                  ? MediaQuery.of(context).padding.bottom + 1.h
                                  : 20.h, // Add extra padding for navigation bar
                              top: 10,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness == Brightness.dark
                                      ? Color(0xFF1E1E1E)
                                      : Colors.grey[100],
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Color(0xFF1E1E1E)
                                      : (Colors.grey[200] ?? Colors.grey),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(54.r),
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Color(0xFF1E1E1E)
                                        : Colors.grey[100],
                                  ),
                                  child: GestureDetector(
                                    onTap:
                                        _isLoading ? null : _selectAndRewriteText,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 4),
                                        Text(
                                          'Re-write with ',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.darkText
                                                : AppColors.lightText,
                                          ),
                                        ),
                                        Text(
                                          'BondChat',
                                          style: GoogleFonts.roboto(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.purple,
                                          ),
                                        ),
                                        SizedBox(width: 5.w),
                                        SvgPicture.asset(
                                          'assets/icons/bondchat_star.svg',
                                          width: 15.w,
                                          height: 15.h,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(
                                    Icons.mic,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                    size: 24,
                                  ),
                                  onPressed: () {}, // Open gallery when clicked
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.photo_library_outlined,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                    size: 24,
                                  ),
                                  onPressed:
                                      _pickImages, // Open gallery when clicked
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                    size: 24,
                                  ),
                                  onPressed:
                                      _pickImages, // Open gallery when clicked
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.video_call_rounded,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                    size: 24,
                                  ),
                                  onPressed:
                                      pickOneMinuteVideos, // Open gallery when clicked
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final XFile videoFile;

  const VideoPlayerWidget({required this.videoFile});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoFile.path))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 50,
          ),
          onPressed: () {
            setState(() {
              _isPlaying ? _controller.pause() : _controller.play();
              _isPlaying = !_isPlaying;
            });
          },
        ),
      ],
    );
  }
}
