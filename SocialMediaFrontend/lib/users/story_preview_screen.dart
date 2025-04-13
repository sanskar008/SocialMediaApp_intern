import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:socialmedia/user_apis/uploadstory.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:uuid/uuid.dart';

class StoryEditor extends StatefulWidget {
  final File selectedImage;

  const StoryEditor({required this.selectedImage, Key? key}) : super(key: key);

  @override
  State<StoryEditor> createState() => _StoryEditorState();
}

class _StoryEditorState extends State<StoryEditor> {
  bool _isUploading = false;

  Future<void> _uploadStory() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Upload directly using the file
      StoryService storyService = StoryService();
      await storyService.uploadStory(widget.selectedImage);

      Fluttertoast.showToast(
        msg: "Story posted successfully!",
        gravity: ToastGravity.BOTTOM,
      );

      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to post story!",
        gravity: ToastGravity.BOTTOM,
      );
      print("Upload error: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.black,
        title: Text(
          "Preview Story",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        actions: [
           InkWell(
                onTap: () {
                  _uploadStory();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 14.0.w  , vertical: 4),
                      child: 
                      _isUploading ?
                      LoadingAnimationWidget.threeArchedCircle(
                        color: Colors.white,
                        size: 20,
                      ) :
                      Text(
                        "Post",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1, // Keep it square like Instagram
          child: Image.file(
            widget.selectedImage,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
