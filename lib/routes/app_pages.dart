// lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import 'package:hacky_voice_recorder/modules/about_us/about_us.dart';
import 'package:hacky_voice_recorder/modules/edit/edit_binding.dart';
import 'package:hacky_voice_recorder/modules/splash/splash_screen.dart';
import '../modules/edit/edit_view.dart';
import '../modules/record/record_binding.dart';
import '../modules/record/record_view.dart';
import '../modules/listen/listen_binding.dart'; // Assuming you have these
import '../modules/listen/listen_view.dart';
import '../modules/favorite/favorite_binding.dart';
import '../modules/favorite/favorite_view.dart';
import '../modules/recently_deleted/recently_deleted_binding.dart';
import '../modules/recently_deleted/recently_deleted_view.dart';
import 'app_routes.dart'; // This is important for the AppRoutes class

class AppPages {
  // Define the initial route constant
  static const INITIAL = AppRoutes.RECORD; // Make sure Routes.RECORD exists in app_routes.dart!

  static final routes = [
    GetPage(
        name: AppRoutes.SPLASH,
        page: () => const SplashScreen()
    ),
    GetPage(
      name: AppRoutes.RECORD,
      page: () => RecordView(),
      binding: RecordBinding(),
    ),
    GetPage(
      name: AppRoutes.LISTEN,
      page: () => ListenView(),
      binding: ListenBinding(),
    ),
    GetPage(
      name: AppRoutes.EDIT,
      page: () => EditView(),
      binding: EditBinding(),
    ),
    GetPage(
      name: AppRoutes.FAVORITE,
      page: () => FavoriteView(),
      binding: FavoriteBinding(),
    ),
    GetPage(
      name: AppRoutes.RECENTLY_DELETED,
      page: () => RecentlyDeletedView(),
      binding: RecentlyDeletedBinding(),
    ),
    GetPage(
      name: AppRoutes.ABOUT_US,
      page: () => AboutUsPage(),
    ),
    // Add other pages here
  ];
}
