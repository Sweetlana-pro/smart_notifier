# Smart Notifier - Architecture & Implementation Guide

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     APP LAYERS                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  🎨 PRESENTATION LAYER                                       │
│  ├─ TripListScreen (UI)                                      │
│  └─ _TripCard, _SimulationDialog (Components)                │
│                                                              │
│  🧠 STATE MANAGEMENT LAYER                                   │
│  └─ TripProvider (ChangeNotifier)                            │
│     ├─ loadInitialTrips()                                    │
│     ├─ syncTrips()                                           │
│     └─ updateTrip()                                          │
│                                                              │
│  🔧 SERVICE LAYER                                            │
│  ├─ NotificationService                                      │
│  │  └─ showTripUpdateNotification()                          │
│  ├─ TripSyncService                                          │
│  │  ├─ handleBackgroundUpdate() ⭐                           │
│  │  ├─ _shouldNotifyUser() (Smart Logic!)                    │
│  │  └─ saveTrips() / loadTripsFromStorage()                  │
│  └─ FirebaseMessagingService                                 │
│     └─ firebaseMessagingBackgroundHandler()                  │
│                                                              │
│  💾 DATA LAYER                                                │
│  └─ SharedPreferences (Local Storage)                        │
│                                                              │
│  🌐 CLOUD LAYER                                               │
│  └─ Firebase Cloud Messaging                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow: Silent Push Update

```
Backend sends silent push
         ↓
Firebase receives (on device)
         ↓
firebaseMessagingBackgroundHandler() runs
         ↓
TripSyncService.handleBackgroundUpdate(data)
         ↓
Load old trip from SharedPreferences
         ↓
Parse new trip from push data
         ↓
_shouldNotifyUser(oldTrip, newTrip)?
         ↓
    (YES)                    (NO)
     ↓                        ↓
Show notification    Just update storage
     ↓                        ↓
     └────────────┬──────────┘
                  ↓
          Save to SharedPreferences
                  ↓
          TripProvider.updateTrip()
                  ↓
          UI refreshes (on next open)
```

## Core Concepts Explained

### 1. The Smart Notification Logic ⭐

**Location**: [lib/services/trip_sync_service.dart](lib/services/trip_sync_service.dart#L30-L50)

```dart
static bool _shouldNotifyUser(Trip? oldTrip, Trip newTrip) {
  // KEY INSIGHT: This function is the heart of the app
  
  // RULE 1: Never notify on first sync
  if (oldTrip == null) {
    return false;  // Wait, don't spam with initial data
  }

  // RULE 2: Status changes are important
  if (oldTrip.status != newTrip.status) {
    return true;   // "Delayed" → "On Time" is significant!
  }

  // RULE 3: Gate changes matter
  if (oldTrip.gate != newTrip.gate) {
    return true;   // "Gate 15" → "Gate 28" - user needs to know!
  }

  // RULE 4: Major time changes only
  final timeDifference = oldTrip.scheduledTime
    .difference(newTrip.scheduledTime)
    .inMinutes
    .abs();
  if (timeDifference >= 5) {
    return true;   // More than 5 min change
  }

  // No significant change
  return false;    // Silent update - good UX!
}
```

**Why this matters in interviews**:
- Shows you understand notification fatigue
- Demonstrates state comparison logic
- Proves you think about user experience
- Real-world problem solving

### 2. Background Handler (Runs Even When App is Closed)

**Location**: [lib/services/background_handler.dart](lib/services/background_handler.dart#L1-L20)

```dart
// THIS IS TOP-LEVEL - NOT IN A CLASS!
// Must be top-level for Firebase to call it
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This code runs in an ISOLATED CONTEXT
  // Even if user force-closed the app!
  
  print('Handling background message: ${message.messageId}');
  print('Message data: ${message.data}');

  if (message.data.isNotEmpty) {
    // Process update without UI context
    final notified = await TripSyncService.handleBackgroundUpdate(
      message.data,
    );

    if (notified) {
      print('User will see notification');
    } else {
      print('Silent sync - background update only');
    }
  }
}
```

**Key Points**:
- Must be `@pragma('vm:entry-point')` for release builds (already handled)
- Runs in isolated process on Android
- Has limited time (~30 seconds on iOS, ~9 minutes on Android)
- Cannot access main UI/BuildContext
- Perfect for data sync!

### 3. Foreground vs Background vs Terminated

```dart
class FirebaseMessagingService {
  Future<void> initialize() async {
    // ═════════════════════════════════════════════════════
    // CASE 1: APP IN FOREGROUND
    // ═════════════════════════════════════════════════════
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // App is open and user is actively using it
      // We can update UI in real-time, show in-app banners
      // User sees smooth transition
    });

    // ═════════════════════════════════════════════════════
    // CASE 2: APP IN BACKGROUND
    // ═════════════════════════════════════════════════════
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,  // Runs silently!
    );

    // ═════════════════════════════════════════════════════
    // CASE 3: APP TERMINATED
    // ═════════════════════════════════════════════════════
    final initialMessage = 
      await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // App was just opened from notification tap
      // Handle the message here
      // Restore state if needed
    }
  }
}
```

### 4. State Management Pattern

**Location**: [lib/state/trip_provider.dart](lib/state/trip_provider.dart)

```dart
class TripProvider extends ChangeNotifier {
  List<Trip> _trips = [];  // Single source of truth
  
  // Update from any source (sync, user action, push)
  Future<void> updateTrip(Trip updatedTrip) async {
    final index = _trips.indexWhere((trip) => trip.id == updatedTrip.id);
    
    if (index >= 0) {
      _trips[index] = updatedTrip;  // Update in list
    } else {
      _trips.add(updatedTrip);       // Add new trip
    }
    
    // Persist changes
    await TripSyncService.saveTrip(updatedTrip);
    
    // Notify all listeners (UI rebuilds automatically!)
    notifyListeners();
  }
}
```

**In UI**:
```dart
// Automatically rebuilds when TripProvider changes
Consumer<TripProvider>(
  builder: (context, tripProvider, child) {
    return ListView(
      children: tripProvider.trips
        .map((trip) => TripCard(trip: trip))
        .toList()
    );
  },
)
```

### 5. Local Storage Strategy (Offline-First)

**Location**: [lib/services/trip_sync_service.dart](lib/services/trip_sync_service.dart#L78-L100)

```dart
// Storage keys: "trip_FLIGHTID"
// Example: "trip_AA123"

// SAVE
await prefs.setString('trip_AA123', jsonEncode(trip.toJson()));

// LOAD
final tripJson = prefs.getString('trip_AA123');
final trip = Trip.fromJson(jsonDecode(tripJson));

// Benefits:
// ✅ App works without internet
// ✅ Instant app startup
// ✅ Survives phone restart
// ✅ Can compare old vs new state (for smart notifications)
```

### 6. Serialization Pattern

**Location**: [lib/models/trip.dart](lib/models/trip.dart#L30-L75)

```dart
class Trip {
  // Convert object to JSON (for storage/network)
  Map<String, dynamic> toJson() => {
    'id': id,
    'flightNumber': flightNumber,
    'status': status.toString().split('.').last,  // Enum to string
    'scheduledTime': scheduledTime.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    // ... other fields
  };

  // Convert JSON back to object (from storage/network)
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      flightNumber: json['flightNumber'] as String,
      status: _parseStatus(json['status'] as String),
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      // ... parse other fields
    );
  }
}
```

**Common Interview Question**: "How do you handle data persistence?"
**Answer**: Use toJson/fromJson pattern with shared_preferences for simple cases, Hive for complex data.

## Test Scenarios for Demo

### Scenario 1: Silent Sync (No User Notification)

1. App has: "Flight AA123 - On Time"
2. Backend sends: Same status, no time change
3. Result: ✓ Data updates silently (no notification)

### Scenario 2: Status Change (Show Notification)

1. App has: "Flight AA123 - On Time"
2. Backend sends: "Flight AA123 - Delayed"
3. Result: 🔔 Notification: "Flight AA123 is now Delayed"

### Scenario 3: Gate Change (Show Notification)

1. App has: "Gate 15"
2. Backend sends: "Gate 28"
3. Result: 🔔 Notification shown (user needs to go to new gate!)

### Scenario 4: Minor Time Change (No Notification)

1. App has: "2:30 PM"
2. Backend sends: "2:32 PM" (2 min change)
3. Result: ✓ Silent update (less than 5 min threshold)

### Scenario 5: Major Time Change (Show Notification)

1. App has: "2:30 PM"
2. Backend sends: "2:45 PM" (15 min change)
3. Result: 🔔 Notification shown

## Common Interview Questions & Answers

### Q: "How do you handle the case when the app is terminated?"
**A**: Firebase caches the message and calls our background handler when app starts. If we need initial state, we call `getInitialMessage()` in main(). Local storage ensures we always have the last known good state.

### Q: "Why not just show every notification?"
**A**: Notification fatigue. Users will disable notifications or uninstall the app. Smart filtering balances reliability with great UX.

### Q: "How do you ensure data consistency?"
**A**: Single source of truth in SharedPreferences. Every change is persisted before notifying listeners. Provider ensures UI stays in sync.

### Q: "What if the network request fails during sync?"
**A**: We gracefully handle errors, log them, and keep the locally cached state. User can retry with the refresh button.

### Q: "How would you scale this to millions of trips?"
**A**: Switch to Hive (local DB), implement pagination, add indices for faster queries, consider BLoC pattern for more complex state.

## Key Metrics for Interview

- **Offline-first**: Works without internet
- **Background-first**: Syncs even when app is closed
- **Smart notifications**: Reduces noise intelligently
- **Clean architecture**: Clear separation of concerns
- **Production-ready**: Error handling, logging, permissions
- **User-focused**: Considers UX, not just features

## Testing Checklist

- [ ] App starts with cached trips (no network)
- [ ] Pull-to-refresh works and updates trips
- [ ] Simulation button correctly triggers updates
- [ ] Status changes show notifications
- [ ] Gate changes show notifications
- [ ] Small time changes DON'T show notifications
- [ ] First sync doesn't spam notifications
- [ ] App handles permission denials gracefully
- [ ] Logs show background handler invocations
- [ ] Data persists across app restarts
