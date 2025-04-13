import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/bottom_nav_bar/activity/chatProvider.dart';
import 'package:socialmedia/bottom_nav_bar/bottom_nav.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/add_reaction.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/postProvider.dart';
import 'package:socialmedia/community/communityProvider.dart';
import 'package:socialmedia/firebase_options.dart';
import 'package:socialmedia/pages/onboarding_screens/avatar_selection.dart';
import 'package:socialmedia/pages/onboarding_screens/interests.dart';
import 'package:socialmedia/pages/onboarding_screens/login_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/otp_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/signup_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/start_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/user_input_fields.dart';
import 'package:socialmedia/services/call_manager.dart';
import 'package:socialmedia/services/chat_socket_service.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/utils/colors.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initLocalNotifications();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  

  

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("User granted permission");
  } else {
    print("User denied permission");
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Set the system UI mode to show only the top status bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? isLoggedIn = prefs.getString('loginstatus');
  print("App restarted - loginstatus: $isLoggedIn"); // Debug log

  Widget initialScreen = await getInitialScreen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserProviderall()),
        ChangeNotifierProvider(create: (_) => ReactionsProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(430, 930),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MyApp(initialScreen: initialScreen);
        },
      ),
    ),
  );
}



Future<Widget> getInitialScreen() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String isLoggedIn = prefs.getString('loginstatus') ?? '0';
  String tempuserid = prefs.getString('temp_userid') ?? '';
  String temptoken = prefs.getString('temp_token') ?? '';
  String? userId = prefs.getString('user_id');
  String? token = prefs.getString('user_token');

  if (isLoggedIn == '1') {
    return UserInputFields(
      userid: tempuserid,
      token: temptoken,
    ); // Navigate to Home
  } else if (isLoggedIn == '2') {
    return LoginScreen(); // Navigate to Signup if onboarding is done but not logged in
  } else if (isLoggedIn == '3' && userId != null && token != null) {
    callingbackgroundnotif();
    return BottomNavBarScreen(); // Navigate to Start Screen if first-time user
  } else {
    return StartScreen();
  }
}

void callingbackgroundnotif(){

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("New Notification: ${message.notification}");

    // Show notification
    var androidDetails = const AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notificationn', // Make sure this matches your icon name
    );

    var iosDetails = const DarwinNotificationDetails();
    var generalDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    localNotifications.show(
      0,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      generalDetails,
    );
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print("Notification clicked: ${message.notification?.title}");
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("User clicked notification: ${message.notification?.title}");
  });

  }



class MyApp extends StatefulWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final CallManager _callManager = CallManager();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    getFCMToken();
    
  }

  

  

  Future<void> _initializeServices() async {
    await _socketService.connect();
    await _callManager.initialize();
  }

  Future<void> getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("App resumed");
        _socketService.connect();
        _callManager.initialize();
        break;
      case AppLifecycleState.inactive:
        print("App inactive");
        break;
      case AppLifecycleState.paused:
        print("App paused");
        break;
      case AppLifecycleState.detached:
        print("App detached");
        _socketService.disconnect();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppNotification(
      child: MaterialApp(
        navigatorKey: CallManager.navigatorKey,
        theme: ThemeData(
            brightness: Brightness.light, primaryColor: AppColors.lightPrimary),
        darkTheme: ThemeData(
            brightness: Brightness.dark, primaryColor: AppColors.darkPrimary),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: widget.initialScreen,
        ),
      ),
    );
  }
}

FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

void initLocalNotifications() {
  var androidSettings = const AndroidInitializationSettings(
      'ic_notificationn'); // Match your filename
  var iosSettings = const DarwinInitializationSettings();
  var initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  localNotifications.initialize(initSettings);
}


// void main() {
//   runApp(
//     ScreenUtilInit(
//       designSize: const Size(430, 932), // Set to your design's base size
//       minTextAdapt: true, // Optional, for text scaling
//       splitScreenMode: true, // Optional, to support multi-screen
//       builder: (context, child) {
//         return MaterialApp(
//           theme: ThemeData(
//             brightness: Brightness.light,
//             primaryColor: AppColors.lightPrimary,

//           ),
//           darkTheme: ThemeData(
//             brightness: Brightness.dark,
//             primaryColor: AppColors.darkPrimary,
//           ),
//           themeMode: ThemeMode.system,
//           debugShowCheckedModeBanner: false,
//           home:  StartScreen(), // Set `Check` as your home widget
//         );
//       },
//     ),
//   );
// }



