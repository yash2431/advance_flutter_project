// lib/app/modules/favorite/favorite_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart'; // For AudioProcessingState
import './favorite_controller.dart';

class FavoriteView extends GetView<FavoriteController> {
  const FavoriteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Recordings'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.filteredRecordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 60, color: Get.theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  'No favorite recordings yet.',
                  style: Get.textTheme.headlineSmall?.copyWith(color: Get.theme.disabledColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.back(), // Go back to Listen or Record screen
                  icon: const Icon(Icons.library_music),
                  label: const Text('View All Recordings'),
                ),
              ],
            ),
          );
        } else {
          return ListView.builder(
            itemCount: controller.filteredRecordings.length,
            itemBuilder: (context, index) {
              final recording = controller.filteredRecordings[index];
              final isPlayingThis = controller.currentlyPlaying.value?.id == recording.filePath;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isPlayingThis && controller.playerState.value.playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Get.theme.colorScheme.primary,
                            size: 40,
                          ),
                          onPressed: () => controller.togglePlayback(recording),
                        ),
                        title: Text(
                          recording.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPlayingThis ? Get.theme.colorScheme.primary : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${recording.formattedDate} • ${recording.formattedDuration} • ${recording.formattedSize}',
                              style: Get.textTheme.bodySmall,
                            ),
                            if (recording.transcription != null && recording.transcription!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  recording.transcription!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Get.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.favorite, // Always filled heart for favorites screen
                                color: Colors.redAccent,
                              ),
                              onPressed: () => controller.toggleFavorite(recording), // Unfavorite on click
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  controller.navigateToEditScreen(recording);
                                } else if (value == 'rename') {
                                  controller.renameRecording(recording);
                                } else if (value == 'share') {
                                  controller.shareRecording(recording);
                                } else if (value == 'delete') {
                                  controller.deleteRecording(recording);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Rename'),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Text('Share'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => controller.togglePlayback(recording),
                      ),
                      if (isPlayingThis && controller.playerState.value.processingState == AudioProcessingState.ready)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: LinearProgressIndicator(
                            value: recording.duration.inMilliseconds > 0
                                ? controller.currentPlaybackPosition.value.inMilliseconds / recording.duration.inMilliseconds
                                : 0.0,
                            backgroundColor: Get.theme.disabledColor.withOpacity(0.3),
                            color: Get.theme.colorScheme.primary,
                          ),
                        ),
                      if (isPlayingThis)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 16.0, right: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Obx(() => Text(
                                controller.formatPlaybackPosition(controller.currentPlaybackPosition.value),
                                style: Get.textTheme.bodySmall,
                              )),
                              Text(
                                recording.formattedDuration,
                                style: Get.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }),
    );
  }
}
