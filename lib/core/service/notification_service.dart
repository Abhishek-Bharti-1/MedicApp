import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService notificationService =
      NotificationService._internal();
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static var instance;

  factory NotificationService() {
    return notificationService;
  }

  NotificationService._internal();

  init() {}
}
