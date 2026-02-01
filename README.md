
---

## 🚀 Getting Started

### Prerequisites

- [Flutter](https://flutter.dev) SDK ^3.6.1 or higher
- [Firebase](https://firebase.google.com) project
- Android Studio / Xcode (for mobile)
- Chrome (for web testing)


## 📁 Project Structure

web_rtc/
├── android/ # Android platform files
├── ios/ # iOS platform files
├── web/ # Web platform files
├── lib/ # Main application source code
│ ├── video_call/ # Video call feature module
│ │ ├── video_call_controller.dart # Business logic & state
│ │ ├── video_call_entity.dart # Data models
│ │ └── video_call_screen.dart # UI screen
│ ├── firebase_options.dart # Firebase configuration (auto-generated)
│ └── main.dart # App entry point
├── firebase.json # Firebase hosting/deploy config
├── pubspec.yaml # Flutter dependencies
├── pubspec.lock # Locked dependency versions
├── analysis_options.yaml # Dart analyzer rules
├── .gitignore # Git ignore rules
├── .metadata # Flutter project metadata
└── README.md # Project documentation


### Installation

# Clone the repository
git clone https://github.com/your-username/web_rtc.git
cd web_rtc

# Install dependencies
flutter pub get

# Run the app
flutter run
