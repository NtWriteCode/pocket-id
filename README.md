# Pocket ID

A simple, cross-platform Flutter app for storing personal identification numbers.

## Features

- **Multi-Person Support**: Track ID cards for multiple people
- **Flexible Card Storage**: Store any type of ID card with custom names and numbers
- **Search & Filter**: Quickly find cards by name or ID number with real-time search
- **Pin Cards**: Keep frequently-used cards at the top of the list
- **Expiration Tracking**: Optional expiration dates with visual warnings (3-month advance notice)
- **Visual Icons**: Add emojis to cards for quick visual identification
- **Privacy-First**: Data stored locally with no cloud dependencies
- **Optional Backup**: Manual WebDAV backup/restore for data portability
- **Cross-Platform**: Works on Android, Desktop (Linux, Windows, macOS), and Web
- **Material 3 Design**: Modern, adaptive UI with light/dark theme support

## Screenshots

### Home Screen
- **Left Drawer**: Browse and select people/profiles
- **Main View**: Shows all cards for the selected person
- **Bottom-right FAB**: Add new cards to current person
- Responsive grid layout on wider screens
- Tap cards to reveal/hide full ID numbers
- Copy ID numbers to clipboard

### Card Form
- Choose from 16 common emoji icons
- Enter card name and ID number
- Simple, focused interface

### Settings Screen
- Configure WebDAV server for backups
- Test connection before saving
- Manual backup and restore operations

## Installation

### Prerequisites
- Flutter SDK 3.10.7 or higher
- For Android: Android Studio with SDK tools
- For Desktop: Platform-specific build tools
- For Web: Chrome or another web browser

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd pocket_id/pocket_id
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# Android
flutter run -d android

# Linux
flutter run -d linux

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Web
flutter run -d chrome
```

## Data Storage

### Local Storage
- **Native platforms** (Android, Desktop): JSON file in app documents directory
- **Web**: Browser localStorage
- **Format**: Human-readable JSON with all people and cards

### WebDAV Backup (Optional)
Configure a WebDAV server in Settings to enable manual backup/restore:
- Compatible with Nextcloud, ownCloud, and other WebDAV services
- Exports entire database as a single JSON file
- Creates dedicated `pocket-id/` folder on server (prevents conflicts)
- Credentials stored locally for convenience
- No automatic sync - all operations are manual

### End-to-End Encryption (Optional)
Secure your WebDAV backups with client-side encryption:
- **AES-256-GCM** encryption with PBKDF2 key derivation
- Password-based encryption (separate from WebDAV credentials)
- **Real-time password strength meter** with visual feedback
- Checks against 10,000+ common/exposed passwords
- Optional password persistence for convenience
- Smart conflict handling for encryption mismatches
- **Warning**: Lost passwords cannot be recovered!
- See [ENCRYPTION.md](ENCRYPTION.md) for detailed documentation

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── person.dart               # Person data model
│   └── id_card.dart              # ID card data model
├── providers/
│   ├── data_provider.dart        # Main data management
│   └── settings_provider.dart    # Settings management
├── services/
│   ├── storage_service.dart      # Storage abstraction
│   ├── storage_service_stub.dart # Stub implementation
│   ├── storage_service_native.dart # File-based storage
│   ├── storage_service_web.dart  # localStorage implementation
│   └── webdav_service.dart       # WebDAV backup/restore
├── screens/
│   ├── home_screen.dart          # Person list
│   ├── person_detail_screen.dart # Card list for person
│   ├── card_form_screen.dart     # Add/edit card
│   └── settings_screen.dart      # WebDAV configuration
└── widgets/
    └── emoji_picker.dart         # Common emoji icons
```

## Architecture

- **State Management**: Provider pattern for reactive UI
- **Data Persistence**: Platform-specific JSON storage via conditional imports
- **Backup**: Optional WebDAV for remote storage
- **UI**: Material 3 with responsive layouts

## Security Notes

- **No encryption**: Data relies on device-level security
- **Local-first**: All data stored on device by default
- **Manual backups**: No automatic cloud sync reduces exposure
- **Masked display**: ID numbers masked by default, tap to reveal

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Linux
```bash
flutter build linux --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Web
```bash
flutter build web --release
```

## Data Format

The app uses a simple JSON format:

```json
{
  "version": 1,
  "exportedAt": "2026-01-21T10:00:00Z",
  "people": [
    {
      "id": "uuid",
      "name": "John Doe",
      "createdAt": "2026-01-21T09:00:00Z"
    }
  ],
  "cards": [
    {
      "id": "uuid",
      "personId": "uuid",
      "name": "Driver's License",
      "idNumber": "123456789",
      "emoji": "🚗",
      "createdAt": "2026-01-21T09:15:00Z"
    }
  ],
  "settings": {
    "webdavUrl": "https://example.com/webdav",
    "webdavUsername": "user",
    "webdavPassword": "pass"
  }
}
```

## Dependencies

- **provider**: State management
- **uuid**: Generate unique IDs
- **path_provider**: File paths (native platforms)
- **web**: Browser APIs (web platform)
- **webdav_client**: WebDAV operations

## Contributing

This is a simple personal project designed for self-hosting. Feel free to fork and modify for your needs.

## License

MIT License - see LICENSE file for details.

## Disclaimer

This app stores sensitive personal information. Use at your own risk. Always:
- Enable device encryption
- Use strong device passwords
- Keep backups secure
- Verify WebDAV server security
