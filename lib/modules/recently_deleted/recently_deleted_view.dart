// lib/app/modules/recently_deleted/recently_deleted_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './recently_deleted_controller.dart';

class RecentlyDeletedView extends GetView<RecentlyDeletedController> {
  const RecentlyDeletedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Deleted'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.deletedRecordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restore_from_trash, size: 60, color: Get.theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  'No recently deleted recordings.',
                  style: Get.textTheme.headlineSmall?.copyWith(color: Get.theme.disabledColor),
                ),
              ],
            ),
          );
        } else {
          return ListView.builder(
            itemCount: controller.deletedRecordings.length,
            itemBuilder: (context, index) {
              final recording = controller.deletedRecordings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.folder_delete, color: Colors.redAccent),
                  title: Text(
                    recording.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Get.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${recording.formattedDate} • ${recording.formattedDuration} • ${recording.formattedSize}',
                    style: Get.textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        tooltip: 'Restore',
                        onPressed: () => controller.restoreRecording(recording),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Delete Permanently',
                        onPressed: () => controller.permanentlyDeleteRecording(recording),
                      ),
                    ],
                  ),
                  // Optionally, tap to see details or play (if you implement player here)
                  onTap: () {
                    // Could show a dialog with details or allow playing
                    Get.snackbar('Deleted Item', 'This item is in trash. Restore to play/edit.',
                        snackPosition: SnackPosition.BOTTOM);
                  },
                ),
              );
            },
          );
        }
      }),
    );
  }
}
