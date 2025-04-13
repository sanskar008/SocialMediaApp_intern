import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProviderall with ChangeNotifier {
  String? _userId;
  String? _userToken;
  String? _socketToken;
  String? _userName;
  String? _userprofile;
  int? _publicStatus;

  String? get userId => _userId;
  String? get userToken => _userToken;
  String? get socketToken => _socketToken;
  String? get userName => _userName;
  String? get userProfile => _userprofile;
  int? get publicStatus => _publicStatus;

  /// Save user data in SharedPreferences and update provider state
  Future<void> saveUserData(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _userToken = data['token'];
    _userId = data['userDetails']['_id'];
    _socketToken = data['socketToken'];
    _userName = data['userDetails']['name'];
    _userprofile = data['userDetails']['profilePic'];

    await prefs.setString('user_token', _userToken!);
    await prefs.setString('user_id', _userId!);
    await prefs.setString('socketToken', _socketToken!);
    await prefs.setString('user_name', _userName!);
    await prefs.setString('user_profile' , _userprofile!);

    notifyListeners(); // Notify UI to rebuild
  }

  /// Load user data from SharedPreferences
  Future<void> loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userToken = prefs.getString('user_token');
    _userId = prefs.getString('user_id');
    _socketToken = prefs.getString('socketToken');
    _userName = prefs.getString('user_name');
    _userprofile = prefs.getString('user_profile');

    notifyListeners();
  }

   void setPublicStatus(int status) {
    _publicStatus = status;
    notifyListeners();
  }

  /// Clear user data (for logout)
  Future<void> clearUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _userToken = null;
    _userId = null;
    _socketToken = null;
    _userName = null;
    _userprofile = null;

    notifyListeners();
  }
}
