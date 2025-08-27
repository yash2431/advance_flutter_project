import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_waveforms/audio_waveforms.dart' as audio_waveforms;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/recording_model.dart';
import '../../services/audio_handler_service.dart';
import '../../services/database_service.dart';
import '../../services/speech_service.dart';
import '../../utils/app_constants.dart';

enum ProcessingState { idle, loading, ready, playing, paused, completed }

class PlayerState {
  final bool playing;
  final ProcessingState processingState;

  PlayerState({required this.playing, required this.processingState});

  PlayerState copyWith({bool? playing, ProcessingState? processingState}) {
    return PlayerState(
      playing: playing ?? this.playing,
      processingState: processingState ?? this.processingState,
    );
  }
}

class EditController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final Recording? recording = Get.arguments as Recording?;
  final DatabaseService _databaseService = Get.find<DatabaseService>();
  final MyAudioHandler _audioHandler = Get.find<MyAudioHandler>();
  late SpeechService _speechService;

  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Player State Management
  final Rx<PlayerState> playerState = PlayerState(
    playing: false,
    processingState: ProcessingState.idle,
  ).obs;
  final Rx<Duration> currentPlaybackPosition = Duration.zero.obs;
  final RxDouble playbackProgress = 0.0.obs;

  // Waveform Management
  audio_waveforms.PlayerController? playerController;
  final RxList<double> waveforms = <double>[].obs;
  final RxBool isLoadingWaveform = true.obs;
  final RxBool isWaveformReady = false.obs;

  // Trim and Mark Management
  final RxDouble startTrim = 0.0.obs;
  final RxDouble endTrim = 1.0.obs;
  final RxList<Duration> markedPositions = <Duration>[].obs;
  final RxBool isProcessing = false.obs;

  // Transcription Management
  final RxBool isTranscribing = false.obs;
  final RxString transcriptionText = ''.obs;
  final RxBool isTranscriptionReady = false.obs;

  // UI State Management
  final RxBool showTrimInfo = false.obs;
  final RxBool showMarksPanel = false.obs;
  final RxString statusMessage = ''.obs;
  final Rx<Color> statusColor = Colors.blue.obs;

  StreamSubscription<int>? _progressSubscription;
  Timer? _statusTimer;
  bool _isDisposed = false;
  bool _isPlayerInitialized = false;

  // Speech Management
  Timer? _speechTimer;
  bool _speechServiceAvailable = false;

  // Getters
  Animation<double> get fadeAnimation => _fadeAnimation;

  Animation<double> get scaleAnimation => _scaleAnimation;

  @override
  void onInit() {
    super.onInit();
    if (recording == null) {
      _showStatusMessage('No recording provided', Colors.red);
      Get.back();
      return;
    }
    _initAnimations();
    _initSpeechService();
    _stopBackgroundPlayback();
    _initializePlayer();
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure recording data is fresh and waveform is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Check if waveform needs to be loaded
        if (isWaveformReady.value == false && !isLoadingWaveform.value) {
          Get.log('Loading waveform for recording: ${recording?.name}');
          await _loadWaveform();
        }

        // Validate recording data
        if (recording != null) {
          Get.log(
            'Recording data validated: ${recording!.name}, Duration: ${recording!.duration}, File: ${recording!.filePath}',
          );
        }
      } catch (e) {
        Get.log('Error in onReady: $e', isError: true);
        _showStatusMessage('Error initializing recording data', Colors.red);
      }
    });
  }

  @override
  void onClose() {
    _isDisposed = true;
    _progressSubscription?.cancel();
    _statusTimer?.cancel();
    _speechTimer?.cancel();
    _animationController.dispose();
    _disposePlayerController();
    _speechService.dispose();
    super.onClose();
  }

  void _initSpeechService() {
    _speechService = SpeechService(
      localeId: 'en_US',
      onResult: (result) {
        if (_isDisposed) return;
        transcriptionText.value = result.recognizedWords;
        isTranscriptionReady.value = result.finalResult;
        if (result.finalResult) {
          _showStatusMessage('Transcription completed', Colors.green);
          _stopTranscription();
        }
      },
      onStatus: (status) {
        if (_isDisposed) return;
        Get.log('SpeechService Status: $status');

        switch (status) {
          case 'listening':
            _speechServiceAvailable = true;
            break;
          case 'done':
          case 'notListening':
            _stopTranscription();
            break;
        }
      },
      onError: (errorMsg) {
        if (_isDisposed) return;
        Get.log('SpeechService Error: $errorMsg', isError: true);

        if (errorMsg.toLowerCase().contains('timeout')) {
          if (errorMsg.toLowerCase().contains('permanent')) {
            _showStatusMessage(
              'Speech recognition timed out. Please try again.',
              Colors.orange,
            );
            _reinitializeSpeechService();
          }
        } else if (errorMsg.toLowerCase().contains('permission')) {
          _showStatusMessage('Microphone permission required', Colors.red);
        } else {
          _showStatusMessage('Speech recognition error', Colors.red);
        }

        _stopTranscription();
      },
    );

    _speechService
        .initialize()
        .then((initialized) {
          if (_isDisposed) return;
          _speechServiceAvailable = initialized;
          if (!initialized) {
            _showStatusMessage('Speech recognition unavailable', Colors.red);
          }
        })
        .catchError((error) {
          if (!_isDisposed) {
            _speechServiceAvailable = false;
            _showStatusMessage(
              'Failed to initialize speech service',
              Colors.red,
            );
          }
        });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _stopBackgroundPlayback() async {
    try {
      if (_audioHandler.mediaItem.value?.id == recording?.filePath) {
        await _audioHandler.stop();
      }
    } catch (e) {
      Get.log('Error stopping background playback: $e', isError: true);
    }
  }

  Future<void> _initializePlayer() async {
    await _initPlayerController();
    await _loadWaveform();
  }

  void _disposePlayerController() {
    _stopProgressTimer();
    try {
      if (playerController != null) {
        playerController?.stopPlayer();
        playerController?.dispose();
      }
    } catch (e) {
      Get.log('Error disposing player controller: $e', isError: true);
    } finally {
      playerController = null;
      _isPlayerInitialized = false;

      // Reset player state
      playerState.value = PlayerState(
        playing: false,
        processingState: ProcessingState.ready,
      );
      currentPlaybackPosition.value = Duration.zero;
      _updatePlaybackProgress();
    }
  }

  Future<void> _initPlayerController() async {
    _disposePlayerController();

    try {
      playerController = audio_waveforms.PlayerController();
      _setupPlayerListeners();
      _isPlayerInitialized = true;

      // Reset player state
      playerState.value = PlayerState(
        playing: false,
        processingState: ProcessingState.ready,
      );
    } catch (e) {
      Get.log('Error initializing player controller: $e', isError: true);
      _isPlayerInitialized = false;
      playerController = null;
      throw e;
    }
  }

  void _setupPlayerListeners() {
    playerController?.onPlayerStateChanged.listen((state) {
      if (_isDisposed) return;

      final newPlayerState = PlayerState(
        playing: state == audio_waveforms.PlayerState.playing,
        processingState: _mapAudioProcessingState(state),
      );

      playerState.value = newPlayerState;

      if (state == audio_waveforms.PlayerState.playing) {
        _startProgressTimer();
      } else {
        _stopProgressTimer();
      }

      if (state == audio_waveforms.PlayerState.stopped) {
        playerState.value = PlayerState(
          playing: false,
          processingState: ProcessingState.ready,
        );
        currentPlaybackPosition.value = Duration.zero;
        _updatePlaybackProgress();
      }
    });
  }

  Future<void> _playAudio() async {
    try {
      await playerController?.stopPlayer();

      await playerController?.preparePlayer(
        path: recording!.filePath,
        shouldExtractWaveform: true,
      );

      final startMs = (recording!.duration.inMilliseconds * startTrim.value)
          .toInt();
      await playerController?.seekTo(startMs);

      await playerController?.startPlayer();

      _showStatusMessage('Playing', Colors.green);
      playerState.value = PlayerState(
        playing: true,
        processingState: ProcessingState.playing,
      );
    } catch (e) {
      _showStatusMessage('Playback failed: ${e.toString()}', Colors.red);
      playerState.value = PlayerState(
        playing: false,
        processingState: ProcessingState.ready,
      );
    }
  }

  Future<void> togglePlayback() async {
    if (recording == null || recording!.filePath.isEmpty) {
      _showStatusMessage('No recording found.', Colors.red);
      return;
    }

    if (!_isPlayerInitialized || playerController == null) {
      _showStatusMessage('Player not initialized', Colors.red);
      return;
    }

    try {
      final currentState = playerState.value;

      if (currentState.playing) {
        await playerController?.pausePlayer();
        _showStatusMessage('Paused', Colors.orange);
        playerState.value = PlayerState(
          playing: false,
          processingState: ProcessingState.paused,
        );
      } else {
        await _playAudio();
      }
    } catch (e, stack) {
      Get.log('Error in togglePlayback: $e\n$stack', isError: true);
      _showStatusMessage('Playback error: ${e.toString()}', Colors.red);
      playerState.value = PlayerState(
        playing: false,
        processingState: ProcessingState.ready,
      );
    }
  }

  Future<void> seekToPosition(double position) async {
    if (playerController == null ||
        recording == null ||
        !_isPlayerInitialized) {
      _showStatusMessage('Player not initialized', Colors.red);
      return;
    }

    try {
      final seekMilliseconds =
          (recording!.duration.inMilliseconds * position.clamp(0.0, 1.0))
              .toInt();

      await playerController?.seekTo(seekMilliseconds);
      await _audioHandler.seek(Duration(milliseconds: seekMilliseconds));

      currentPlaybackPosition.value = Duration(milliseconds: seekMilliseconds);
      _updatePlaybackProgress();

      _showStatusMessage(
        'Seeked to ${formatPlaybackPosition(Duration(milliseconds: seekMilliseconds))}',
        Colors.blue,
      );
    } catch (e, stackTrace) {
      Get.log('Seek error: $e\n$stackTrace', isError: true);
      _showStatusMessage('Failed to seek: $e', Colors.red);
    }
  }

  Future<void> toggleTranscription() async {
    if (isTranscribing.value) {
      await _stopTranscription();
    } else {
      await _startTranscription();
    }
  }

  Future<void> _startTranscription() async {
    if (recording == null || !File(recording!.filePath).existsSync()) {
      _showStatusMessage('No valid recording to transcribe', Colors.red);
      return;
    }

    if (!_speechServiceAvailable) {
      _showStatusMessage('Speech recognition not available', Colors.red);
      return;
    }

    try {
      await playerController?.pausePlayer();

      isTranscribing.value = true;
      transcriptionText.value = '';
      isTranscriptionReady.value = false;

      await _playAudio();

      await _speechService.listen(
        listenFor: recording!.duration,
        pauseFor: const Duration(seconds: 2),
      );

      _showStatusMessage('Transcribing...', Colors.green);

      // Set timer for full audio duration
      _speechTimer = Timer(recording!.duration, () async {
        if (isTranscribing.value) {
          // Only auto-stop if still transcribing (user hasn't manually stopped)
          await _stopTranscription();
          await playerController?.pausePlayer();
          _showStatusMessage('Transcription completed', Colors.green);

          // Mark transcription as ready and finalize the result
          isTranscriptionReady.value = true;
        }
      });
    } catch (e) {
      Get.log('Transcription start error: $e', isError: true);
      isTranscribing.value = false;
      await playerController?.pausePlayer();
      _showStatusMessage('Failed to start transcription', Colors.red);
    }
  }

  Future<void> _stopTranscription() async {
    try {
      _speechTimer?.cancel();
      _speechTimer = null;

      if (isTranscribing.value) {
        await _speechService.stop();
        isTranscribing.value = false;

        // Mark transcription as ready when manually stopped
        // This ensures the current transcription text is preserved
        if (transcriptionText.value.isNotEmpty) {
          isTranscriptionReady.value = true;
          _showStatusMessage(
            'Transcription stopped - text saved',
            Colors.orange,
          );
        } else {
          _showStatusMessage('Transcription stopped', Colors.orange);
        }
      }
    } catch (e) {
      Get.log('Error stopping transcription: $e', isError: true);
    }
  }

  void _startProgressTimer() {
    _progressSubscription?.cancel();
    _progressSubscription = playerController?.onCurrentDurationChanged.listen(
      (timeMs) {
        if (_isDisposed) return;
        currentPlaybackPosition.value = Duration(milliseconds: timeMs);
        _updatePlaybackProgress();
      },
      onError: (e, stackTrace) {
        if (!_isDisposed) {
          Get.log('Progress timer error: $e\n$stackTrace', isError: true);
          _showStatusMessage('Failed to update playback position', Colors.red);
        }
      },
    );
  }

  void _stopProgressTimer() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
  }

  void _updatePlaybackProgress() {
    if (recording != null && recording!.duration.inMilliseconds > 0) {
      playbackProgress.value =
          currentPlaybackPosition.value.inMilliseconds /
          recording!.duration.inMilliseconds;
    }
  }

  ProcessingState _mapAudioProcessingState(audio_waveforms.PlayerState state) {
    switch (state) {
      case audio_waveforms.PlayerState.playing:
        return ProcessingState.playing;
      case audio_waveforms.PlayerState.paused:
        return ProcessingState.paused;
      case audio_waveforms.PlayerState.stopped:
        return ProcessingState.ready;
      default:
        return ProcessingState.loading;
    }
  }

  Future<void> _loadWaveform() async {
    if (recording == null || recording!.filePath.isEmpty || _isDisposed) {
      isLoadingWaveform.value = false;
      return;
    }

    try {
      final file = File(recording!.filePath);
      if (!await file.exists()) {
        _showStatusMessage('Recording file not found', Colors.red);
        isLoadingWaveform.value = false;
        return;
      }

      // Validate recording duration
      if (recording!.duration.inMilliseconds <= 0) {
        _showStatusMessage('Invalid recording duration', Colors.red);
        isLoadingWaveform.value = false;
        return;
      }

      // Reset waveform state
      waveforms.clear();
      isWaveformReady.value = false;
      isLoadingWaveform.value = true;

      if (!_isPlayerInitialized || playerController == null) {
        await _initPlayerController();
      }

      // Ensure player controller is ready
      if (playerController == null) {
        throw Exception('Player controller not initialized');
      }

      await playerController?.preparePlayer(
        path: recording!.filePath,
        shouldExtractWaveform: true,
      );

      final sampleSize = (recording!.duration.inSeconds * 2).clamp(100, 500);
      final waveformData = await playerController!.extractWaveformData(
        path: recording!.filePath,
        noOfSamples: sampleSize,
      );

      if (_isDisposed) return;

      if (waveformData.isNotEmpty) {
        waveforms.assignAll(waveformData);
        isWaveformReady.value = true;
        isLoadingWaveform.value = false;
        _showStatusMessage('Waveform loaded successfully', Colors.green);
      } else {
        isLoadingWaveform.value = false;
        _showStatusMessage('Waveform data unavailable', Colors.orange);
      }
    } catch (e, stack) {
      if (!_isDisposed) {
        Get.log('Waveform error: $e\n$stack', isError: true);
        isLoadingWaveform.value = false;
        isWaveformReady.value = false;
        _showStatusMessage('Failed to load waveform: $e', Colors.red);
      }
    }
  }

  void updateTrimRange(double start, double end) {
    if (recording == null) return;

    final validStart = start.clamp(0.0, 1.0);
    final validEnd = end.clamp(0.0, 1.0);

    if (validStart >= validEnd) return;

    startTrim.value = validStart;
    endTrim.value = validEnd;

    showTrimInfo.value = true;

    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed) {
        showTrimInfo.value = false;
      }
    });

    final startSec =
        (recording!.duration.inMilliseconds * startTrim.value / 1000.0)
            .toStringAsFixed(2);
    final endSec = (recording!.duration.inMilliseconds * endTrim.value / 1000.0)
        .toStringAsFixed(2);
    statusMessage.value = 'Trim: ${startSec}s - ${endSec}s';
    statusColor.value = Colors.blue;
  }

  void addMark() {
    if (recording == null) return;

    final currentPos = currentPlaybackPosition.value;
    if (currentPos <= recording!.duration &&
        !markedPositions.any(
          (mark) => (mark - currentPos).abs() < const Duration(milliseconds: 1),
        )) {
      markedPositions.add(currentPos);
      markedPositions.sort((a, b) => a.compareTo(b));
      final markSec = (currentPos.inMilliseconds / 1000.0);
      _showStatusMessage('Mark added at ${markSec}s', Colors.green);
      showMarksPanel.value = true;
    } else {
      _showStatusMessage('Cannot add mark at this position', Colors.red);
    }
  }

  void removeMark(Duration mark) {
    markedPositions.remove(mark);
    final markSec = (mark.inMilliseconds / 1000.0).toStringAsFixed(2);
    _showStatusMessage('Mark at ${markSec}s removed', Colors.orange);
    if (markedPositions.isEmpty) {
      showMarksPanel.value = false;
    }
  }

  void clearAllMarks() {
    markedPositions.clear();
    showMarksPanel.value = false;
    _showStatusMessage('All marks cleared', Colors.green);
  }

  void toggleMarksPanel() {
    showMarksPanel.value = !showMarksPanel.value;
  }

  Future<void> saveChanges() async {
    if (playerController == null || recording == null) {
      _showStatusMessage('Player or recording not initialized', Colors.red);
      return;
    }

    await playerController?.pausePlayer();
    await _audioHandler.pause();

    if (startTrim.value > 0.0 || endTrim.value < 1.0) {
      isProcessing.value = true;
      _showStatusMessage(
        'after trimming the waveforms will be in loading state only',
        Colors.blue,
      );
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Processing Audio...', style: Get.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we trim your recording',
                    style: Get.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final inputPath = recording!.filePath;
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(
        '${appDocDir.path}/${AppConstants.RECORDINGS_DIRECTORY}',
      );
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      final String outputPath =
          '${recordingsDir.path}/temp_trimmed_${DateTime.now().millisecondsSinceEpoch}.m4a';

      final int startMs = (recording!.duration.inMilliseconds * startTrim.value)
          .toInt();
      final int endMs = (recording!.duration.inMilliseconds * endTrim.value)
          .toInt();

      // Use -c copy to avoid re-encoding for faster trimming
      final String ffmpegCommand =
          '-i "$inputPath" -ss ${startMs / 1000.0} -to ${endMs / 1000.0} -c copy "$outputPath"';

      try {
        final session = await FFmpegKit.execute(ffmpegCommand);
        final returnCode = await session.getReturnCode();
        Get.back();
        isProcessing.value = false;

        if (ReturnCode.isSuccess(returnCode)) {
          // Copy the trimmed file back to the original file path
          final trimmedFile = File(outputPath);
          if (await trimmedFile.exists()) {
            await trimmedFile.copy(inputPath); // Overwrite original file
            await trimmedFile.delete(); // Delete temporary file
          }

          // Update recording duration and size only
          recording!.duration = Duration(milliseconds: endMs - startMs);
          recording!.size = await File(inputPath).length();

          // Update database
          await _databaseService.updateRecording(recording!);

          // Reset trim values
          startTrim.value = 0.0;
          endTrim.value = 1.0;

          // Reinitialize player controller for the updated file
          await _initPlayerController();

          // Reload waveform for the trimmed audio
          await _loadWaveform();

          _showStatusMessage('Recording trimmed and saved!', Colors.green);

          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Success!',
                      style: Get.textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your recording has been trimmed and saved successfully.',
                      style: Get.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.back(
                          result: recording,
                        ); // Return the updated recording
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          final output = await session.getOutput();
          _showStatusMessage(
            'Failed to trim audio: ${output ?? 'Unknown FFmpeg error'}',
            Colors.red,
          );
          final outputFile = File(outputPath);
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
        }
      } catch (e, stackTrace) {
        Get.log('Trimming error: $e\n$stackTrace', isError: true);
        Get.back();
        isProcessing.value = false;
        _showStatusMessage(
          'An exception occurred during trimming: $e',
          Colors.red,
        );
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          await outputFile.delete();
        }
      }
    } else {
      _showStatusMessage('No trimming applied', Colors.blue);
      Get.back();
    }
  }

  void _showStatusMessage(String message, Color color) {
    if (_isDisposed) return;

    statusMessage.value = message;
    statusColor.value = color;

    Get.snackbar(
      'Status',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  String formatPlaybackPosition(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(position.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(position.inSeconds.remainder(60));
    return "${twoDigits(position.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String get trimmedDuration {
    if (recording == null) return '00:00:00';
    final startMs = (recording!.duration.inMilliseconds * startTrim.value)
        .toInt();
    final endMs = (recording!.duration.inMilliseconds * endTrim.value).toInt();
    return formatPlaybackPosition(Duration(milliseconds: endMs - startMs));
  }

  double get trimPercentage {
    return ((endTrim.value - startTrim.value) * 100);
  }

  Future<void> _reinitializeSpeechService() async {
    try {
      _speechService.dispose();
      await Future.delayed(const Duration(seconds: 1));
      _initSpeechService();
    } catch (e) {
      Get.log('Error reinitializing speech service: $e', isError: true);
    }
  }
}
