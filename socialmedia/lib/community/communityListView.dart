import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/post_Screen.dart';
import 'package:socialmedia/community/communityDetailedScreen.dart';
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/community/communityProvider.dart';
import 'package:socialmedia/users/listtype_shimmer.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';

class CommunitiesListView extends StatefulWidget {
  @override
  _CommunitiesListViewState createState() => _CommunitiesListViewState();
}

class _CommunitiesListViewState extends State<CommunitiesListView> {
  bool isLoading = true;
  List<Community> communities = [];
  Map<String, dynamic>? community;

  @override
  void initState() {
    super.initState();
    fetchUserCommunities();
  }

  Future<void> fetchUserCommunities() async {
    final userId = Provider.of<UserProviderall>(context, listen: false).userId;

    if (userId != null) {
      try {
        // Get token from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token') ?? '';

        // Set headers with authorization token
        final headers = {
          'token': token,
          'userid': userId,
          'Content-Type': 'application/json',
        };

        // First fetch the user profile to get community IDs
        final Uri profileUrl = Uri.parse('${BASE_URL}api/showProfile?other=$userId');
        final profileResponse = await http.get(
          profileUrl,
          headers: headers,
        );

        if (profileResponse.statusCode == 200) {
          final profileData = json.decode(profileResponse.body);
          final communityIds = List<String>.from(profileData['result'][0]['communities'] ?? []);

          if (communityIds.isEmpty) {
            setState(() {
              isLoading = false;
            });
            return;
          }

          // Now fetch details for each community
          List<Community> fetchedCommunities = [];
          for (String communityId in communityIds) {
            await fetchCommunityInfo(communityId, headers, fetchedCommunities);
          }

          setState(() {
            communities = fetchedCommunities;
            isLoading = false;
          });
        } else {
          print('Error: ${profileResponse.statusCode} - ${profileResponse.body}');
          setState(() => isLoading = false);
        }
      } catch (e) {
        print('Error fetching communities: $e');
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCommunityInfo(String communityId, Map<String, String> headers, List<Community> fetchedCommunities) async {
    try {
      final Uri communityUrl = Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/communities/$communityId');
      final communityResponse = await http.get(
        communityUrl,
        headers: headers,
      );

      if (communityResponse.statusCode == 200) {
        final communityData = json.decode(communityResponse.body);
        // The API directly returns the community object, not nested in a 'result' field
        fetchedCommunities.add(Community.fromJson(communityData));
      } else {
        print('Error fetching community $communityId: ${communityResponse.statusCode} - ${communityResponse.body}');
      }
    } catch (e) {
      print('Error fetching community $communityId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: LoadingAnimationWidget.twistingDots(leftDotColor: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkText
                                      : AppColors.lightText, rightDotColor: Color(0xFF7400A5), size: 20),
      );
    }

    if (communities.isEmpty) {
      return Center(
        child: Text(
          'No Communities Joined Yet',
          style: GoogleFonts.roboto(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];

        return Padding(
          padding: EdgeInsets.only(left: 10.0.w, top: 10.h, right: 10.0.w),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              border: Border.all(color: Color(0xFF7400A5),)
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: community.profilePicture != null ? NetworkImage(community.profilePicture!) : AssetImage('assets/avatar/2.png') as ImageProvider,
                backgroundColor: Colors.purple.shade100,
              ),
              title: Text(
                community.name,
                style: GoogleFonts.roboto(
                  color: Color(0xFF7400A5),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                community.description ?? 'No description',
                style: GoogleFonts.roboto(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${community.membersCount} Members',
                style: GoogleFonts.roboto(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityDetailScreen(communityId: community.id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
