# Zerocks — Secure Printing Platform

A secure document printing platform connecting customers to local print shops.

## Project Structure

```
zerocks/
├── zerocks_common/        # Shared Dart package (models + services)
├── zerocks_customer/      # Customer Android app
├── zerocks_shop/          # Shop Windows app
└── firebase/              # Security rules & indexes
```

## Prerequisites

- Flutter SDK 3.35+ installed
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- A Firebase project with Blaze plan (for phone auth)
- Google Maps API key with Maps SDK for Android enabled

## Quick Start

### 1. Firebase Setup

```bash
# Login to Firebase
firebase login

# Create or select your Firebase project
firebase projects:list

# Enable required services in Firebase Console:
# - Authentication → Phone (for customers)
# - Authentication → Email/Password (for shops)
# - Cloud Firestore
# - Firebase Storage
# - Cloud Messaging
```

### 2. Configure Customer App (Android)

```bash
cd zerocks_customer

# Run FlutterFire to generate firebase_options.dart
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android

# Add your Google Maps API key
# Edit: android/app/src/main/AndroidManifest.xml
# Replace: YOUR_GOOGLE_MAPS_API_KEY_HERE
```

After `flutterfire configure`, update `lib/main.dart` to import and use the generated options:

```dart
import 'firebase_options.dart';

// In main():
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### 3. Configure Shop App (Windows)

```bash
cd zerocks_shop

# Run FlutterFire to generate firebase_options.dart
flutterfire configure --project=YOUR_PROJECT_ID --platforms=windows
```

Same `main.dart` update as above.

### 4. Deploy Security Rules

```bash
# From the zerocks/ root directory
firebase deploy --only firestore:rules --project=YOUR_PROJECT_ID
firebase deploy --only storage --project=YOUR_PROJECT_ID
```

### 5. Create a Test Shop

Add a document to the `shops` collection in Firestore Console:

```json
{
  "name": "Test Print Shop",
  "address": "123 Main Street, City",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "isOnline": true,
  "ownerId": "SHOP_OWNER_UID",
  "pricePerPage": 2.0,
  "createdAt": "SERVER_TIMESTAMP"
}
```

The `ownerId` should match the UID of the email/password account you create for the shop.

### 6. Run

```bash
# Customer app (Android)
cd zerocks_customer
flutter run

# Shop app (Windows — must be on Windows)
cd zerocks_shop
flutter run -d windows
```

## Tech Stack

| Category | Technology |
|----------|-----------|
| Frontend | Flutter (Android + Windows) |
| State Management | Riverpod 3.x |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Maps | Google Maps Flutter |
| QR Scanning | mobile_scanner |
| PDF Preview | Syncfusion Flutter PDF Viewer |

## App Flow

1. Customer opens Android app → Phone OTP login
2. Finds nearby shop on map or scans shop QR code
3. Uploads PDF/image securely to Firebase Storage
4. Shop Windows app receives job in real-time
5. Shop previews file (no download) and prints
6. Shop marks job as "Completed"
7. File auto-deletes from Firebase Storage

## Security

- **Firestore rules**: Role-based access (users own their data, shops own their queue)
- **Storage rules**: 10 MB limit, PDF/image only, authenticated access
- **Auto-delete**: Files removed from Storage on job completion
- **No local caching**: Customer app never downloads files locally
- **No download button**: Shop app preview has no save/export option
# zerocks
