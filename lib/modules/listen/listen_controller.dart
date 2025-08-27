import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audio_service/audio_service.dart';
import '../../models/recording_model.dart';
import '../../routes/app_routes.dart';
import '../../services/audio_handler_service.dart';
import '../../services/database_service.dart';

class ListenController extends GetxController {
  final DatabaseService databaseService = Get.find<DatabaseService>();
  final MyAudioHandler _audioHandler = Get.find<MyAudioHandler>();

  // Observable lists and variables
  final RxList<Recording> allRecordings = <Recording>[].obs;
  final RxList<Recording> filteredRecordings = <Recording>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchTerm = ''.obs;
  final Rx<DateTime?> filterDate = Rx<DateTime?>(null);

  final Rxn<Recording> currentlyPlaying = Rxn<Recording>();
  final Rx<PlayerState> playerState = PlayerState(
    playing: false,
    processingState: AudioProcessingState.idle,
  ).obs;
  final Rx<Duration> currentPlaybackPosition = Duration.zero.obs;

  late final StreamSubscription<PlaybackState> _playbackStateSubscription;
  late final StreamSubscription<MediaItem?> _mediaItemSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeAudioHandler();
    fetchRecordings();
    _listenToAudioService();
  }

  Future<void> requestPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.notification,
      Permission.microphone,
    ];
    for (var perm in permissions) {
      if (await perm.request().isGranted) {
        Get.log('${perm.toString()} granted');
      } else {
        Get.log('${perm.toString()} denied', isError: true);
        Get.snackbar(
          'Error',
          '${perm.toString()} required.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// Initializes the AudioHandler to ensure it's ready.
  Future<void> _initializeAudioHandler() async {
    try {
      await _audioHandler.init();
      Get.log('AudioHandler initialized successfully');
    } catch (e, stackTrace) {
      Get.log(
        'AudioHandler initialization error: $e\n$stackTrace',
        isError: true,
      );
      _showSnackbar(
        'Error',
        'Failed to initialize audio service: ${e.toString()}',
        backgroundColor: Colors.red.withValues(red: 0.8),
      );
    }
  }

  /// Sets up listeners for AudioService's playback state and media item changes.
  void _listenToAudioService() {
    _playbackStateSubscription = _audioHandler.playbackState.listen(
      (state) {
        playerState.value = PlayerState(
          playing: state.playing,
          processingState: state.processingState,
        );
        currentPlaybackPosition.value = state.updatePosition;
        Get.log(
          'Playback state updated: playing=${state.playing}, position=${state.updatePosition}',
        );
      },
      onError: (e, stackTrace) {
        Get.log('Playback state error: $e\n$stackTrace', isError: true);
        _showSnackbar(
          'Error',
          'Audio playback state error: ${e.toString()}',
          backgroundColor: Colors.red.withValues(red: 0.8),
        );
      },
    );

    _mediaItemSubscription = _audioHandler.mediaItem.listen(
      (mediaItem) {
        if (mediaItem != null) {
          final playing = allRecordings.firstWhereOrNull(
            (rec) => rec.filePath == mediaItem.id,
          );
          currentlyPlaying.value = playing;
          if (playing == null && mediaItem.id.isNotEmpty) {
            _showSnackbar(
              'Warning',
              'Currently playing recording not found in list.',
              backgroundColor: Colors.orange.withOpacity(0.8),
            );
          }
        } else {
          currentlyPlaying.value = null;
        }
        Get.log('Media item updated: ${mediaItem?.id ?? 'null'}');
      },
      onError: (e, stackTrace) {
        Get.log('Media item error: $e\n$stackTrace', isError: true);
        _showSnackbar(
          'Error',
          'Media item error: ${e.toString()}',
          backgroundColor: Colors.red.withValues(red: 0.8),
        );
      },
    );
  }

  /// Utility method to show snackbar with consistent styling.
  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor ?? Colors.blueAccent.withOpacity(0.8),
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Fetches all active recordings from the database and updates the filtered list.
  Future<void> fetchRecordings() async {
    isLoading.value = true;
    try {
      final recordings = await databaseService.getRecordings(
        isFavorite: null,
        isDeleted: false,
      );
      allRecordings.assignAll(recordings);
      applyFilter();
    } catch (e, stackTrace) {
      Get.log('Fetch recordings error: $e\n$stackTrace', isError: true);
      _showSnackbar(
        'Error',
        'Failed to fetch recordings: ${e.toString()}',
        backgroundColor: Colors.red.withValues(red: 0.8),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sets the search term and re-applies filters.
  void setSearchTerm(String term) {
    final newTerm = term.toLowerCase();
    if (searchTerm.value != newTerm) {
      searchTerm.value = newTerm;
      applyFilter();
    }
  }

  /// Sets the date filter and re-applies filters.
  void setFilterDate(DateTime? date) {
    if (filterDate.value != date) {
      filterDate.value = date;
      applyFilter();
    }
  }

  /// Applies the current search term and date filters to `allRecordings`.
  void applyFilter() {
    filteredRecordings.value = allRecordings.where((rec) {
      bool matches = true;
      if (searchTerm.value.isNotEmpty) {
        matches =
            rec.name.toLowerCase().contains(searchTerm.value) ||
            (rec.transcription?.toLowerCase().contains(searchTerm.value) ??
                false);
      }
      if (filterDate.value != null) {
        matches =
            matches &&
            rec.date.year == filterDate.value!.year &&
            rec.date.month == filterDate.value!.month &&
            rec.date.day == filterDate.value!.day;
      }
      return matches;
    }).toList();
  }

  /// Toggles the favorite status of a recording.
  Future<void> toggleFavorite(Recording recording) async {
    recording.isFavorite = !recording.isFavorite;
    try {
      await databaseService.updateRecording(recording);
      final indexAll = allRecordings.indexWhere((r) => r.id == recording.id);
      if (indexAll != -1) {
        allRecordings[indexAll] = recording;
        final indexFiltered = filteredRecordings.indexWhere(
          (r) => r.id == recording.id,
        );
        if (indexFiltered != -1) {
          filteredRecordings[indexFiltered] = recording;
        }
        applyFilter();
      }
      _showSnackbar(
        'Favorite Updated',
        '${recording.name} ${recording.isFavorite ? 'added to' : 'removed from'} favorites.',
        backgroundColor: Colors.green.withValues(green: 0.8),
      );
    } catch (e, stackTrace) {
      recording.isFavorite = !recording.isFavorite;
      Get.log('Toggle favorite error: $e\n$stackTrace', isError: true);
      _showSnackbar(
        'Error',
        'Failed to update favorite status: ${e.toString()}',
        backgroundColor: Colors.red.withValues(red: 0.8),
      );
    }
  }

  /// Soft-deletes a recording after user confirmation.
  Future<void> deleteRecording(Recording recording) async {
    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Move to Recently Deleted?'),
            content: Text(
              'Are you sure you want to move "${recording.name}" to recently deleted?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Move'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        await databaseService.softDeleteRecording(recording.id!);
        await fetchRecordings();
        _showSnackbar(
          'Moved to Trash',
          '"${recording.name}" moved to Recently Deleted.',
          backgroundColor: Colors.amber.withOpacity(0.8),
        );
      } catch (e, stackTrace) {
        Get.log('Delete recording error: $e\n$stackTrace', isError: true);
        _showSnackbar(
          'Error',
          'Failed to move to trash: ${e.toString()}',
          backgroundColor: Colors.red.withValues(red: 0.8),
        );
      }
    }
  }

  /// Rename a recording
  Future<void> renameRecording(Recording recording) async {
    final TextEditingController nameController = TextEditingController(
      text: recording.name,
    );
    try {
      final newName = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Rename Recording'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'New recording name'),
            autofocus: true,
            onSubmitted: (_) {
              if (nameController.text.trim().isNotEmpty) {
                Get.back(result: nameController.text.trim());
              } else {
                _showSnackbar(
                  'Invalid Name',
                  'Recording name cannot be empty.',
                  backgroundColor: Colors.red.withOpacity(0.8),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Get.back(result: nameController.text.trim());
                } else {
                  _showSnackbar(
                    'Invalid Name',
                    'Recording name cannot be empty.',
                    backgroundColor: Colors.red.withOpacity(0.8),
                  );
                }
              },
              child: const Text('Rename'),
            ),
          ],
        ),
      );

      if (newName != null && newName != recording.name) {
        try {
          final oldFile = File(recording.filePath);
          final sanitizedNewName = _sanitizeFileName(newName);
          final newFilePath =
              '${oldFile.parent.path}/$sanitizedNewName${_getFileExtension(recording.filePath)}';

          if (await oldFile.exists() && oldFile.parent.existsSync()) {
            final newFile = await oldFile.rename(newFilePath);
            recording.filePath = newFile.path;
            recording.name = sanitizedNewName;
            await databaseService.updateRecording(recording);
            await fetchRecordings();
            _showSnackbar(
              'Success',
              'Recording renamed to "$sanitizedNewName".',
              backgroundColor: Colors.green.withOpacity(0.8),
            );
          } else {
            recording.name = sanitizedNewName;
            await databaseService.updateRecording(recording);
            await fetchRecordings();
            _showSnackbar(
              'Warning',
              'Original recording file not found. Name updated in database only.',
              backgroundColor: Colors.orange.withOpacity(0.8),
            );
          }
        } catch (e, stackTrace) {
          Get.log('Rename recording error: $e\n$stackTrace', isError: true);
          _showSnackbar(
            'Error',
            'Failed to rename recording: ${e.toString()}',
            backgroundColor: Colors.red.withOpacity(0.8),
          );
        }
      }
    } finally {
      // Add a small delay to ensure the dialog widget has been completely removed
      // from the widget tree before the controller is disposed.
      await Future.delayed(const Duration(milliseconds: 100));
      nameController.dispose();
    }
  }

  // Keep your helper functions as they are
  String _sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, name.length > 50 ? 50 : name.length);
    return sanitized.isEmpty ? 'recording' : sanitized;
  }

  String _getFileExtension(String filePath) {
    final validExtensions = ['.m4a', '.mp3', '.wav'];
    for (final ext in validExtensions) {
      if (filePath.toLowerCase().endsWith(ext)) {
        return ext;
      }
    }
    return '.m4a';
  }

  /// Shares the recording file.
  Future<void> shareRecording(Recording recording) async {
    try {
      final file = File(recording.filePath);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(recording.filePath),
        ], text: 'Check out my recording: ${recording.name}');
        _showSnackbar(
          'Share Initiated',
          'Sharing "${recording.name}".',
          backgroundColor: Colors.blueAccent.withOpacity(0.8),
        );
      } else {
        _showSnackbar(
          'Error',
          'Recording file not found for sharing.',
          backgroundColor: Colors.red.withValues(red: 0.8),
        );
      }
    } catch (e, stackTrace) {
      Get.log('Share recording error: $e\n$stackTrace', isError: true);
      _showSnackbar(
        'Error',
        'Failed to share recording: ${e.toString()}',
        backgroundColor: Colors.red.withValues(red: 0.8),
      );
    }
  }

  /// Navigates to the edit screen for a specific recording.
  void navigateToEditScreen(Recording recording) {
    Get.toNamed(AppRoutes.EDIT, arguments: recording);
  }

  /// Toggles playback for a given recording (modified to redirect to edit screen).
  Future<void> togglePlayback(Recording recording) async {
    try {
      // Stop any ongoing playback to prevent conflicts
      if (playerState.value.playing) {
        await _audioHandler.stop();
        Get.log(
          'Stopped ongoing playback for: ${currentlyPlaying.value?.filePath}',
        );
      }

      // Redirect to edit screen instead of playing
      final file = File(recording.filePath);
      if (await file.exists()) {
        navigateToEditScreen(recording);
        Get.log('Navigated to edit screen for: ${recording.filePath}');
      } else {
        Get.log('File not found: ${recording.filePath}', isError: true);
        _showSnackbar(
          'Error',
          'Recording file not found.',
          backgroundColor: Colors.red.withValues(red: 0.8),
        );
      }
    } catch (e, stackTrace) {
      Get.log('Toggle playback error: $e\n$stackTrace', isError: true);
      await _audioHandler.stop();
      _showSnackbar(
        'Error',
        'Failed to process action: ${e.toString()}',
        backgroundColor: Colors.red.withValues(red: 0.8),
      );
    }
  }

  /// Formats a Duration object into HH:mm:ss string.
  String formatPlaybackPosition(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(position.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(position.inSeconds.remainder(60));
    return '${twoDigits(position.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void onClose() {
    _playbackStateSubscription.cancel();
    _mediaItemSubscription.cancel();
    _audioHandler.stop();
    super.onClose();
  }
}

class PlayerState {
  final bool playing;
  final AudioProcessingState processingState;

  PlayerState({required this.playing, required this.processingState});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          playing == other.playing &&
          processingState == other.processingState;

  @override
  int get hashCode => playing.hashCode ^ processingState.hashCode;
}
