import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

typedef SttResultCallback = void Function(SpeechRecognitionResult result);
typedef SttStatusCallback = void Function(String status);
typedef SttErrorCallback = void Function(String errorMsg);

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  final SttResultCallback onResult;
  final SttStatusCallback onStatus;
  final SttErrorCallback onError;
  String localeId;

  SpeechService({
    required this.localeId,
    required this.onResult,
    required this.onStatus,
    required this.onError,
  });

  Future<bool> initialize() async {
    try {
      bool initialized = await _speech.initialize(
        onError: (e) => onError('${e.errorMsg}: ${e.permanent ? "Permanent" : "Temporary"}'),
        onStatus: onStatus,
        debugLogging: true,
      );
      Get.log('SpeechService: Initialize result=$initialized');
      if (!initialized) {
        onError('initialization_failed: Speech recognition not available');
      }
      return initialized;
    } catch (e) {
      Get.log('SpeechService: Initialization failed: $e', isError: true);
      onError('initialization_failed: $e');
      return false;
    }
  }

  Future<List<LocaleName>> locales() async {
    try {
      return await _speech.locales();
    } catch (e) {
      Get.log('SpeechService: Fetch locales failed: $e', isError: true);
      onError('fetch_locales_failed: $e');
      return [];
    }
  }

  Future<bool> hasPermission() async {
    try {
      return await _speech.hasPermission;
    } catch (e) {
      Get.log('SpeechService: Permission check failed: $e', isError: true);
      onError('permission_check_failed: $e');
      return false;
    }
  }

  bool get isListening => _speech.isListening;

  Future<void> listen({bool onDevice = true, required Duration listenFor, required Duration pauseFor}) async {
    if (_speech.isListening) {
      Get.log('SpeechService: Already listening, stopping current session.');
      await _speech.stop();
      await Future.delayed(Duration(milliseconds: 50));
    }

    Get.log('SpeechService: Starting to listen for locale: $localeId');
    try {
      await _speech.listen(
        onResult: onResult,
        localeId: localeId,
        cancelOnError: false,
        partialResults: true,
        onDevice: onDevice,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      Get.log('SpeechService: Listen failed: $e', isError: true);
      onError('listen_failed: $e');
    }
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      Get.log('SpeechService: Stopping listening.');
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      Get.log('SpeechService: Cancelling listening.');
      await _speech.cancel();
    }
  }

  void dispose() {
    Get.log('SpeechService: Disposing.');
    cancel();
  }
}
