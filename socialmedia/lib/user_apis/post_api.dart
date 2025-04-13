import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/utils/constants.dart';

Future<void> submitPost({
  required BuildContext context,
  required List<File> mediaFiles, // Now handles both images and videos
  required String userid,
  required String token,
  required String content,
}) async {
  const String url = '${BASE_URL}api/post';
  final request = http.MultipartRequest('POST', Uri.parse(url))
    ..headers.addAll({
      'userid': userid,
      'token': token,
    })
    ..fields.addAll({
      'privacy': '1',
      'whoCanComment': '1',
      'content': content,
    });

  try {
    // Process all media files (images + videos)
    for (final file in mediaFiles) {
      final fileExt = file.path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi'].contains(fileExt);

      final part = await http.MultipartFile.fromPath(
        isVideo ? 'video' : 'image', // Array format for multiple files
        file.path,
      );
      request.files.add(part);
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: 'Post successful!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNavBarScreen()),
      );
    } else {
      throw Exception('Failed with status ${response.statusCode}: $responseBody');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post failed: ${e.toString()}')),
    );
    rethrow;
  }
}