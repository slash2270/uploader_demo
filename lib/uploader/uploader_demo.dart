// ignore_for_file: public_member_api_docs
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uploader_demo/uploader/upload_response_screen.dart';
import 'package:uploader_demo/uploader/uploader_screen.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String title = 'FileUpload Sample Demo';
final Uri uploadURL = Uri.parse(
  'https://us-central1-flutteruploadertest.cloudfunctions.net/upload',
);

FlutterUploader _uploader = FlutterUploader();

void backgroundHandler() {
  WidgetsFlutterBinding.ensureInitialized();

  // 注意這些實例屬於一個分叉的隔離。
  var uploader = FlutterUploader();

  var notifications = FlutterLocalNotificationsPlugin();

  // 僅顯示未處理上傳的通知。
  SharedPreferences.getInstance().then((preferences) {
    var processed = preferences.getStringList('processed') ?? <String>[];

    if (Platform.isAndroid) {
      uploader.progress.listen((progress) {
        if (processed.contains(progress.taskId)) {
          return;
        }

        notifications.show(
          progress.taskId.hashCode,
          'FlutterUploader Example',
          'Upload in Progress',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'FlutterUploader.Example',
              'FlutterUploader',
              channelDescription:
              'Installed when you activate the Flutter Uploader Example',
              progress: progress.progress ?? 0,
              icon: 'ic_upload',
              enableVibration: false,
              importance: Importance.low,
              showProgress: true,
              onlyAlertOnce: true,
              maxProgress: 100,
              channelShowBadge: false,
            ),
            iOS: const IOSNotificationDetails(),
          ),
        );
      });
    }

    uploader.result.listen((result) {
      if (processed.contains(result.taskId)) {
        return;
      }

      processed.add(result.taskId);
      preferences.setStringList('processed', processed);

      notifications.cancel(result.taskId.hashCode);

      final successful = result.status == UploadTaskStatus.complete;

      var title = 'Upload Complete';
      if (result.status == UploadTaskStatus.failed) {
        title = 'Upload Failed';
      } else if (result.status == UploadTaskStatus.canceled) {
        title = 'Upload Canceled';
      }

      notifications
          .show(
        result.taskId.hashCode,
        'FlutterUploader Example',
        title,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'FlutterUploader.Example',
            'FlutterUploader',
            channelDescription:
            'Installed when you activate the Flutter Uploader Example',
            icon: 'ic_upload',
            enableVibration: !successful,
            importance: result.status == UploadTaskStatus.failed
                ? Importance.high
                : Importance.min,
          ),
          iOS: const IOSNotificationDetails(
            presentAlert: true,
          ),
        ),
      )
          .catchError((e, stack) {
        print('error while showing notification: $e, $stack');
      });
    });
  });
}

class UploadDemo extends StatefulWidget {
  const UploadDemo({Key? key}) : super(key: key);

  @override
  _UploadDemoState createState() => _UploadDemoState();
}

class _UploadDemoState extends State<UploadDemo> {
  int _currentIndex = 0;

  bool allowCellular = true;

  @override
  void initState() {
    super.initState();

    _uploader.setBackgroundHandler(backgroundHandler);

    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
    const AndroidInitializationSettings('ic_upload');
    var initializationSettingsIOS = IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {},
    );
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (payload) async {},
    );

    SharedPreferences.getInstance()
        .then((sp) => sp.getBool('allowCellular') ?? true)
        .then((result) {
      if (mounted) {
        setState(() {
          allowCellular = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(allowCellular
                  ? Icons.signal_cellular_connected_no_internet_4_bar
                  : Icons.wifi_outlined),
              onPressed: () async {
                final sp = await SharedPreferences.getInstance();
                await sp.setBool('allowCellular', !allowCellular);
                if (mounted) {
                  setState(() {
                    allowCellular = !allowCellular;
                  });
                }
              },
            ),
          ],
        ),
        body: _currentIndex == 0
            ? UploadScreen(
          uploader: _uploader,
          uploadURL: uploadURL,
          onUploadStarted: () {
            setState(() => _currentIndex = 1);
          },
        )
            : UploadResponsesScreen(
          uploader: _uploader,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Responses',
            ),
          ],
          onTap: (newIndex) {
            setState(() => _currentIndex = newIndex);
          },
          currentIndex: _currentIndex,
        ),
      ),
    );
  }
}