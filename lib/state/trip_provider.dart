import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../services/trip_sync_service.dart';

class TripProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastSyncTime;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Load trips from local storage on initialization
  Future<void> loadInitialTrips() async {
    _isLoading = true;
    notifyListeners();

    try {
      _trips = await TripSyncService.loadTripsFromStorage();
      if (_trips.isEmpty) {
        // If no trips in storage, sync from backend
        await syncTrips();
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load trips: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync trips from backend
  Future<void> syncTrips() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedTrips = await TripSyncService.syncTripsFromBackend();

      // Save to local storage
      await TripSyncService.saveTrips(fetchedTrips);

      _trips = fetchedTrips;
      _lastSyncTime = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to sync trips: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a single trip (called from background sync)
  Future<void> updateTrip(Trip updatedTrip) async {
    final index = _trips.indexWhere((trip) => trip.id == updatedTrip.id);

    if (index >= 0) {
      _trips[index] = updatedTrip;
      await TripSyncService.saveTrip(updatedTrip);
      notifyListeners();
    } else {
      // New trip
      _trips.add(updatedTrip);
      await TripSyncService.saveTrip(updatedTrip);
      notifyListeners();
    }
  }

  /// Get trip by ID
  Trip? getTrip(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get trips by status
  List<Trip> getTripsByStatus(TripStatus status) {
    return _trips.where((trip) => trip.status == status).toList();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Simulate receiving a background update (for testing)
  Future<void> simulateBackgroundUpdate(
    String tripId,
    TripStatus newStatus,
  ) async {
    final trip = getTrip(tripId);
    if (trip != null) {
      final updatedTrip = trip.copyWith(
        status: newStatus,
        lastUpdated: DateTime.now(),
      );

      // This simulates what happens in background
      await TripSyncService.handleBackgroundUpdate(updatedTrip.toJson());

      // Update local state
      await updateTrip(updatedTrip);
    }
  }
}
