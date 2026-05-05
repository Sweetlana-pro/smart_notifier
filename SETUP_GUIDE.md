# Setup & Troubleshooting Guide

## Pre-Setup Requirements

### System Requirements
- Flutter SDK: >= 3.11.1
- Android: API 21+ (or Android Studio with emulator)
- iOS: iOS 12.0+ (requires Xcode)
- macOS: Xcode Command Line Tools

### Verify Flutter Setup
```bash
flutter doctor
```

Optional but recommended: Install Xcode for iOS development (required: 30GB+ disk space)

## Firebase Setup (Critical!)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Name it: `smart-notifier` (or your choice)
4. Enable Google Analytics (optional)
5. Create project

### Step 2: Register Android App

1. In Firebase Console, select your project
2. Click "Add App" → "Android"
3. Enter:
   - **Package name**: `com.example.smart_notifier`
   - **App nickname**: Smart Notifier (optional)
4. Click "Register app"
5. Download `google-services.json`
6. Place it in: `android/app/google-services.json`

### Step 3: Register iOS App

1. Click "Add App" → "iOS"
2. Enter:
   - **Bundle ID**: `com.example.smartNotifier`
   - **App nickname**: Smart Notifier (optional)
3. Click "Register app"
4. Download `GoogleService-Info.plist`
5. In Xcode:
   - Open `ios/Runner.xcworkspace`
   - Right-click "Runner" → "Add Files to Runner"
   - Select `GoogleService-Info.plist`
   - Ensure it's added to all targets

### Step 4: Enable Cloud Messaging

1. In Firebase Console
2. Go to: Cloud Messaging tab
3. Note your **Server Key** (needed for sending test messages)

## Project Setup

### Step 1: Install Flutter Dependencies
```bash
cd smart_notifier
flutter pub get
```

### Step 2: Update Firebase Options

Edit [lib/firebase_options.dart](lib/firebase_options.dart) with your Firebase credentials:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyxxxxxxxxxxxxxxxxxxxxxxxx',      // From google-services.json
  appId: '1:123456789:android:abcdef123456',    // From google-services.json
  messagingSenderId: '123456789',                 // From google-services.json
  projectId: 'smart-notifier-xxxxx',              // Your project ID
  storageBucket: 'smart-notifier-xxxxx.appspot.com',
);
```

Get these values from:
- `android/app/google-services.json` (firebase_config)
- Or from Firebase Console → Project Settings → Your Apps

### Step 3: Android Configuration

#### Minimal SDK Update
Edit `android/app/build.gradle.kts`:
```kotlin
android {
    compileSdk = 34  // At least 33
    defaultConfig {
        minSdk = 21    // Firebase requires 21+
        targetSdk = 34
    }
}
```

### Step 4: iOS Configuration

**If using Xcode:**
```bash
cd ios
pod install
cd ..
```

**Minimum iOS version:**
- Edit `ios/Podfile`
- Find: `platform :ios, '12.0'`
- Keep as-is (12.0+) or update to 14.0 for better support

## Building & Running

### First Run (Android)
```bash
flutter run --verbose
```

or 

```bash
flutter run -d android
```

### First Run (iOS)
```bash
flutter run -d ios
```

### Run on Physical Device

**Android:**
```bash
adb devices                    # List connected devices
flutter run -d <device-id>    # Run on specific device
```

**iOS:**
- Connect iPhone via USB
- Trust the device in popup
- In Xcode: Select device from top menu
- `flutter run -d ios`

## Permissions Setup

### Android Permissions

Already configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS Permissions

Already configured in `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses network to sync your trips</string>
<key>NSBonjourServiceTypes</key>
<array>
  <string>_http._tcp</string>
</array>
```

## Testing the App

### Manual Testing

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Initial state:**
   - App loads mock trips
   - Shows: AA123, UA456, DL789

3. **Test pull-to-refresh:**
   - Swipe down on trip list
   - Should see loading indicator
   - Trips update after ~500ms

4. **Test simulation (Background Sync):**
   - Tap floating action button (cloud icon)
   - Select a trip (e.g., AA123)
   - Select new status (e.g., Delayed)
   - Click "Simulate"
   - Should see:
     - Snackbar: "Background update simulated"
     - Notification appear (if status changed)
     - Trip card updates with new status

5. **Test notification details:**
   - Tap launched notification
   - Should see trip card with new status

### Testing Background Sync

#### Test 1: App in Background
1. Open app and load trips
2. Press home button (app goes to background)
3. Send test push (see "Sending Test Messages" below)
4. Should see notification in notification center
5. Tap notification → app opens to trip list

#### Test 2: App Terminated
1. Open app
2. Force close: Settings → Apps → Smart Notifier → Force Stop
3. Send test push
4. Tap notification from notification center
5. App launches and loads cached trips

#### Test 3: Foreground
1. Keep app open
2. Send test push via Firebase Console
3. Should see in-app change immediately

### Sending Test Messages

#### Via Firebase Console (Easiest)

1. Open Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. **Notification title**: "Trip Update"
4. **Notification body**: "Flight AA123 status changed"
5. **Add data field:**
   - Key: `id`
   - Value: `AA123`
6. **Target**: Topic or specific device token
7. Click "Send"

#### Get Device Token

In app, after first run, check console logs:
```
FCM Token: exampleLongTokenString...
```

Copy this token and use in Firebase Console test message.

#### Via REST API (Advanced)

```bash
curl -X POST \
  'https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send' \
  -H 'Authorization: Bearer {ACCESS_TOKEN}' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": {
      "data": {
        "id": "AA123",
        "flightNumber": "AA123",
        "status": "delayed"
      },
      "token": "{FCM_TOKEN}"
    }
  }'
```

## Troubleshooting

### Problem: "Firebase not initialized"

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Problem: "google-services.json not found"

**Solution:**
1. Download from Firebase Console again
2. Place in `android/app/` (exact path: `android/app/google-services.json`)
3. Run:
   ```bash
   flutter clean
   flutter run
   ```

### Problem: "Pods not found" (iOS)

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### Problem: "Permission denied" (Android)

**Solution:**
1. Uninstall app: `flutter clean`
2. Grant permissions when app asks
3. Rebuild: `flutter run`

### Problem: "Notification not showing"

**Solution:**
1. Check Android Notification Settings:
   - Settings → Apps → Smart Notifier → Notifications → Toggle On
2. Check battery optimization:
   - Settings → Battery & Device Care → Optimization → Smart Notifier → Don't Optimize
3. Check Do Not Disturb mode is off

### Problem: "Hot reload/restart not working"

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Problem: "Background handler not called"

**Check:**
1. App has `POST_NOTIFICATIONS` permission (granted in settings)
2. Notification priority is HIGH (in NotificationService)
3. Device has internet connection
4. FCM token is properly configured

**Debug:**
Add logs in `background_handler.dart`:
```dart
print('DEBUG: Background handler called!');
print('DEBUG: Message data: ${message.data}');
```

Run with: `flutter run -v` to see verbose logs

### Problem: "App crashes on startup"

**Solution:**
1. Check if `firebase_options.dart` is properly configured
2. Verify all imports in `main.dart` exist
3. Run: `flutter pub get && flutter clean && flutter run -v`

## IDE Setup

### Android Studio

1. Open project: File → Open → `android/` folder (NOT root)
2. Gradle syncs automatically
3. If error: File → Invalidate Caches

### Visual Studio Code

1. Install Flutter extension (by Dart Code)
2. Open workspace root: Code → Open Folder → smart_notifier
3. Install dependencies: View → Command Palette → "Pub: Get Packages"

### Xcode (iOS)

1. Open: `ios/Runner.xcworkspace` (NOT Runner.xcodeproj!)
2. Select scheme: Select Runner project → Targets → Runner
3. Select device from top menu
4. Cmd+R to run

## Performance Optimization

### For Development

- Use debug build (default): `flutter run`
- Enable verbose logging: `flutter run -v`
- Use cloud debugging: `flutter attach` in separate terminal

### For Testing

- Use release build: `flutter run -d android --release`
- Profile build for performance: `flutter run -d android --profile`

### RAM & Storage

- Clear app cache: Settings → Apps → Smart Notifier → Storage → Clear Cache
- Uninstall and reinstall for clean state
- Check device storage has 50MB+ free

## Next Steps

1. **Configure your Firebase credentials** (most important!)
2. **Test on physical device** (emulator FCM can be unreliable)
3. **Send test messages** from Firebase Console
4. **Verify background sync** by force-closing app
5. **Review [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)** for deep dives

## Still Having Issues?

1. Check Flutter version: `flutter --version`
2. Check Flutter doctor: `flutter doctor -v`
3. Check logs: `flutter run -v` (save full output)
4. Compare setup with official guides:
   - [Flutter Firebase Setup](https://firebase.flutter.dev/)
   - [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
