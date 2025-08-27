import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hacky_voice_recorder/modules/splash/connectivity_controller.dart';
import 'package:hacky_voice_recorder/routes/app_pages.dart';
import 'package:hacky_voice_recorder/routes/app_routes.dart';
import 'package:hacky_voice_recorder/services/audio_handler_service.dart';
import 'package:hacky_voice_recorder/services/database_service.dart';
import 'package:hacky_voice_recorder/services/storage_service.dart';
import 'package:hacky_voice_recorder/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize notification channel for Android 8.0+
  if (Platform.isAndroid) {
    const platform = MethodChannel('com.example.hacky_voice_recorder/notification');
    try {
      await platform.invokeMethod('createNotificationChannel', {
        'id': 'com.voice_recorder_app.channel.audio',
        'name': 'Voice Recorder Playback',
        'description': 'Controls playback of recorded audio',
        'importance': 3, // NotificationManager.IMPORTANCE_DEFAULT
      });
      Get.log('Notification channel created');
    } catch (e) {
      Get.log('Failed to create notification channel: $e', isError: true);
    }
  }

  // Initialize essential services
  Get.put(ConnectivityController());
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => DatabaseService().init());
  Get.put(SpeechToText());

  // Initialize audio_service
  try {
    final MyAudioHandler audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.voice_recorder_app.channel.audio',
        androidNotificationChannelName: 'Voice Recorder Playback',
        androidNotificationChannelDescription: 'Controls playback of recorded audio.',
        androidNotificationIcon: 'mipmap/ic_launcher',// Use verified icon
        androidStopForegroundOnPause: true,
        androidShowNotificationBadge: false, // Disable badge to avoid issues
      ),
    );
    Get.put<MyAudioHandler>(audioHandler);
    Get.log('AudioService initialized successfully');
  } catch (e, stackTrace) {
    Get.log('AudioService initialization failed: $e\n$stackTrace', isError: true);
    Get.snackbar('Error', 'Failed to initialize audio service: $e', backgroundColor: Colors.red);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final StorageService storageService = Get.find<StorageService>();

    return Obx(
          () => GetMaterialApp(
        title: 'Voice Recorder',
        initialRoute: AppRoutes.SPLASH,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: storageService.themeMode,
        builder: (context, child) {
          return child!;
        },
      ),
    );
  }
}
