// lib/app/modules/listen/listen_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:audio_service/audio_service.dart';
import './listen_controller.dart';

class ListenView extends GetView<ListenController> {
  const ListenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recordings'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0), // Adjust height for search and filter
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => controller.setSearchTerm(value),
                  decoration: InputDecoration(
                    hintText: 'Search by name or transcription...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Get.theme.cardColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => ElevatedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: controller.filterDate.value ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            controller.setFilterDate(picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(controller.filterDate.value == null
                            ? 'Filter by Date'
                            : DateFormat('MMM dd, yyyy').format(controller.filterDate.value!)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Get.theme.cardColor,
                          foregroundColor: Get.theme.textTheme.bodyLarge?.color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )),
                    ),
                    if (controller.filterDate.value != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => controller.setFilterDate(null),
                        color: Get.theme.iconTheme.color,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.filteredRecordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.audiotrack, size: 60, color: Get.theme.disabledColor),
                const SizedBox(height: 16),
                Text(
                  'No recordings found.',
                  style: Get.textTheme.headlineSmall?.copyWith(color: Get.theme.disabledColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Recording'),
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
                                recording.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: recording.isFavorite ? Colors.redAccent : Get.theme.iconTheme.color,
                              ),
                              onPressed: () => controller.toggleFavorite(recording),
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
                        onTap: () => controller.togglePlayback(recording), // Tap to play/pause
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
                      if (isPlayingThis) // Show current time and total duration when playing
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
