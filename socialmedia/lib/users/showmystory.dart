import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:socialmedia/utils/storyAvatar.dart';
import 'package:story_view/story_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyStoryViewPage extends StatefulWidget {
  final List<Story_Item> stories;
  const MyStoryViewPage({required this.stories});

  @override
  _MyStoryViewPageState createState() => _MyStoryViewPageState();
}

class _MyStoryViewPageState extends State<MyStoryViewPage>
    with SingleTickerProviderStateMixin {
  final StoryController controller = StoryController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<StoryItem> storyItems = [];
  List<Viewer> viewers = [];
  bool isLoading = true;
  bool isViewerListOpen = false;
  int currentStoryIndex = 0;
  bool _isAnimationInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
    _fetchStoryViewers(widget.stories[0].storyid);


    // Initialize only the animation controller here
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the animation here, after MediaQuery is available
    if (!_isAnimationInitialized) {
      _animation = Tween<double>(
        begin: 0,
        end: MediaQuery.of(context).size.height * 0.5,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _animation.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });


      _isAnimationInitialized = true;
    }
  }

  void _loadStories() {
    storyItems = widget.stories
        .map((story) => StoryItem.pageImage(
              url: story.imageUrl,
              controller: controller,
              duration: const Duration(seconds: 5),
            ))
        .toList();
    storyItems = widget.stories
        .map((story) => StoryItem.pageImage(
              url: story.imageUrl,
              controller: controller,
              duration: const Duration(seconds: 5),
            ))
        .toList();
  }

  void _onStoryChanged(StoryItem storyItem, int index) {
  if (currentStoryIndex != index) {
    setState(() {
      currentStoryIndex = index;  // Update to correct story
      isLoading = true;
      viewers = [];
    });
    _fetchStoryViewers(widget.stories[currentStoryIndex].storyid);
  }
}

  void _toggleViewerList() {
    setState(() {
      isViewerListOpen = !isViewerListOpen;
      if (isViewerListOpen) {
        _animationController.forward();
        controller.pause();
      } else {
        _animationController.reverse();
        controller.play();
      }
    });
  }

  void _closeViewerList() {
    if (isViewerListOpen) {
      setState(() {
        isViewerListOpen = false;
        _animationController.reverse();
        controller.play();
      });
    }
  }

  Future<void> _deleteStory() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final userId = userProvider.userId;
    final token = userProvider.userToken;

    if (userId == null || token == null) {
      print("User credentials missing");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}api/archieve-story'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: jsonEncode({
          "storyId": widget.stories[currentStoryIndex].storyid,
        }),
      );

      if (response.statusCode == 200) {
        print('Story deleted successfully');
        // Close the story view after successful deletion
        if (mounted) Navigator.pop(context);
      } else {
        print('Failed to delete story: ${response.body}');
      }
    } catch (e) {
      print('Error deleting story: $e');
    }
  }

  Future<void> _fetchStoryViewers(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final token = prefs.getString('user_token') ?? '';

      if (userId.isEmpty || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${BASE_URL}api/get-story-viewers?storyId=$storyId'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
          'userId': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final viewersList = data['viewers'];

        print('Fetched viewers for story: $storyId');

        if (mounted) {
          setState(() {
            viewers = (viewersList is List)
                ? viewersList
                    .map((viewer) => Viewer(
                          userId: viewer['userId'],
                          name: viewer['name'],
                        ))
                    .toList()
                : [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          viewers = [];
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAnimationInitialized)
      return Container(); // Return empty container while initializing

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: storyItems,
            controller: controller,
            onStoryShow: _onStoryChanged,
            onComplete: () => Navigator.pop(context),
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.pop(context);
              }
            },
            progressPosition: ProgressPosition.top,
          ),
          
          _buildHeader(),
          _buildViewerPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  print(widget.stories[currentStoryIndex].name);
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      NetworkImage(widget.stories[currentStoryIndex].imageUrl),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.stories[currentStoryIndex].name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${widget.stories[currentStoryIndex].ago}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              TextButton(
                onPressed: _deleteStory,
                child: Text(
                  "Delete Story",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewerPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: _toggleViewerList,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: _animation.value + 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildDragHandle(),
                  if (!isViewerListOpen) _buildViewerSummary(),
                  if (isViewerListOpen) _buildViewerList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildViewerSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          isLoading ? 'Loading...' : '${viewers.length} views',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildViewerList() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewers.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/avatar/2.png'),
            ),
            title: Text(
              viewers[index].name,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class Viewer {
  final String userId;
  final String name;

  Viewer({required this.userId, required this.name});
}

