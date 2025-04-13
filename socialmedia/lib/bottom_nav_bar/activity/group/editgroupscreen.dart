import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:convert';

class EditGroupScreen extends StatefulWidget {
  final String chatRoomId;

  const EditGroupScreen({super.key, required this.chatRoomId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  List<String> selectedInterests = [];
  final List<String> availableInterests = [
    'Memes',
    'Food & Culinary',
    'Pop Culture',
    'Gaming',
    'Health',
    'Outdoor Adventures',
    'Music',
    'Movies',
    'TV Shows',
    'Pets',
    'Fitness',
    'Travel',
    'Photography',
    'Technology',
    'DIY',
    'Fashion',
    'Literature',
    'Comedy',
    'Social Activism',
    'Social Media',
    'Craft Mixology',
    'Podcasts',
    'Cultural Arts',
    'History',
    'Science',
    'Auto Enthusiasts',
    'Meditation',
    'Virtual Reality',
    'Dance',
    'Board Games',
    'Wellness',
    'Trivia',
    'Content Creation',
    'Graphic Arts',
    'Anime',
    'Sports',
    'Stand-Up',
    'Crafts',
    'Exploration',
    'Concerts',
    'Musicians',
    'Animal Lovers',
    'Visual Arts',
    'Animation',
    'Style',
    'Basketball',
    'Football',
    'Hockey',
    'Boxing',
    'MMA',
    'Wrestling',
    'Baseball',
    'Golf',
    'Tennis',
    'Track & Field',
    'Gadgets',
    'Mathematics',
    'Physics',
    'Outer Space',
    'Religious',
    'Culture'
  ];

  bool showAllInterests = false; // Toggle to show all interests

  bool isLoading = false;

  /// Function to Pick Image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  /// Function to Update Group Info
  Future<void> _updateGroup() async {
    if (_bioController.text.isEmpty &&
        _groupNameController.text.isEmpty &&
        _profileImage == null) {
      Fluttertoast.showToast(
        msg: "No changes to update!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.pop(context);
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final userProvider = Provider.of<UserProviderall>(context, listen: false);
      final String? userId = userProvider.userId;
      final String? token = userProvider.userToken;

      if (userId == null || token == null) {
        throw Exception("User credentials not found.");
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("${BASE_URL}api/edit-group"),
      );

      request.headers.addAll({
        'userid': userId,
        'token': token,
      });

      request.fields['chatRoomId'] = widget.chatRoomId;
      if (_groupNameController.text.isNotEmpty) {
        request.fields['groupName'] = _groupNameController.text;
      }
      if (_bioController.text.isNotEmpty) {
        request.fields['bio'] = _bioController.text;
      }

      // ✅ Check and add image correctly
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'image', _profileImage!.path), // Ensure key matches backend
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      print('Response: $responseData'); // Check backend response

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Group updated successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pop(context);
      } else {
        throw Exception("Failed to update group: $responseData");
      }
    } catch (error) {
      print("Error updating group: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text("Failed to update group: $error"))),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int displayedInterestCount =
        showAllInterests ? availableInterests.length : 15;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Group",
          style: GoogleFonts.roboto(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage("assets/avatar/1.png")
                            as ImageProvider,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                labelStyle: GoogleFonts.roboto(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: "About Group",
                labelStyle: GoogleFonts.roboto(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select Interests",
                style: GoogleFonts.roboto(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Wrap(
              spacing: 8.0,
              children: availableInterests
                  .take(displayedInterestCount)
                  .map((interest) {
                bool isSelected = selectedInterests.contains(interest);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedInterests.remove(interest);
                      } else {
                        selectedInterests.add(interest);
                      }
                    });
                  },
                  child: Chip(
                    label: Text(
                      interest,
                      style: GoogleFonts.roboto(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    backgroundColor:
                        isSelected ? Color(0xFFC08EF9) : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            if (!showAllInterests)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAllInterests = true;
                  });
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      "Load More",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC08EF9),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _updateGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7400A5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Continue",
                      style:
                          GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
