import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'edit_controller.dart';

class EditView extends GetView<EditController> {
  const EditView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildHeaderCard(theme),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: controller.fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: controller.fadeAnimation.value,
                      child: Transform.scale(
                        scale: controller.scaleAnimation.value,
                        child: child ?? _buildBody(context, theme, constraints),
                      ),
                    );
                  },
                  child: _buildBody(context, theme, constraints),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.primaryColor,
      foregroundColor: Colors.white,
      title: Obx(() => Column(
        children: [
          Text(
            controller.recording?.name ?? 'Unnamed Recording',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            controller.isProcessing.value
                ? 'Processing...'
                : 'Duration: ${controller.recording != null ? controller.formatPlaybackPosition(controller.recording!.duration) : "00:00:00"}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
        ],
      )),
      centerTitle: true,
      actions: [
        Obx(
              () => IconButton(
            icon: controller.isProcessing.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.save_rounded),
            onPressed: controller.isProcessing.value ? null : () => controller.saveChanges(),
            tooltip: 'Save Changes',
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, BoxConstraints constraints) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWaveformCard(context, theme, constraints),
            _buildControlsCard(context, theme),
            _buildTrimCard(context, theme),
            _buildTranscriptionCard(context, theme),
            _buildMarksCard(context, theme),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return BoxDecoration(
        color: theme.cardColor.withOpacity(0.9), // Slightly transparent for depth
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.tealAccent[200]!.withOpacity(0.4), // Bright border for visibility
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent[200]!.withOpacity(0.2), // Subtle glow effect
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(theme),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.audiotrack_rounded,
                  color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.recording?.name ?? 'Unnamed Recording',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark ? Colors.white : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${controller.recording != null ? (controller.recording!.size / 1024 / 1024).toStringAsFixed(2) : "0.00"} MB',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.8)
                            : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
                () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeChip(
                  'Current',
                  controller.formatPlaybackPosition(controller.currentPlaybackPosition.value),
                  theme.brightness == Brightness.dark ? Colors.tealAccent[200]! : theme.primaryColor,
                ),
                _buildTimeChip(
                  'Total',
                  controller.recording != null
                      ? controller.formatPlaybackPosition(controller.recording!.duration)
                      : '00:00:00',
                  theme.brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey.shade600,
                ),
                _buildTimeChip(
                  'Trimmed',
                  controller.trimmedDuration,
                  theme.brightness == Brightness.dark ? Colors.green[400]! : Colors.green.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformCard(BuildContext context, ThemeData theme, BoxConstraints constraints) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _buildCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Audio Waveform',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark ? Colors.white : null,
                  ),
                ),
                const Spacer(),
                Obx(
                      () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.isWaveformReady.value
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.isWaveformReady.value ? 'Ready' : 'Loading',
                      style: TextStyle(
                        fontSize: 10,
                        color: controller.isWaveformReady.value ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(
                () => controller.isLoadingWaveform.value
                ? Container(
              height: 120,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading waveform...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.8)
                          : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
                : controller.playerController != null
                ? Container(
              height: constraints.maxHeight * 0.2,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTapDown: (details) {
                  final double relativePosition =
                      details.localPosition.dx / (constraints.maxWidth - 32);
                  controller.seekToPosition(relativePosition.clamp(0.0, 1.0));
                },
                child: AudioFileWaveforms(
                  playerController: controller.playerController!,
                  size: Size(constraints.maxWidth - 32, constraints.maxHeight * 0.2),
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: theme.brightness == Brightness.dark
                        ? Colors.tealAccent[200]!.withOpacity(0.3)
                        : theme.primaryColor.withOpacity(0.3),
                    liveWaveColor: theme.brightness == Brightness.dark ? Colors.tealAccent[200]! : theme.primaryColor,
                    showSeekLine: true,
                    seekLineColor: Colors.red,
                    seekLineThickness: 3.0,
                    waveThickness: 3.0,
                    showBottom: true,
                    showTop: true,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.brightness == Brightness.dark
                            ? Colors.tealAccent[200]!.withOpacity(0.02)
                            : theme.primaryColor.withOpacity(0.02),
                        theme.brightness == Brightness.dark
                            ? Colors.tealAccent[200]!.withOpacity(0.08)
                            : theme.primaryColor.withOpacity(0.08),
                        theme.brightness == Brightness.dark
                            ? Colors.tealAccent[200]!.withOpacity(0.02)
                            : theme.primaryColor.withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.tealAccent[200]!.withOpacity(0.3)
                          : theme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            )
                : Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                'Waveform unavailable',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
                () => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: controller.playbackProgress.value,
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.tealAccent[200]!.withOpacity(0.1)
                    : theme.primaryColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.brightness == Brightness.dark ? Colors.tealAccent[200]! : theme.primaryColor),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(theme),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous,
                color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor),
            onPressed: () => controller.seekToPosition(0),
            tooltip: 'Seek to Start',
          ),
          Obx(
                () => IconButton(
              icon: Icon(
                controller.playerState.value.playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () => controller.togglePlayback(),
              style: IconButton.styleFrom(
                backgroundColor: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor,
                padding: const EdgeInsets.all(16),
              ),
              tooltip: controller.playerState.value.playing ? 'Pause' : 'Play',
            ),
          ),
          IconButton(
            icon: Icon(Icons.skip_next,
                color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor),
            onPressed: () => controller.seekToPosition(1.0),
            tooltip: 'Seek to End',
          ),
        ],
      ),
    );
  }

  Widget _buildTrimCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.content_cut,
                  color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trim Audio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
                () => RangeSlider(
              values: RangeValues(
                controller.recording != null
                    ? controller.recording!.duration.inMilliseconds.toDouble() * controller.startTrim.value
                    : 0.0,
                controller.recording != null
                    ? controller.recording!.duration.inMilliseconds.toDouble() * controller.endTrim.value
                    : 1.0,
              ),
              min: 0,
              max: controller.recording != null
                  ? controller.recording!.duration.inMilliseconds.toDouble()
                  : 1.0,
              divisions: controller.recording != null
                  ? controller.recording!.duration.inMilliseconds ~/ 10
                  : 1,
              labels: RangeLabels(
                controller.recording != null
                    ? controller.formatPlaybackPosition(
                  Duration(
                    milliseconds: (controller.recording!.duration.inMilliseconds *
                        controller.startTrim.value)
                        .toInt(),
                  ),
                )
                    : '00:00:00',
                controller.recording != null
                    ? controller.formatPlaybackPosition(
                  Duration(
                    milliseconds: (controller.recording!.duration.inMilliseconds *
                        controller.endTrim.value)
                        .toInt(),
                  ),
                )
                    : '00:00:00',
              ),
              onChanged: (RangeValues values) {
                if (controller.recording != null) {
                  controller.updateTrimRange(
                    values.start / controller.recording!.duration.inMilliseconds.toDouble(),
                    values.end / controller.recording!.duration.inMilliseconds.toDouble(),
                  );
                }
              },
              activeColor: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : null,
              inactiveColor: theme.brightness == Brightness.dark ? Colors.grey[600] : null,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
                () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start: ${controller.recording != null ? controller.formatPlaybackPosition(Duration(milliseconds: (controller.recording!.duration.inMilliseconds * controller.startTrim.value).toInt())) : "00:00:00"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark ? Colors.white : null,
                  ),
                ),
                Text(
                  'End: ${controller.recording != null ? controller.formatPlaybackPosition(Duration(milliseconds: (controller.recording!.duration.inMilliseconds * controller.endTrim.value).toInt())) : "00:00:00"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.transcribe,
                  color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transcription',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : null,
                ),
              ),
              const Spacer(),
              Obx(
                    () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: controller.isTranscriptionReady.value
                        ? Colors.green.withOpacity(0.1)
                        : controller.isTranscribing.value
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.isTranscriptionReady.value
                        ? 'Ready'
                        : controller.isTranscribing.value
                        ? 'Transcribing'
                        : 'Not Started',
                    style: TextStyle(
                      fontSize: 10,
                      color: controller.isTranscriptionReady.value
                          ? Colors.green
                          : controller.isTranscribing.value
                          ? Colors.orange
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
                () => controller.transcriptionText.value.isEmpty
                ? Text(
              'No transcription available. Start transcribing to see results.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.8)
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            )
                : SelectableText(
              controller.transcriptionText.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark ? Colors.white : null,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
                () => ElevatedButton(
              onPressed: controller.isProcessing.value ? null : () => controller.toggleTranscription(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                controller.isTranscribing.value ? 'Stop Transcription' : 'Start Transcription',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark,
                  color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Marks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? Colors.white : null,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.red),
                onPressed: () => controller.clearAllMarks(),
                tooltip: 'Clear All Marks',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
                () => controller.markedPositions.isEmpty
                ? Center(
              child: Text(
                'No marks added yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.8)
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            )
                : Column(
              children: controller.markedPositions
                  .map(
                    (mark) => ListTile(
                  leading: Icon(
                    Icons.bookmark,
                    color: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor,
                  ),
                  title: Text(
                    controller.formatPlaybackPosition(mark),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark ? Colors.white : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => controller.removeMark(mark),
                    tooltip: 'Remove Mark',
                  ),
                  onTap: () => controller.seekToPosition(
                    mark.inMilliseconds / (controller.recording?.duration.inMilliseconds.toDouble() ?? 1.0),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => controller.addMark(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Mark at Current Position'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(
                    () => ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : () => controller.saveChanges(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark ? Colors.tealAccent[200] : theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: controller.isProcessing.value
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Apply Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}