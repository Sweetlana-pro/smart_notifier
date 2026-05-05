import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip.dart';
import 'notification_service.dart';

class TripSyncService {
  static final NotificationService _notificationService = NotificationService();

  /// Handle background update from push notification
  /// Returns true if trip was updated and notification shown
  static Future<bool> handleBackgroundUpdate(Map<String, dynamic> data) async {
    try {
      // Parse the incoming trip data
      final newTrip = Trip.fromJson(data);

      // Retrieve old trip state from storage
      final prefs = await SharedPreferences.getInstance();
      final tripKey = 'trip_${newTrip.id}';
      final oldTripJson = prefs.getString(tripKey);

      Trip? oldTrip;
      if (oldTripJson != null) {
        oldTrip = Trip.fromJson(jsonDecode(oldTripJson));
      }

      // Compare state and determine if notification is needed
      final shouldNotify = _shouldNotifyUser(oldTrip, newTrip);

      // Save updated trip to storage
      await prefs.setString(tripKey, jsonEncode(newTrip.toJson()));

      // Show notification if state changed
      if (shouldNotify) {
        await _notificationService.showTripUpdateNotification(
          flightNumber: newTrip.flightNumber,
          newStatus: newTrip.getStatusString(),
        );
      }

      return shouldNotify;
    } catch (e) {
      print('Error handling background update: $e');
      return false;
    }
  }

  /// Determine if user should be notified based on state changes
  static bool _shouldNotifyUser(Trip? oldTrip, Trip newTrip) {
    // First trip - don't notify
    if (oldTrip == null) {
      return false;
    }

    // Status changed - always notify
    if (oldTrip.status != newTrip.status) {
      return true;
    }

    // Gate changed - notify
    if (oldTrip.gate != newTrip.gate) {
      return true;
    }

    // Scheduled time changed significantly (more than 5 minutes)
    final timeDifference = oldTrip.scheduledTime
        .difference(newTrip.scheduledTime)
        .inMinutes
        .abs();
    if (timeDifference >= 5) {
      return true;
    }

    return false;
  }

  /// Sync all trips from backend (simulated)
  static Future<List<Trip>> syncTripsFromBackend() async {
    // Simulate backend fetch - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    return [
      Trip(
        id: 'AA123',
        flightNumber: 'AA123',
        origin: 'LAX',
        destination: 'JFK',
        status: TripStatus.onTime,
        scheduledTime: now.add(const Duration(hours: 2)),
        gate: 42,
        lastUpdated: now,
      ),
      Trip(
        id: 'UA456',
        flightNumber: 'UA456',
        origin: 'SFO',
        destination: 'ORD',
        status: TripStatus.delayed,
        scheduledTime: now.add(const Duration(hours: 4)),
        actualTime: now.add(const Duration(hours: 4, minutes: 30)),
        gate: 15,
        lastUpdated: now,
      ),
      Trip(
        id: 'DL789',
        flightNumber: 'DL789',
        origin: 'ATL',
        destination: 'BOS',
        status: TripStatus.gateChanged,
        scheduledTime: now.add(const Duration(hours: 6)),
        gate: 28,
        lastUpdated: now,
      ),
    ];
  }

  /// Load trips from local storage
  static Future<List<Trip>> loadTripsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final trips = <Trip>[];

      for (final key in keys) {
        if (key.startsWith('trip_')) {
          final tripJson = prefs.getString(key);
          if (tripJson != null) {
            trips.add(Trip.fromJson(jsonDecode(tripJson)));
          }
        }
      }

      return trips;
    } catch (e) {
      print('Error loading trips from storage: $e');
      return [];
    }
  }

  /// Save trip to local storage
  static Future<void> saveTrip(Trip trip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripKey = 'trip_${trip.id}';
      await prefs.setString(tripKey, jsonEncode(trip.toJson()));
    } catch (e) {
      print('Error saving trip: $e');
    }
  }

  /// Save multiple trips to local storage
  static Future<void> saveTrips(List<Trip> trips) async {
    try {
      for (final trip in trips) {
        await saveTrip(trip);
      }
    } catch (e) {
      print('Error saving trips: $e');
    }
  }
}
