// lib/app/data/models/recording_model.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p; // For path manipulation

import '../../../utils/app_constants.dart';

class Recording {
  int? id;
  String name;
  String filePath;
  DateTime date;
  Duration duration;
  int size; // in bytes
  bool isFavorite;
  bool isDeleted;
  String? transcription; // New field for speech-to-text

  Recording({
    this.id,
    required this.name,
    required this.filePath,
    required this.date,
    required this.duration,
    required this.size,
    this.isFavorite = false,
    this.isDeleted = false,
    this.transcription,
  });

  // Convert a Recording object into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      AppConstants.COLUMN_ID: id,
      AppConstants.COLUMN_NAME: name,
      AppConstants.COLUMN_FILE_PATH: filePath,
      AppConstants.COLUMN_DATE: date.millisecondsSinceEpoch, // Store as Unix timestamp
      AppConstants.COLUMN_DURATION: duration.inMilliseconds,
      AppConstants.COLUMN_SIZE: size,
      AppConstants.COLUMN_IS_FAVORITE: isFavorite ? 1 : 0,
      AppConstants.COLUMN_IS_DELETED: isDeleted ? 1 : 0,
      AppConstants.COLUMN_TRANSCRIPTION: transcription,
    };
  }

  // Convert a Map (from SQLite) into a Recording object
  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map[AppConstants.COLUMN_ID],
      name: map[AppConstants.COLUMN_NAME],
      filePath: map[AppConstants.COLUMN_FILE_PATH],
      date: DateTime.fromMillisecondsSinceEpoch(map[AppConstants.COLUMN_DATE]),
      duration: Duration(milliseconds: map[AppConstants.COLUMN_DURATION]),
      size: map[AppConstants.COLUMN_SIZE],
      isFavorite: map[AppConstants.COLUMN_IS_FAVORITE] == 1,
      isDeleted: map[AppConstants.COLUMN_IS_DELETED] == 1,
      transcription: map[AppConstants.COLUMN_TRANSCRIPTION],
    );
  }

  // Helper for display
  String get formattedDate => DateFormat('MMM dd, yyyy HH:mm').format(date);
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // Get file name without extension
  String get fileName => p.basenameWithoutExtension(filePath);

  // Check if the file actually exists
  Future<bool> fileExists() async {
    return await File(filePath).exists();
  }

  @override
  String toString() {
    return 'Recording(id: $id, name: $name, filePath: $filePath, date: $date, duration: $duration, size: $size, isFavorite: $isFavorite, isDeleted: $isDeleted, transcription: $transcription)';
  }
}
