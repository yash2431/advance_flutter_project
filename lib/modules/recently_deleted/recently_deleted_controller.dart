// lib/app/modules/recently_deleted/recently_deleted_controller.dart
import 'dart:io';
import 'package:flutter/material.dart'; // For AlertDialog
import 'package:get/get.dart';
import '../../models/recording_model.dart';
import '../../services/audio_handler_service.dart';
import '../../services/database_service.dart'; // To stop background playback if active

class RecentlyDeletedController extends GetxController {
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final MyAudioHandler _audioHandler = Get.find<MyAudioHandler>();

  final RxList<Recording> deletedRecordings = <Recording>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeletedRecordings();
  }

  Future<void> fetchDeletedRecordings() async {
    isLoading.value = true;
    final recordings = await _databaseService.getRecordings(
      isDeleted: true, // Only fetch deleted ones
    );
    deletedRecordings.assignAll(recordings);
    isLoading.value = false;
  }

  Future<void> restoreRecording(Recording recording) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Restore Recording?'),
        content: Text('Are you sure you want to restore "${recording.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Restore'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      // Check if original file still exists before restoring, or handle missing file
      final file = File(recording.filePath);
      if (!(await file.exists())) {
        Get.snackbar('File Not Found', 'Original recording file for "${recording.name}" is missing. Cannot restore.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
        // Optionally, permanently delete from DB if file is truly gone.
        return;
      }

      await _databaseService.restoreRecording(recording.id!);
      await fetchDeletedRecordings(); // Refresh list
      Get.snackbar('Restored', '"${recording.name}" has been restored.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> permanentlyDeleteRecording(Recording recording) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text('This action cannot be undone. Are you sure you want to permanently delete "${recording.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        // Stop playback if this item is currently playing
        if (_audioHandler.mediaItem.value?.id == recording.filePath) {
          await _audioHandler.stop();
        }

        // 1. Delete file from storage
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // 2. Delete from database
        await _databaseService.deleteRecording(recording.id!);
        await fetchDeletedRecordings(); // Refresh list
        Get.snackbar('Deleted', '"${recording.name}" permanently deleted.',
            snackPosition: SnackPosition.BOTTOM);
      } catch (e) {
        Get.snackbar('Error', 'Failed to permanently delete: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }
}