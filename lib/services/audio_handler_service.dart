import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';
import '../models/recording_model.dart';
import 'database_service.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final databaseService = Get.find<DatabaseService>();
  bool _isLooping = false; // Track looping state for continuous playback
  bool _isInitialized = false; // Track initialization state

  MyAudioHandler() {
    // Initialize playback state with default controls and actions
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.play,
        MediaControl.pause,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
        MediaAction.seek,
      },
      playing: false,
      processingState: AudioProcessingState.idle,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
    ));
    Get.log('MyAudioHandler instantiated');
  }

  /// Initializes the audio handler and player.
  Future<void> init() async {
    if (_isInitialized) {
      Get.log('MyAudioHandler already initialized');
      return;
    }

    try {
      // Configure audio session for Android/iOS
      await _player.setAudioSource(ConcatenatingAudioSource(children: []));
      await _player.setAutomaticallyWaitsToMinimizeStalling(true);
      // Set audio session category for playback
      await _player.setVolume(1.0); // Ensure default volume
      _isInitialized = true;
      Get.log('MyAudioHandler initialized successfully for audio_service: ^0.18.18, just_audio: ^0.10.4');
    } catch (e, stackTrace) {
      _isInitialized = false;
      Get.log('AudioHandler initialization error: $e\n$stackTrace', isError: true);
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
      throw Exception('Failed to initialize AudioHandler: $e');
    }
  }

  /// Resets the player to a clean state for new playback.
  Future<void> resetPlayer() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
      await _player.setAudioSource(ConcatenatingAudioSource(children: []));
      mediaItem.add(null);
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
      ));
      Get.log('Player reset successfully');
    } catch (e, stackTrace) {
      Get.log('Error in resetPlayer: $e\n$stackTrace', isError: true);
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
      throw Exception('Failed to reset player: $e');
    }
  }

  /// Consolidated listener for player events.
  void _listenForPlayerEvents() {
    // Duration changes
    _player.durationStream.listen((duration) {
      final currentMediaItem = mediaItem.value;
      if (duration != null && currentMediaItem != null) {
        mediaItem.add(currentMediaItem.copyWith(duration: duration));
        Get.log('Updated media item duration: $duration');
      }
    }, onError: (e, stackTrace) {
      Get.log('Duration stream error: $e\n$stackTrace', isError: true);
    });

    // Player state changes
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      try {
        final processingState = _getAudioProcessingState(playerState.processingState);
        playbackState.add(playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: {
            MediaAction.play,
            MediaAction.pause,
            MediaAction.stop,
            MediaAction.seek,
          },
          processingState: processingState,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _player.currentIndex ?? 0,
        ));
        Get.log('Player state updated: playing=$playing, processingState=$processingState');

        // Handle completion for multiple playbacks
        if (playerState.processingState == ProcessingState.completed) {
          if (_isLooping) {
            _player.seek(Duration.zero);
            _player.play();
            Get.log('Looping enabled, restarting playback');
          } else {
            resetPlayer(); // Prepare for next playback
            Get.log('Playback completed, player reset for replay');
          }
        }
      } catch (e, stackTrace) {
        Get.log('Error updating playback state: $e\n$stackTrace', isError: true);
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.stop],
          systemActions: {MediaAction.stop},
          playing: false,
          processingState: AudioProcessingState.error,
        ));
      }
    }, onError: (e, stackTrace) {
      Get.log('Player state stream error: $e\n$stackTrace', isError: true);
    });

    // Position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
      ));
      Get.log('Position updated: $position');
    }, onError: (e, stackTrace) {
      Get.log('Position stream error: $e\n$stackTrace', isError: true);
    });
  }

  AudioProcessingState _getAudioProcessingState(ProcessingState processingState) {
    switch (processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Sets the audio source using a URL (file path).
  Future<void> setUrl(String url) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      final file = File(url);
      if (!await file.exists()) {
        Get.log('File not found: $url', isError: true);
        throw Exception('Audio file not found: $url');
      }
      final fileLength = await file.length();
      if (fileLength <= 0) {
        Get.log('File is empty: $url', isError: true);
        throw Exception('Audio file is empty: $url');
      }

      // Use AudioSource.file for just_audio: ^0.10.4
      int retries = 3;
      while (retries > 0) {
        try {
          await _player.setAudioSource(AudioSource.file(url));
          break;
        } catch (e) {
          retries--;
          if (retries == 0) rethrow;
          Get.log('Retrying setUrl ($retries attempts left): $e');
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      mediaItem.add(MediaItem(
        id: url,
        title: url.split('/').last,
        duration: null, // Updated by durationStream
        artist: 'Voice Recorder',
      ));
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.ready,
      ));
      Get.log('Set audio source: $url');
    } catch (e, stackTrace) {
      Get.log('Error in setUrl: $e\n$stackTrace', isError: true);
      mediaItem.add(null);
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
      throw Exception('Failed to set audio source: $e');
    }
  }

  @override
  Future<void> play() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      int retries = 3;
      while (retries > 0) {
        try {
          await _player.play();
          break;
        } catch (e) {
          retries--;
          if (retries == 0) rethrow;
          Get.log('Retrying play ($retries attempts left): $e');
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      playbackState.add(playbackState.value.copyWith(
        playing: true,
        processingState: AudioProcessingState.ready,
      ));
      Get.log('Playback started');
    } catch (e, stackTrace) {
      Get.log('Error in play: $e\n$stackTrace', isError: true);
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
      throw Exception('Failed to start playback: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _player.pause();
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.ready,
      ));
      Get.log('Playback paused');
    } catch (e, stackTrace) {
      Get.log('Error in pause: $e\n$stackTrace', isError: true);
      throw Exception('Failed to pause playback: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _player.stop();
      await _player.seek(Duration.zero);
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
        updatePosition: Duration.zero,
      ));
      mediaItem.add(null);
      Get.log('Playback stopped');
    } catch (e, stackTrace) {
      Get.log('Error in stop: $e\n$stackTrace', isError: true);
      throw Exception('Failed to stop playback: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _player.seek(position);
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
      Get.log('Seek to: $position');
    } catch (e, stackTrace) {
      Get.log('Error in seek: $e\n$stackTrace', isError: true);
      throw Exception('Failed to seek: $e');
    }
  }

  Future<void> setMediaItem(MediaItem item) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await setUrl(item.id); // Reuse setUrl for consistency
      mediaItem.add(item); // Update with full MediaItem details
      Get.log('Set media item: ${item.id}');
    } catch (e, stackTrace) {
      Get.log('Error in setMediaItem: $e\n$stackTrace', isError: true);
      mediaItem.add(null);
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
      throw Exception('Failed to set media item: $e');
    }
  }

  Future<void> playRecording(Recording recording, {bool loop = false}) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // Stop any existing playback and reset player
      await stop();
      await resetPlayer();

      // Set looping mode
      _isLooping = loop;
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);

      // Set the audio source using setUrl
      await setUrl(recording.filePath);

      // Update media item with recording details
      mediaItem.add(MediaItem(
        id: recording.filePath,
        title: recording.name,
        duration: recording.duration,
        artist: 'Voice Recorder',
      ));

      await play();
      Get.log('Started playing recording: ${recording.filePath}, loop=$loop');
    } catch (e, stackTrace) {
      Get.log('Error in playRecording: $e\n$stackTrace', isError: true);
      await stop();
      throw Exception('Failed to play recording: $e');
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    try {
      await stop();
      await _player.dispose();
      _isInitialized = false;
      Get.log('Audio handler disposed on task removed');
    } catch (e, stackTrace) {
      Get.log('Error in onTaskRemoved: $e\n$stackTrace', isError: true);
    }
    await super.onTaskRemoved();
  }

  /// Custom cleanup method.
  Future<void> dispose() async {
    try {
      await _player.dispose();
      _isInitialized = false;
      Get.log('AudioPlayer disposed');
    } catch (e, stackTrace) {
      Get.log('Error in dispose: $e\n$stackTrace', isError: true);
    }
  }
}