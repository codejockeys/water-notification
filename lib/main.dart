import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:developer' as dev;

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  await Firebase.initializeApp();
  dev.log("A background message has been received: ${msg.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  tz.initializeTimeZones();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController taskController = TextEditingController();
  final selectItems = ['Seconds', 'Minutes', 'Hours'];
  String selectionValue = 'Seconds';
  final timeItems = [1, 5, 10, 15, 20];
  int timeValue = 1;


  @override
  void initState() {
    super.initState();
    int inSeconds = 1;
    if (selectionValue == 'Minutes') {
      inSeconds = timeValue * 60;
    }
    if (selectionValue == 'Hours') {
      inSeconds = timeValue * 3600;
    }
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.zonedSchedule(
            notification.hashCode,
            notification.title,
            notification.body,
            tz.TZDateTime.now(tz.local).add(Duration(seconds: inSeconds)),
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int inSeconds = 1;
    if (selectionValue == 'Minutes') {
      inSeconds = timeValue * 60;
    }
    if (selectionValue == 'Hours') {
      inSeconds = timeValue * 3600;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Water Notifications"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                hintText: "Enter your task",
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  DropdownButton<String>(
                    hint: const Text("type"),
                    value: selectionValue,
                    items: selectItems.map(buildSelectionItem).toList(),
                    onChanged: (value) => setState(
                      () {
                        selectionValue = value!;
                        dev.log("Selection: $selectionValue");
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 150,
                  ),
                  DropdownButton<int>(
                    value: timeValue,
                    hint: const Text("time"),
                    items: timeItems.map(buildTimeItem).toList(),
                    onChanged: (value) => setState(
                      () {
                        timeValue = value!;
                        dev.log("Time delay: $timeValue");
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 160,
            ),
            ElevatedButton(
              onPressed: () {
                dev.log("Request to schedule notification!");

                flutterLocalNotificationsPlugin.zonedSchedule(
                  0, //do not change this value
                  "Water Notification",
                  taskController.text,
                  tz.TZDateTime.now(tz.local).add(
                    Duration(seconds: inSeconds),
                  ),
                  NotificationDetails(
                    android: AndroidNotificationDetails(
                        channel.id, channel.name,
                        channelDescription: channel.description,
                        importance: Importance.high,
                        color: Colors.blue,
                        playSound: true,
                        styleInformation: const BigPictureStyleInformation(
                          DrawableResourceAndroidBitmap("@mipmap/ic_launcher"),
                          largeIcon: DrawableResourceAndroidBitmap(
                              "@mipmap/ic_launcher"),
                          htmlFormatContent: true,
                          htmlFormatContentTitle: true,
                        ),
                        icon: '@mipmap/ic_launcher'),
                  ),
                  androidAllowWhileIdle: true,
                  uiLocalNotificationDateInterpretation:
                      UILocalNotificationDateInterpretation.absoluteTime,
                );
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("schedule notification"),
            ),
            const SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {
                dev.log("Request to cancel schedule notification!");
                flutterLocalNotificationsPlugin.cancel(0);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("cancel schedule notification"),
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> buildSelectionItem(String item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
        ),
      );

  DropdownMenuItem<int> buildTimeItem(int item) => DropdownMenuItem(
        value: item,
        child: Text(
          item.toString(),
        ),
      );
}
