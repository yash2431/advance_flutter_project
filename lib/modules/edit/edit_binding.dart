// lib/app/modules/edit/edit_binding.dart
import 'package:get/get.dart';

import './edit_controller.dart';

class EditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditController>(() => EditController());
  }
}