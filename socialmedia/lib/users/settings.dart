import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/pages/onboarding_screens/privacyPolicyScreen.dart';
import 'package:socialmedia/pages/onboarding_screens/start_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/termsAndConditionsScreen.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/blocker_users.dart';
import 'package:socialmedia/users/change_password.dart';
import 'package:socialmedia/users/edit_profile.dart';
import 'package:socialmedia/users/public_private_toggle.dart';
import 'package:socialmedia/users/report_issue.dart';
import 'package:socialmedia/services/voice_settings.dart';
import 'package:socialmedia/users/reset_password.dart';
import 'package:socialmedia/utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  bool privacyLev;
  SettingsScreen({required this.privacyLev}); // Constructor

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProviderall userProvider;
  String currentVoice = 'Bon'; // Default voice name

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {});
    });
    _loadVoicePreference();
  }

  Future<void> _loadVoicePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentVoice = prefs.getString('chat_voice') ?? 'Bon';
    });
  }

  Future<void> _saveVoicePreference(String voiceName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_voice', voiceName);
    await prefs.setString('chat_title', voiceName == 'Bon' ? 'BonChat' : 'Sora');
    setState(() {
      currentVoice = voiceName;
    });
  }

  void _showPrivacyToast() {
    String message = widget.privacyLev
        ? "Privacy level is ON"
        : "Privacy level is OFF";

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    // Call clearUserData function from UserProvider
    userProvider.clearUserData();

  prefs.setString('loginstatus', '2');
  await prefs.remove('temp_userid');
  await prefs.remove('temp_token');
  await prefs.remove('socketTocken');

 

    // Show logout toast
    Fluttertoast.showToast(
      msg: "Logged out successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );

  // Navigate to Login Screen and remove all previous routes
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => StartScreen()), // Replace with your LoginScreen widget
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white, // Set background color to black
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        title: Text(
          'Settings',
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
        ),
        backgroundColor: Colors.black26, // Black app bar
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSettingsItem(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              // Navigate to Edit Profile Screen
              Navigator.push(context, MaterialPageRoute(builder: (context)=> EditProfileScreen(avatar: '', selectedInterests: <String>[])));
            },
          ),
          _buildSettingsItem(
            icon: Icons.record_voice_over,
            title: 'Voice Settings',
            onTap: () {
              _showVoiceSettingsDialog(context);
            },
          ),
          _buildSettingsItem(
            icon: Icons.report_problem,
            title: 'Report an Issue',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ReportIssueScreen()));
            },
          ),
          _buildSettingsItem(
            icon: Icons.lock,
            title: 'Account Privacy Status',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyToggleScreen()));
            },
          ),
          _buildSettingsItem(
            icon: Icons.block,
            title: 'Blocked Accounts',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => BlockedUsersScreen()));
            },
          ),
          _buildSettingsItem(
            icon: Icons.password_rounded,
            title: 'Change Password',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> ChangePasswordScreen()));
            },
          ),
          _buildSettingsItem(
            icon: Icons.note_alt_rounded,
            title: 'Terms & Conditions',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> TermsAndConditionsScreen()));
            },
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> PrivacyPolicyScreen()));
            },
          ),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              _logout(context);
            },
          ),

        ],
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
      ),
      onTap: onTap,
      trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, size: 16),
    );
  }

  void _showVoiceSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voice Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading:  Icon(Icons.male, color: Colors.blue),
                  title: Text(
                    'Michael',
                    style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                  ),
                  trailing: currentVoice == 'Bon' 
                    ? Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                  onTap: () async {
                    await _saveVoicePreference('Bon');
                    await VoiceSettings.setSelectedVoice('male');
                    Navigator.pop(context);
                    Fluttertoast.showToast(
                      msg: "Male voice selected - Paul activated",
                      toastLength: Toast.LENGTH_LONG,
                    );
                  },
                ),
                ListTile(
                  leading:  Icon(Icons.female, color: Colors.pink),
                  title: Text(
                    'Vanessa',
                    style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                  ),
                  trailing: currentVoice == 'Sora' 
                    ? Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                  onTap: () async {
                    await _saveVoicePreference('Sora');
                    await VoiceSettings.setSelectedVoice('female');
                    Navigator.pop(context);
                    Fluttertoast.showToast(
                      msg: "Female voice selected - Sora activated",
                      toastLength: Toast.LENGTH_LONG,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
