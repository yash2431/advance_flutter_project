import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../services/storage_service.dart';
import './record_controller.dart';

class RecordView extends GetView<RecordController> {
  RecordView({super.key});

  final StorageService _storageService = Get.find<StorageService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Voice'),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() {
                final duration = controller.currentDuration.value;
                final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
                final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
                final hours = duration.inHours > 0 ? '${duration.inHours.toString().padLeft(2, '0')}:' : '';

                return Text(
                  '$hours$minutes:$seconds',
                  style: Get.textTheme.headlineMedium?.copyWith(fontSize: 48),
                );
              }),
              const SizedBox(height: 30),

              Card(
                margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Obx(() => controller.isRecording.value
                      ? AudioWaveforms(
                    size: Size(Get.width * 0.8, 60),
                    recorderController: controller.recorderController,
                  )
                      : SizedBox(
                    width: Get.width * 0.8,
                    height: 60,
                    child: Center(
                      child: Text(
                        'Start recording...',
                        style: Get.textTheme.bodyMedium,
                      ),
                    ),
                  )),
                ),
              ),

              const Spacer(),
              _buildControlButtons(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => controller.navigateToListenScreen(),
                icon: const Icon(Icons.library_music),
                label: const Text('My Recordings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    final isDark = Get.isDarkMode; // true if dark mode

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Discard Button + Text
        Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'discardBtn',
              onPressed: controller.isRecording.value || controller.recordFilePath.isNotEmpty
                  ? () => controller.discardRecording()
                  : null,
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.delete_forever),
            ),
            const SizedBox(height: 6),
            Text(
              "Discard",
              style: TextStyle(
                color: isDark ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
              ),
            ),
          ],
        )),

        // Record Button + Text
        Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: FloatingActionButton(
                heroTag: 'recordBtn',
                onPressed: () => controller.toggleRecording(),
                backgroundColor: controller.isRecording.value
                    ? Colors.red
                    : Get.theme.colorScheme.primary,
                foregroundColor: Colors.white,
                child: Icon(
                  controller.isRecording.value ? Icons.stop : Icons.mic,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.isRecording.value ? "Stop" : "Record",
              style: TextStyle(
                color: isDark ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
              ),
            ),
          ],
        )),

        // Save Button + Text
        Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'saveBtn',
              onPressed: controller.recordFilePath.isNotEmpty && !controller.isRecording.value
                  ? () => controller.saveRecording()
                  : null,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.save),
            ),
            const SizedBox(height: 6),
            Text(
              "Save",
              style: TextStyle(
                color: isDark ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 200,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Get.isDarkMode
                        ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!]
                        : [Get.theme.colorScheme.primary, Get.theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: SvgPicture.asset(
                        'lib/assets/app_icon/voice_recorder_icon.svg',
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'App Version 1.0',
                      style: Get.textTheme.titleSmall?.copyWith(
                        color: Get.isDarkMode ? Colors.white70 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Obx(() => Icon(
                    _storageService.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                    color: Get.theme.iconTheme.color,
                  )),
                  title: Text(
                    'Appearance',
                    style: Get.textTheme.titleMedium,
                  ),
                  trailing: Obx(() => Switch(
                    value: _storageService.themeMode == ThemeMode.dark,
                    onChanged: (value) => controller.toggleTheme(),
                    activeColor: Get.theme.colorScheme.primary,
                    activeTrackColor: Get.theme.colorScheme.primary.withOpacity(0.3),
                    inactiveThumbColor: Get.theme.colorScheme.onSurface,
                    inactiveTrackColor: Get.theme.colorScheme.onSurface.withOpacity(0.3),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Icon(Icons.favorite, color: Get.theme.iconTheme.color),
                  title: Text('Favorites', style: Get.textTheme.titleMedium),
                  onTap: () {
                    Get.back();
                    controller.navigateToFavoritesScreen();
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Icon(Icons.restore_from_trash, color: Get.theme.iconTheme.color),
                  title: Text('Recently Deleted', style: Get.textTheme.titleMedium),
                  onTap: () {
                    Get.back();
                    controller.navigateToRecentlyDeletedScreen();
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Icon(Icons.settings, color: Get.theme.iconTheme.color),
                  title: Text('About Us', style: Get.textTheme.titleMedium),
                  onTap: () {
                    Get.back();
                    controller.navigateToAboutUsScreen();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
