import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medicapp/core/const/color_constants.dart';
import 'package:medicapp/core/service/notification_service.dart';
import 'package:medicapp/screens/onboarding/page/onboarding_page.dart';
import 'package:medicapp/screens/role_select/role_select_page.dart';
import 'package:medicapp/screens/tab_bar/page/tab_bar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medicapp/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp();
  await _requestPermissions();
  await NotificationServices.instance.initialize();
  runApp(MyApp()); 
}
Future<void> _requestPermissions() async {
  // Define the permissions to request
  List<Permission> permissions = [
    Permission.camera,
    Permission.location,
  ];

  // Request all permissions
  Map<Permission, PermissionStatus> statuses = await permissions.request();

  // Handle each permission status
  statuses.forEach((permission, status) {
    if (status.isGranted) {
      print('${permission.toString().split('.').last} permission granted.');
    } else if (status.isDenied) {
      print('${permission.toString().split('.').last} permission denied.');
    } else if (status.isPermanentlyDenied) {
      print(
          '${permission.toString().split('.').last} permission permanently denied. Please enable it from settings.');
      // Optionally, open app settings:
      openAppSettings();
    } else if (status.isRestricted) {
      print(
          '${permission.toString().split('.').last} permission is restricted.');
    }
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
   String? _role;
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = NotificationService.flutterLocalNotificationsPlugin;

  @override
  initState() {
    super.initState();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsDarwin);

    // tz.initializeTimeZones();
    _loadRole();


    //flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: selectNotification);
  }

   Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('userRole') ?? 'No role selected';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medic App',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(color: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                Brightness.dark, // Change based on your theme
          ),
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: ColorConstants.textColor)),
        fontFamily: 'NotoSansKR',
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn?TabBarPage(role: _role): OnboardingPage(),
    );
  }

  Future selectNotification(String? payload) async {
    showDialog(
      context: context,
      builder: (_) {
        return new AlertDialog(
          title: const Text("PayLoad"),
          content: Text("Payload : $payload"),
        );
      },
    );
  }
}
