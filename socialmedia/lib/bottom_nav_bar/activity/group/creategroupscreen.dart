import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';

// Group Creation Screens
class CreateGroupFlow extends StatefulWidget {
  @override
  _CreateGroupFlowState createState() => _CreateGroupFlowState();
}

class _CreateGroupFlowState extends State<CreateGroupFlow> {
  final PageController _pageController = PageController();
  String groupName = '';
  String groupInfo = '';
  List<String> selectedInterests = [];
  List<String> selectedParticipants = [];
  List<Map<String, dynamic>> followers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      final response = await http.get(
        Uri.parse('${BASE_URL}api/followers'),
        headers: {
          'userid': userId ?? '',
          'token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          followers = List<Map<String, dynamic>>.from(data['result']);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching followers: $e');
      setState(() => isLoading = false);
    }
  }

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Future<void> _createGroup() async {
  //   try {
  //     print('went into try');
  //     print(selectedParticipants);
  //     final prefs = await SharedPreferences.getInstance();
  //     final userId = prefs.getString('user_id');
  //     final token = prefs.getString('user_token');

  //     final response = await http.post(
  //       Uri.parse('${BASE_URL}api/create-group'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'userid': userId ?? '',
  //         'token': token ?? '',
  //       },
  //       body: json.encode({
  //         'groupName': groupName,
  //         'participants': selectedParticipants,
  //       }),
  //     );

  //     if (response.statusCode == 201) {
  //       print("created");
  //       final data = json.decode(response.body);
  //       final chatRoomId = data['chatRoom']['chatRoomId'];
  //       await prefs.setString('chatroom_id', chatRoomId);
  //       print('room created successfully');
  //       print(chatRoomId);
  //       Navigator.of(context).pop(true); // Return success
  //     }
  //   } catch (e) {
  //     print('Error creating group: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to create group')),
  //     );
  //   }
  // }

  // Future<void> _createGroup() async {
  //   try {
  //     print('went into try');
  //     print(selectedParticipants);
  //     final prefs = await SharedPreferences.getInstance();
  //     final userId = prefs.getString('user_id');
  //     final token = prefs.getString('user_token');

  //     // Create a multipart request
  //     var request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse('${BASE_URL}api/create-group'),
  //     );

  //     // Add headers
  //     request.headers.addAll({
  //       'userid': userId ?? '',
  //       'token': token ?? '',
  //     });

  //     // Add text fields
  //     request.fields['groupName'] = groupName;
  //     request.fields['participants'] = json.encode(selectedParticipants);

  //     // Add image field if available
  //     if (imageFile != null) {
  //       request.files.add(await http.MultipartFile.fromPath(
  //         'image',
  //         imageFile!.path,
  //       ));
  //     }

  //     // Send the request
  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);

  //     if (response.statusCode == 201) {
  //       print("created");
  //       final data = json.decode(response.body);
  //       final chatRoomId = data['chatRoom']['chatRoomId'];
  //       await prefs.setString('chatroom_id', chatRoomId);
  //       print('room created successfully');
  //       print(chatRoomId);
  //       Navigator.of(context).pop(true); // Return success
  //     }
  //   } catch (e) {
  //     print('Error creating group: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to create group')),
  //     );
  //   }
  // }

  Future<void> _createGroup() async {
    try {
      // Check if image is selected since it's required
      // if (_profileImage == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Please select a group image')),
      //   );
      //   return;
      // }

      print('went into try');
      print(selectedParticipants);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('user_token');

      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${BASE_URL}api/create-group'),
      );

      // Add headers
      request.headers.addAll({
        'userid': userId ?? '',
        'token': token ?? '',
      });

      // Add text fields
      request.fields['groupName'] = groupName;
      request.fields['participants'] = json.encode(selectedParticipants);

      // Add image field (now required)
      // request.files.add(await http.MultipartFile.fromPath(
      //   'image',
      //   _profileImage!.path,
      // ));

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print("created");
        final data = json.decode(response.body);
        final chatRoomId = data['chatRoom']['chatRoomId'];
        await prefs.setString('chatroom_id', chatRoomId);
        print('room created successfully');
        print(chatRoomId);
        Navigator.of(context).pop(true); // Return success
      } else {
        // Handle non-201 status codes
        print('Failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Center(child: Text('Failed to create group. Please try again.'))),
        );
      }
    } catch (e) {
      print('Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Failed to create group'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _BuildGroupInfoScreen(
                onNext: (name, info, _profileImage) {
                  setState(() {
                    groupName = name;
                    groupInfo = info;
                  });
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              _BuildInterestsScreen(
                selectedInterests: selectedInterests,
                onInterestsSelected: (interests) {
                  setState(() => selectedInterests = interests);
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              _BuildParticipantsScreen(
                followers: followers,
                isLoading: isLoading,
                selectedParticipants: selectedParticipants,
                onParticipantsSelected: (participants) {
                  setState(() => selectedParticipants = participants);
                  _createGroup();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen 1: Group Info
class _BuildGroupInfoScreen extends StatefulWidget {
  final Function(String name, String info, File? profile) onNext;

  const _BuildGroupInfoScreen({required this.onNext});

  @override
  __BuildGroupInfoScreenState createState() => __BuildGroupInfoScreenState();
}

class __BuildGroupInfoScreenState extends State<_BuildGroupInfoScreen> {
  final _nameController = TextEditingController();
  final _infoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              child: Text(
                "Let's Make A Group",
                style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            /* FittedBox(
              child: CircleAvatar(
                radius: 60.sp,
                backgroundColor: Colors.grey[800],
                child: Icon(Icons.group, size: 60, color: Colors.white),
              ),
            ),*/
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : const AssetImage("assets/avatar/1.png") as ImageProvider,
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
            SizedBox(height: 30.h),
            TextField(
              controller: _nameController,
              style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
              decoration: InputDecoration(
                hintText: 'Group Name',
                hintStyle: GoogleFonts.roboto(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                  borderRadius: BorderRadius.all(Radius.circular(20.sp)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                  borderRadius: BorderRadius.all(Radius.circular(20.sp)),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _infoController,
              style: GoogleFonts.roboto(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
              maxLines: 3,
               maxLength: 150 , 
               inputFormatters: [
                LengthLimitingTextInputFormatter(150),
              ],
              decoration: InputDecoration(
                hintText: 'About Group',
                hintStyle: GoogleFonts.roboto(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.sp)),
                  borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.sp)),
                  borderSide: BorderSide(color: Colors.purple),
                ),
                // suffix: ValueListenableBuilder<TextEditingValue>(
                //     valueListenable: _infoController,
                //     builder: (context, value, child) {
                //       return Text(
                //         '${value.text.length}/130',
                //         style: GoogleFonts.roboto(
                //           color: Colors.grey,
                //           fontSize: 12,
                //         ),
                //       );
                //     },
                //   )
              ),
              
            ),
            //Spacer(),
            SizedBox(
              height: 100.h,
            ),
            SizedBox(
              width: double.infinity,
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      widget.onNext(_nameController.text, _infoController.text, _profileImage);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7400A5),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.roboto(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 2: Interests
class _BuildInterestsScreen extends StatefulWidget {
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsSelected;

  const _BuildInterestsScreen({
    required this.selectedInterests,
    required this.onInterestsSelected,
  });

  @override
  __BuildInterestsScreenState createState() => __BuildInterestsScreenState();
}

class __BuildInterestsScreenState extends State<_BuildInterestsScreen> {
  final List<String> availableInterests = [
    'Rock',
    'Indie Pop',
    'Fashion',
    'Motor Cycles',
    'NEWS',
    'Music',
    'Sports',
    'Racing cars',
    'Marketing',
    'Science',
    'Chess',
    'Food'
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What is\nGroup About?",
                style: GoogleFonts.roboto(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Select Group Interest',
                style: GoogleFonts.roboto(fontSize: 18.sp, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey[800]),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableInterests.map((interest) {
                    final isSelected = widget.selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            widget.selectedInterests.add(interest);
                          } else {
                            widget.selectedInterests.remove(interest);
                          }
                        });
                      },
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                      selectedColor: Color(0xFF7400A5),
                      checkmarkColor: Colors.white,
                      labelStyle: GoogleFonts.roboto(
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onInterestsSelected(widget.selectedInterests);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  Color(0xFF7400A5),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w500, color: Colors.white),
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

class _BuildParticipantsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> followers;
  final bool isLoading;
  final List<String> selectedParticipants;
  final Function(List<String>) onParticipantsSelected;

  const _BuildParticipantsScreen({
    required this.followers,
    required this.isLoading,
    required this.selectedParticipants,
    required this.onParticipantsSelected,
  });

  @override
  __BuildParticipantsScreenState createState() => __BuildParticipantsScreenState();
}

class __BuildParticipantsScreenState extends State<_BuildParticipantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFollowers = [];

  @override
  void initState() {
    super.initState();
    filteredFollowers = widget.followers;
  }

  void _filterFollowers(String query) {
    setState(() {
      filteredFollowers = widget.followers.where((follower) {
        return follower['name'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.lightText : AppColors.darkText,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Add Friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                onChanged: _filterFollowers,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: Icon(Icons.search, color: Colors.white),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 20),
            if (widget.isLoading)
              Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filteredFollowers.length,
                  itemBuilder: (context, index) {
                    final follower = filteredFollowers[index];
                    final isSelected = widget.selectedParticipants.contains(follower['_id']);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            widget.selectedParticipants.remove(follower['_id']);
                          } else {
                            widget.selectedParticipants.add(follower['_id']);
                          }
                        });
                      },
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: follower['profilePic'] != null ? NetworkImage(follower['profilePic']) : null,
                                backgroundColor: Colors.purple,
                              ),
                              if (isSelected)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFAA5EEA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            follower['name'] ?? 'name',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 10),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.selectedParticipants.isNotEmpty) {
                    widget.onParticipantsSelected(widget.selectedParticipants);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7400A5),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Add Friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
