// lib/app/modules/record/record_binding.dart
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart'; // Import SpeechToText

import './record_controller.dart';

class RecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpeechToText>(() => SpeechToText()); // Initialize SpeechToText
    Get.lazyPut<RecordController>(() => RecordController());
  }
}