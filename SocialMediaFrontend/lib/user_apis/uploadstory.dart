import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';

class StoryService {
  // Method to upload a story
  Future<void> uploadStory(
    File imageeFile) async{
     
    final url = Uri.parse('${BASE_URL}api/upload-story');
    final request = http.MultipartRequest('POST', url);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('user_id') ?? '';
    final String token = prefs.getString('user_token') ?? '';

    request.headers['userId'] = userId;
    request.headers['token'] = token;

    request.fields['privacy'] = '1';
    request.fields['contentType'] = 'image';

    final imageFile = await http.MultipartFile.fromPath('image', imageeFile.path);
    request.files.add(imageFile);

    try {
      final response = await request.send();
      
      if (response.statusCode == 200) {
        print('Story uploaded successfully');
      } else {
        print('Failed to upload story. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading story: $e');
    }
  }
}


