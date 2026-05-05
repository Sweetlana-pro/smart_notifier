# Smart Notifier - Travel Trip Management App

A lightweight Flutter application that demonstrates intelligent push notification handling with silent background sync - perfect for showcasing reliable, real-world app architecture.

## 🎯 Core Concept

Instead of just displaying every notification, this app intelligently:
- Receives silent push messages (data-only, no user-facing alert)
- Updates trip data in the background
- Compares old vs new state
- Shows notification **only if something meaningful changed**

This showcases production-grade reliability and state management - exactly what interviewers look for.

## ✨ Key Features

### 1. **Trip List Screen**
- Displays active trips with real-time status
- Status indicators: On Time, Delayed, Gate Changed, Cancelled
- Shows flight number, origin/destination, scheduled time, and gate number
- Pull-to-refresh to manually sync updates

### 2. **Push Notification System** (Firebase Cloud Messaging)
- **Foreground**: In-app updates and snackbars
- **Background**: System notifications with proper permissions
- **Terminated**: Handled gracefully on app restart
- Smart notification trigger only on state changes

### 3. **Silent Background Sync** ⭐ (The Star Feature)
The core differentiator:
```
1. Receive data-only push message (silent)
2. Update local trip info in background
3. Compare previous state with new state
4. Show notification only if meaningful change detected
5. Update UI when user opens app
```

### 4. **State Management**
- **Provider** pattern for reactive state updates
- Single source of truth for trip data
- Efficient rebuilds only when data changes
- Clean separation of concerns

### 5. **Local Storage**
- **shared_preferences** for persistent trip storage
- Last known state always available
- Immediate app startup without network wait

## 🏗️ Architecture

```
lib/
├── main.dart                          # App initialization and Firebase setup
├── firebase_options.dart              # Firebase configuration
├── models/
│   └── trip.dart                      # Trip data model with serialization
├── services/
│   ├── notification_service.dart      # Local notifications management
│   ├── background_handler.dart        # Firebase messaging & background tasks
│   └── trip_sync_service.dart         # Core sync logic (comparison & smart notifications)
├── state/
│   └── trip_provider.dart             # Provider-based state management
└── screens/
    └── trip_list_screen.dart          # Main UI with trip list and simulation
```

## 💡 Smart Sync Logic (Interview Talking Point)

### The Decision Tree
```dart
shouldNotify(oldTrip, newTrip) {
  // Never notify on first sync
  if (oldTrip == null) return false;
  
  // Always notify on status change
  if (oldTrip.status != newTrip.status) return true;
  
  // Gate changes are important
  if (oldTrip.gate != newTrip.gate) return true;
  
  // Only notify on significant time changes (>5 min)
  if (timeDifference > 5 minutes) return true;
  
  return false;  // No notification for noise
}
```

This is the key that separates a well-designed app from spam notifications.

## 🔧 Tech Stack

- **Flutter**: Cross-platform UI framework
- **Firebase Core**: Backend infrastructure
- **Firebase Cloud Messaging (FCM)**: Push notifications
- **flutter_local_notifications**: System notifications
- **Provider**: State management (lightweight, industry-standard)
- **shared_preferences**: Local storage
- **intl**: Date/time formatting

## 📱 Key Implementation Details

### Background Message Handler
```dart
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This runs even when app is closed!
  final notified = await TripSyncService.handleBackgroundUpdate(
    message.data,
  );
}
```

### Sync Service Core
```dart
// Load old state
final oldTrip = await storage.getTrip(id);
final newTrip = Trip.fromJson(data);

// Smart comparison
if (oldTrip.status != newTrip.status) {
  showNotification(newTrip);  // Only notify on real changes
}

// Persist new state
await storage.saveTrip(newTrip);
```

### State Reactivity
```dart
// Provider automatically notifies UI
await updateTrip(updatedTrip);
notifyListeners();  // Rebuilds only affected widgets
```

## 🚀 Running the App

### Prerequisites
1. Flutter SDK installed
2. Firebase project created
3. Google Play Services (Android)
4. CocoaPods (iOS)

### Setup Steps

**1. Install dependencies**
```bash
flutter pub get
```

**2. Configure Firebase**
- Follow Firebase Console setup for your project
- Update `lib/firebase_options.dart` with your credentials
- For Android: Place `google-services.json` in `android/app/`
- For iOS: Place `GoogleService-Info.plist` in `ios/Runner/`

**3. Run the app**
```bash
flutter run
```

### Testing Background Sync

The app includes a **simulation feature** (FAB with cloud icon):
1. Tap the floating action button
2. Select a trip and new status (e.g., "Delayed" → "Gate Changed")
3. Backend update is simulated
4. Watch the app sync automatically and show notification!

## 🧪 Example Push Payload (for testing)

Send this via Firebase Console or backend API:

```json
{
  "data": {
    "id": "AA123",
    "flightNumber": "AA123",
    "origin": "LAX",
    "destination": "JFK",
    "status": "delayed",
    "scheduledTime": "2024-05-04T14:30:00Z",
    "gate": 42,
    "lastUpdated": "2024-05-04T14:20:00Z"
  },
  "notification": {
    "title": "Trip Update",
    "body": "New update available"
  }
}
```

The app will:
1. Receive the silent data message
2. Compare with old state (was it already delayed?)
3. Only show notification if status actually changed
4. Update local storage
5. Refresh UI on next app open

## 📊 What Makes This Interview-Worthy

✅ **Handles edge cases**: Gracefully manages terminated app, background state, etc.
✅ **Smart notifications**: Reduces noise by only alerting on real changes
✅ **Persistent state**: Uses local storage to survive app restarts
✅ **Clean architecture**: Services, models, state management clearly separated
✅ **Real-world scenario**: Travel/flight updates are relatable yet non-trivial
✅ **Production-ready**: Proper error handling, logging, permissions

## 🔐 Future Enhancements

- Add Bloc/Cubit alternative for state management
- Implement Hive for more complex local storage
- Add end-to-end encryption for sensitive data
- Real backend API integration
- User preferences for notification types
- Trip search and filtering

## 📝 Interview Explanation Template

*"This app demonstrates reliable push notification handling with smart state comparison. Instead of showing every notification, it receives silent data messages, updates local trip information in the background, and intelligently determines whether the user needs to be notified based on meaningful state changes. This approach reduces notification noise while ensuring users never miss important updates. The architecture uses Provider for state management, shared_preferences for offline-first storage, and separates concerns into clean service layers."*

## 📄 License

MIT License - Use freely for portfolio and educational purposes
