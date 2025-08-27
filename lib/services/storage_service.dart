import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Make sure Get is imported
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/app_constants.dart';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  // 1. Add an Rx variable for the current theme mode
  final _currentThemeMode = ThemeMode.system.obs; // Initialize with system default or light

  // 2. Provide a reactive getter for the themeMode
  ThemeMode get themeMode => _currentThemeMode.value;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load the initial theme mode from SharedPreferences and set the Rx variable
    final storedThemeString = _prefs.getString(AppConstants.THEME_MODE_KEY);
    switch (storedThemeString) {
      case 'light':
        _currentThemeMode.value = ThemeMode.light;
        break;
      case 'dark':
        _currentThemeMode.value = ThemeMode.dark;
        break;
      default:
        _currentThemeMode.value = ThemeMode.system;
        break;
    }
    return this;
  }

  // 3. Update the method that changes the theme to also update the Rx variable
  // You can combine setThemeMode and saveThemeMode if they do the same thing
  Future<void> saveThemeMode(ThemeMode mode) async {
    // Update the reactive variable first
    _currentThemeMode.value = mode;

    // Save to SharedPreferences
    await _prefs.setString(AppConstants.THEME_MODE_KEY, mode.name);

    // Get.changeThemeMode is now optional, as updating _currentThemeMode.value
    // will cause the Obx in GetMaterialApp to rebuild.
    // However, it doesn't hurt to keep it if you want to ensure immediate theme application.
    Get.changeThemeMode(mode);
  }

// You can remove or consolidate setThemeMode if saveThemeMode does the same job
// If you keep it, make sure it also updates _currentThemeMode.value
// Future<void> setThemeMode(ThemeMode themeMode) async {
//   _currentThemeMode.value = themeMode; // Important!
//   await _prefs.setString(AppConstants.THEME_MODE_KEY, themeMode.toString().split('.').last);
//   Get.changeThemeMode(themeMode);
// }
}