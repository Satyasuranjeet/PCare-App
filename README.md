# # Personal Care App

A comprehensive Flutter app for managing personal care schedules with notifications, progress tracking, and data backup to MongoDB.

## Features

- 🔐 **User Authentication**: Register and login with local storage
- 📅 **Schedule Management**: Create, edit, and delete personal care schedules
- 🔔 **Smart Notifications**: Customizable notification tones and frequencies
- 📊 **Progress Tracking**: Visual progress bars and calendar view
- 🗓️ **Calendar Integration**: Beautiful calendar with schedule visualization
- ☁️ **Cloud Backup**: Backup data to MongoDB with one-tap sync
- 🌙 **Dark Theme**: Modern, eye-friendly dark UI
- 🔄 **Recurring Schedules**: Daily, weekly, monthly repetitions
- 📱 **Responsive Design**: Works on all screen sizes

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- MongoDB Atlas account (for cloud backup)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Configure MongoDB (optional):
   - Create a MongoDB Atlas account
   - Get your API URL and key
   - Update `lib/services/mongodb_service.dart` with your credentials

3. Run the app:
```bash
flutter run
```

## Key Features

### Schedule Management
- Create schedules with title, description, and time
- Set frequency (once, daily, weekly, monthly)
- Choose notification tones
- Set end dates for recurring schedules

### Progress Tracking
- Daily and weekly progress visualization
- Calendar view with completion status
- Percentage-based progress indicators

### Notifications
- Local notifications with custom tones
- Recurring notifications based on schedule frequency
- Permission handling for Android/iOS

### Data Storage
- Local SQLite database for offline access
- Shared preferences for user settings
- Optional MongoDB backup for cloud sync

## Usage

1. **Register/Login**: Create an account or sign in
2. **Add Schedule**: Tap '+' to create a new care schedule
3. **Set Notifications**: Choose frequency and notification tone
4. **Track Progress**: View calendar and mark completed tasks
5. **Backup Data**: Use the backup button to sync to cloud

Made with ❤️ for better personal care management Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
