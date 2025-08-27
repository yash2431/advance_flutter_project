// lib/utils/app_constants.dart
abstract class AppConstants {

  static const int MIN_RECORDING_DURATION_MS = 1000;
  static const Duration STT_RETRY_DELAY = Duration(milliseconds: 1000);
  static const int STT_MAX_RETRIES = 3;

  static const String APP_NAME = "Voice Recorder";
  static const String RECORDINGS_DIRECTORY = "VoiceRecordings";
  static const String FAVORITES_KEY = "favorites";
  static const String THEME_MODE_KEY = "themeMode";

  // Database constants
  static const String DATABASE_NAME = "recordings.db";
  static const int DATABASE_VERSION = 1;
  static const String RECORDINGS_TABLE = "recordings";

  // Table columns
  static const String COLUMN_ID = "id";
  static const String COLUMN_NAME = "name";
  static const String COLUMN_FILE_PATH = "filePath";
  static const String COLUMN_DATE = "date"; // Stored as INTEGER (Unix timestamp)
  static const String COLUMN_DURATION = "duration"; // Milliseconds
  static const String COLUMN_SIZE = "size"; // Bytes
  static const String COLUMN_IS_FAVORITE = "isFavorite"; // 0 for false, 1 for true
  static const String COLUMN_IS_DELETED = "isDeleted"; // 0 for false, 1 for true
  static const String COLUMN_TRANSCRIPTION = "transcription"; // Text from voice-to-text
}
