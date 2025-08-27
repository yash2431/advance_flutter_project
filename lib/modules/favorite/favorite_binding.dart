// lib/app/modules/favorite/favorite_binding.dart
import 'package:get/get.dart';

import './favorite_controller.dart';

class FavoriteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoriteController>(() => FavoriteController());
  }
}