// lib/app/modules/recently_deleted/recently_deleted_binding.dart
import 'package:get/get.dart';

import './recently_deleted_controller.dart';

class RecentlyDeletedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecentlyDeletedController>(() => RecentlyDeletedController());
  }
}