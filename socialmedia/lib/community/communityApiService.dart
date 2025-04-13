import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socialmedia/community/communityModel.dart';
import 'package:socialmedia/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'community.dart';

class CommunityService {
  late SharedPreferences prefs;
  String? token;

  CommunityService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('user_token');
  }

  static const String url = 'https://bond-bridge-admin-dashboard.vercel.app/api/communities';
  static Future<List<Community>> fetchCommunities() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> communitiesJson = jsonResponse['communities'];
      return communitiesJson.map((json) => Community.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load communities');
    }
  }

  Future<bool> joinOrLeaveCommunity(String userId, String communityId, String action) async {
    // Make sure initialization is complete
    // if (prefs == null) {
    //   await _initPrefs();
    // }
    if (token == null) {
      await _initPrefs();
    }
    final url = Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/users/joincommunity');
    final headers = {
      'Content-Type': 'application/json',
      'userId': userId,
      if (token != null) 'token': token!,
      'Authorization': 'Basic Og==',
    };
    final body = jsonEncode({
      'userId': userId,
      'communityId': communityId,
      'action': action, //
    });
    print(token);
    print('################@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    try {
      final response = await http.post(url, headers: headers, body: body);
      print(token);
      if (response.statusCode == 200) {
        print('Successfully performed action: $action');
        return true; // Return true on success
      } else {
        print('Failed to perform action: $action. Status code: ${response.statusCode}');
        return false; // Return false on failure
      }
    } catch (e) {
      print(token);
      print('An error occurred: $e');
      return false; // Return false on exception
    }
    
  }

  Future<bool> joinMultipleCommunities(String userId, List<String> communityIds) async {
    if (token == null) {
      await _initPrefs();
    }

    final url = Uri.parse('https://bond-bridge-admin-dashboard.vercel.app/api/users/joinmultiplecommunities');
    final headers = {
      'Content-Type': 'application/json',
      'userId': userId,
      if (token != null) 'token': token!,
      'Authorization': 'Basic Og==',
    };

    final body = jsonEncode({
      'userId': userId,
      'communityIds': communityIds,
      'action': 'join'
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('Successfully joined multiple communities');
        return true;
      } else {
        print('Failed to join communities. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('An error occurred: $e');
      return false;
    }
  }


  // Future<List<Community>> fetchUserCommunities(String userId) async {
  //   final url = Uri.parse('${BASE_URL_COMMUNITIES}api/users/$userId');
  //   print('Fetching communities from URL: $url');

  //   try {
  //     final response = await http.get(url);
  //     print('Response status code: ${response.statusCode}');
  //     print('Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       print('Decoded data: $data');

  //       if (data['communities'] != null && data['communities'] is List) {
  //         final communities = (data['communities'] as List).map((community) => Community.fromJson(community)).toList();
  //         print('Parsed communities: $communities');
  //         return communities;
  //       } else {
  //         print('No communities found in the response');
  //       }
  //     } else {
  //       print('Failed to fetch communities. Status code: ${response.statusCode}');
  //     }

  //     return [];
  //   } catch (e) {
  //     print('Error fetching communities: $e');
  //     return [];
  //   }
  // }
}
