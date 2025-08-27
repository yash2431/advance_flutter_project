import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:intl/intl.dart';
import '../../models/recording_model.dart';
import '../../routes/app_routes.dart';
import '../../../utils/app_constants.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';

class RecordController extends GetxController {
  // Services
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Audio Recording
  final RecorderController recorderController = RecorderController()
    ..androidEncoder = AndroidEncoder.aac
    ..androidOutputFormat = AndroidOutputFormat.mpeg4
    ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
    ..sampleRate = 16000;

  // State Management
  final RxBool isRecording = false.obs;
  final Rx<Duration> currentDuration = Duration.zero.obs;
  final RxString _recordFilePath = ''.obs;
  final RxBool _isProcessing = false.obs;
  final RxBool _isRequestingPermissions = false.obs;

  // Timers
  Timer? _recordingTimer;
  DateTime? _recordStartTime;

  // Getters
  String get recordFilePath => _recordFilePath.value;
  bool get isProcessing => _isProcessing.value;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (_isRequestingPermissions.value) return; // Prevent concurrent requests
    _isRequestingPermissions.value = true;

    try {
      // Check microphone permission
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final micResult = await Permission.microphone.request();
        if (!micResult.isGranted) {
          if (await Permission.microphone.isPermanentlyDenied) {
            _showSnackbar(
              'Microphone Permission Denied',
              'Please enable microphone permission in settings to record audio.',
              backgroundColor: Colors.orange,
            );
            await openAppSettings();
          } else {
            _handleError('check permissions', Exception('Microphone permission denied'));
          }
          return;
        } else {
          _showSnackbar(
            'Microphone Permission Granted',
            'Microphone access enabled.',
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (e) {
      _handleError('check permissions', e);
    } finally {
      _isRequestingPermissions.value = false;
    }
  }

  Future<void> toggleRecording() async {
    if (_isProcessing.value || _isRequestingPermissions.value) return;
    _isProcessing.value = true;

    try {
      if (isRecording.value) {
        await stopRecording();
      } else {
        await startRecording();
      }
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> startRecording() async {
    try {
      if (!await Permission.microphone.isGranted) {
        final micResult = await Permission.microphone.request();
        if (!micResult.isGranted) {
          if (await Permission.microphone.isPermanentlyDenied) {
            _showSnackbar(
              'Microphone Permission Denied',
              'Please enable microphone permission in settings to record audio.',
              backgroundColor: Colors.orange,
            );
            await openAppSettings();
          }
          throw Exception('Microphone permission not granted');
        } else {
          _showSnackbar(
            'Microphone Permission Granted',
            'Microphone access enabled.',
            backgroundColor: Colors.green,
          );
        }
      }

      _recordFilePath.value = await _generateFilePath();
      await recorderController.record(path: _recordFilePath.value);

      await Future.delayed(Duration(milliseconds: 800));

      _startRecordingState();

      _showSnackbar(
        'Recording Started',
        'Recording voice',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _handleError('start recording', e);
      await _cleanupFailedRecording();
      rethrow;
    }
  }

  void _startRecordingState() {
    isRecording.value = true;
    _recordStartTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordStartTime != null) {
        currentDuration.value = DateTime.now().difference(_recordStartTime!);
      }
    });
  }

  Future<void> stopRecording() async {
    try {
      final path = await recorderController.stop();
      _recordFilePath.value = path ?? '';

      _stopRecordingState();

      if (_recordFilePath.value.isNotEmpty &&
          currentDuration.value.inMilliseconds >= AppConstants.MIN_RECORDING_DURATION_MS) {
        _showSnackbar(
          'Recording Stopped',
          'Recording saved temporarily',
          backgroundColor: Colors.blue,
        );
      } else {
        await discardRecording(deleteFile: true);
        _showSnackbar(
          'Recording Discarded',
          'Recording was too short',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      _handleError('stop recording', e);
      await _cleanupFailedRecording();
      rethrow;
    }
  }

  void _stopRecordingState() {
    isRecording.value = false;
    _recordingTimer?.cancel();
  }

  Future<void> _cleanupFailedRecording() async {
    _stopRecordingState();
    if (_recordFilePath.value.isNotEmpty) {
      await discardRecording(deleteFile: true);
    }
  }

  Future<String> _generateFilePath() async {
    try {
      final recordingsDir = await _getInternalStorageDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final randomId = DateTime.now().millisecondsSinceEpoch % 1000;
      return '${recordingsDir.path}/recording_${timestamp}_$randomId.m4a';
    } catch (e) {
      _handleError('generate file path', e);
      rethrow;
    }
  }

  Future<Directory> _getInternalStorageDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final internalDir = Directory('${dir.path}/${AppConstants.RECORDINGS_DIRECTORY}');
    if (!await internalDir.exists()) {
      await internalDir.create(recursive: true);
    }
    return internalDir;
  }

  Future<void> saveRecording() async {
    if (_isProcessing.value) return;
    _isProcessing.value = true;

    try {
      if (_recordFilePath.value.isEmpty || !File(_recordFilePath.value).existsSync()) {
        throw Exception('No valid recording to save');
      }

      if (currentDuration.value.inMilliseconds < AppConstants.MIN_RECORDING_DURATION_MS) {
        await discardRecording(deleteFile: true);
        throw Exception('Recording too short to save');
      }

      final file = File(_recordFilePath.value);
      final recordingName = 'Recording ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}';

      final newRecording = Recording(
        name: recordingName,
        filePath: _recordFilePath.value,
        date: DateTime.now(),
        duration: currentDuration.value,
        size: await file.length(),
      );

      final id = await _databaseService.insertRecording(newRecording);
      if (id <= 0) throw Exception('Failed to save to database');

      _showSnackbar(
        'Saved Successfully',
        'Recording "$recordingName" saved',
        backgroundColor: Colors.green,
      );

      _resetRecordingState();
    } catch (e) {
      _handleError('save recording', e);
      rethrow;
    } finally {
      _isProcessing.value = false;
    }
  }

  void _resetRecordingState() {
    _recordFilePath.value = '';
    currentDuration.value = Duration.zero;
  }

  Future<void> discardRecording({bool deleteFile = true}) async {
    try {
      _stopRecordingState();

      if (deleteFile && _recordFilePath.value.isNotEmpty) {
        final file = File(_recordFilePath.value);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _resetRecordingState();
    } catch (e) {
      _handleError('discard recording', e);
    }
  }

  void _handleError(String context, dynamic error, {bool isCritical = false}) {
    final message = error is Exception ? error.toString() : 'Unknown error';
    Get.log('Error in $context: $message');

    String userMessage;
    if (message.contains('permission')) {
      userMessage = 'Please enable permissions in settings to access storage or record audio. Using app-specific storage as fallback.';
    } else {
      userMessage = 'Operation failed. Please try again.';
    }

    _showSnackbar(
      'Error',
      userMessage,
      backgroundColor: isCritical ? Colors.red : Colors.orange,
      duration: Duration(seconds: isCritical ? 5 : 3),
    );
  }

  void _showSnackbar(String title, String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(10),
    );
  }

  void navigateToListenScreen() {
    Get.toNamed(AppRoutes.LISTEN);
  }

  void navigateToFavoritesScreen() {
    Get.toNamed(AppRoutes.FAVORITE);
  }

  void navigateToRecentlyDeletedScreen() {
    Get.toNamed(AppRoutes.RECENTLY_DELETED);
  }

  void navigateToAboutUsScreen(){
    Get.toNamed(AppRoutes.ABOUT_US);
  }

  void toggleTheme() {
    final currentThemeMode = _storageService.themeMode;
    final newThemeMode = currentThemeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _storageService.saveThemeMode(newThemeMode);
    Get.changeThemeMode(newThemeMode);
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    recorderController.dispose();
    super.onClose();
  }
}
