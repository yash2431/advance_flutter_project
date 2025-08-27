// lib/app/modules/favorite/favorite_controller.dart
import 'package:get/get.dart';
import '../../models/recording_model.dart';
import '../listen/listen_controller.dart'; // Reuse logic from ListenController

class FavoriteController extends ListenController { // Extends ListenController
  // The 'currentlyPlaying', 'playerState', 'currentPlaybackPosition'
  // from ListenController will be available.

  @override
  void onInit() {
    super.onInit();
    fetchFavoriteRecordings(); // Fetch favorites initially
  }

  // Override fetchRecordings to only get favorites
  @override
  Future<void> fetchRecordings() async {
    // This method is called in super.onInit().
    // We can call fetchFavoriteRecordings directly from onInit() instead.
  }

  Future<void> fetchFavoriteRecordings() async {
    isLoading.value = true;
    final recordings = await databaseService.getRecordings(
      isFavorite: true,
      isDeleted: false,
    );
    allRecordings.assignAll(recordings); // Update the base list
    applyFilter(); // Apply any existing search/date filter
    isLoading.value = false;
  }

  // Override toggleFavorite to also refresh favorite list
  @override
  Future<void> toggleFavorite(Recording recording) async {
    // Calling super method will update DB and toggle favorite status
    await super.toggleFavorite(recording);
    await fetchFavoriteRecordings(); // Refresh favorites list after action
  }

  @override
  Future<void> deleteRecording(Recording recording) async {
    await super.deleteRecording(recording); // Soft delete
    await fetchFavoriteRecordings(); // Refresh favorites list
  }

  @override
  Future<void> renameRecording(Recording recording) async {
    await super.renameRecording(recording);
    await fetchFavoriteRecordings();
  }

// No need to override shareRecording or navigateToEditScreen as they are generic
// and will use the `recording` argument passed to them.
}