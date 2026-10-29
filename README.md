# Finals-ELevate-Merch-Supabase-Xendit

![GitHub stars](https://img.shields.io/github/stars/Win1T102/Finals-ELevate-Merch-Supabase-Xendit?style=for-the-badge&logo=github) ![GitHub forks](https://img.shields.io/github/forks/Win1T102/Finals-ELevate-Merch-Supabase-Xendit?style=for-the-badge&logo=github) ![GitHub issues](https://img.shields.io/github/issues/Win1T102/Finals-ELevate-Merch-Supabase-Xendit?style=for-the-badge&logo=github) ![Last commit](https://img.shields.io/github/last-commit/Win1T102/Finals-ELevate-Merch-Supabase-Xendit?style=for-the-badge&logo=github)

## 📑 Table of Contents

- [Description](#description)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Available Scripts](#available-scripts)
- [Project Structure](#project-structure)
- [Development Setup](#development-setup)
- [Contributors](#contributors)
- [Contributing](#contributing)

## 📝 Description

Finals-ELevate-Merch-Supabase-Xendit — a mobile app built with Android (Native), Flutter, Java (Gradle), Kotlin, iOS (Native).

## 📸 Screenshots

![elevate pin](https://raw.githubusercontent.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit/main/assets/images/elevate/elevate pin.png)

![elevate shirt](https://raw.githubusercontent.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit/main/assets/images/elevate/elevate shirt.png)

![elevatebm](https://raw.githubusercontent.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit/main/assets/images/elevate/elevatebm.png)

![elevatebm2](https://raw.githubusercontent.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit/main/assets/images/elevate/elevatebm2.png)

![elevatebm3](https://raw.githubusercontent.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit/main/assets/images/elevate/elevatebm3.png)

![elevatebm4](https://raw.githubusercontent.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit/main/assets/images/elevate/elevatebm4.png)

## 🛠️ Tech Stack

![Android (Native)](https://img.shields.io/badge/Android%20(Native)-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Java (Gradle)](https://img.shields.io/badge/Java%20(Gradle)-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white) ![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white) ![iOS (Native)](https://img.shields.io/badge/iOS%20(Native)-000000?style=for-the-badge&logo=apple&logoColor=white)

## ⚡ Quick Start

```bash

# 1. Clone the repository
git clone https://github.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit.git

# Get packages and run
flutter pub get && flutter run
```

## 🚀 Available Scripts

- **run** — `flutter run`
- **test** — `flutter test`

## 📁 Project Structure

```
.
├── analysis_options.yaml
├── assets
│   ├── fonts
│   │   ├── Archivo-400.ttf
│   │   ├── Archivo-500.ttf
│   │   ├── Archivo-600.ttf
│   │   ├── Archivo-700.ttf
│   │   └── Archivo-900.ttf
│   └── images
│       └── elevate
│           ├── elevate pin.jfif
│           ├── elevate pin.png
│           ├── elevate shirt.jfif
│           ├── elevate shirt.png
│           ├── elevate-logo.png
│           ├── elevatebm.jfif
│           ├── elevatebm.png
│           ├── elevatebm2.jfif
│           ├── elevatebm2.png
│           ├── elevatebm3.jfif
│           ├── elevatebm3.png
│           ├── elevatebm4.jfif
│           ├── elevatebm4.png
│           ├── elevatebm5.jfif
│           ├── elevatebm5.png
│           ├── elevatebm6.jfif
│           ├── elevatebm6.png
│           ├── elevatepin2.jfif
│           ├── elevatepin2.png
│           ├── elevatepin3.jfif
│           ├── elevatepin3.png
│           ├── elevatepin4.jfif
│           ├── elevatepin4.png
│           ├── elevatepin5.jfif
│           ├── elevatepin5.png
│           ├── elevatepin6.jfif
│           ├── elevatepin6.png
│           ├── lanyard.jfif
│           ├── lanyard.png
│           ├── lanyard2.jfif
│           ├── lanyard2.png
│           ├── longsleeve.jfif
│           └── longsleeve.png
├── lib
│   ├── config
│   │   └── app_config.dart
│   ├── main.dart
│   ├── models
│   │   ├── cart_item.dart
│   │   ├── order_model.dart
│   │   └── product_model.dart
│   ├── screens
│   │   ├── auth_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── checkout_screen.dart
│   │   ├── home_screen.dart
│   │   ├── order_details_screen.dart
│   │   ├── orders_screen.dart
│   │   ├── payment_webview_screen.dart
│   │   ├── product_details_screen.dart
│   │   ├── product_list_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── root_shell.dart
│   │   └── xendit_webview_screen.dart
│   ├── services
│   │   ├── cart_service.dart
│   │   ├── order_service.dart
│   │   ├── payment_service.dart
│   │   └── product_service.dart
│   ├── theme
│   │   └── app_theme.dart
│   ├── utils
│   │   ├── categories.dart
│   │   ├── formatters.dart
│   │   ├── friendly_error.dart
│   │   ├── ids.dart
│   │   ├── json_values.dart
│   │   ├── layout.dart
│   │   └── validators.dart
│   └── widgets
│       ├── app_header.dart
│       ├── brand_logo.dart
│       ├── cart_icon_button.dart
│       ├── elevate_background.dart
│       ├── empty_state.dart
│       ├── labeled_field.dart
│       ├── product_card.dart
│       ├── product_image.dart
│       ├── product_modal.dart
│       ├── quantity_stepper.dart
│       ├── skeleton_grid.dart
│       ├── status_chip.dart
│       └── store_bottom_bar.dart
├── linux
│   ├── CMakeLists.txt
│   ├── flutter
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   └── runner
│       ├── CMakeLists.txt
│       ├── main.cc
│       ├── my_application.cc
│       └── my_application.h
├── macos
│   ├── Flutter
│   │   ├── Flutter-Debug.xcconfig
│   │   ├── Flutter-Release.xcconfig
│   │   └── GeneratedPluginRegistrant.swift
│   ├── Runner
│   │   ├── AppDelegate.swift
│   │   ├── Assets.xcassets
│   │   │   └── AppIcon.appiconset
│   │   │       ├── Contents.json
│   │   │       ├── app_icon_1024.png
│   │   │       ├── app_icon_128.png
│   │   │       ├── app_icon_16.png
│   │   │       ├── app_icon_256.png
│   │   │       ├── app_icon_32.png
│   │   │       ├── app_icon_512.png
│   │   │       └── app_icon_64.png
│   │   ├── Base.lproj
│   │   │   └── MainMenu.xib
│   │   ├── Configs
│   │   │   ├── AppInfo.xcconfig
│   │   │   ├── Debug.xcconfig
│   │   │   ├── Release.xcconfig
│   │   │   └── Warnings.xcconfig
│   │   ├── DebugProfile.entitlements
│   │   ├── Info.plist
│   │   ├── MainFlutterWindow.swift
│   │   └── Release.entitlements
│   ├── Runner.xcodeproj
│   │   ├── project.pbxproj
│   │   ├── project.xcworkspace
│   │   │   └── xcshareddata
│   │   │       └── IDEWorkspaceChecks.plist
│   │   └── xcshareddata
│   │       └── xcschemes
│   │           └── Runner.xcscheme
│   ├── Runner.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata
│   │       └── IDEWorkspaceChecks.plist
│   ├── RunnerTests
│   │   └── RunnerTests.swift
│   └── lib
│       ├── config
│       │   └── app_config.dart
│       ├── main.dart
│       ├── models
│       │   └── product_model.dart
│       ├── screens
│       │   ├── orders_screen.dart
│       │   ├── product_list_screen.dart
│       │   └── xendit_webview_screen.dart
│       └── services
│           └── payment_service.dart
├── pubspec.lock
├── pubspec.yaml
├── supabase
│   ├── .temp
│   │   ├── cli-latest
│   │   └── linked-project.json
│   ├── functions
│   │   ├── create-payment
│   │   │   └── index.ts
│   │   └── xendit-webhook
│   │       └── index.ts
│   └── migrations
│       ├── 20261023120000_elevate_merch_checkout.sql
│       └── 20261024183000_seed_all_elevate_merchandise.sql
├── test
│   └── widget_test.dart
├── web
│   ├── favicon.png
│   ├── icons
│   │   ├── Icon-192.png
│   │   ├── Icon-512.png
│   │   ├── Icon-maskable-192.png
│   │   └── Icon-maskable-512.png
│   ├── index.html
│   └── manifest.json
└── windows
    ├── CMakeLists.txt
    ├── flutter
    │   ├── CMakeLists.txt
    │   ├── generated_plugin_registrant.cc
    │   ├── generated_plugin_registrant.h
    │   └── generated_plugins.cmake
    └── runner
        ├── CMakeLists.txt
        ├── Runner.rc
        ├── flutter_window.cpp
        ├── flutter_window.h
        ├── main.cpp
        ├── resource.h
        ├── resources
        │   └── app_icon.ico
        ├── runner.exe.manifest
        ├── utils.cpp
        ├── utils.h
        ├── win32_window.cpp
        └── win32_window.h
```

## 🛠️ Development Setup

### Flutter
1. Install the [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. `flutter pub get && flutter run`

## 👥 Contributors

Thanks to everyone who has contributed to this project:

<p align="left">
<a href="https://github.com/Win1T102" title="Win1T102"><img src="https://avatars.githubusercontent.com/u/203738107?v=4&s=64" width="64" height="64" alt="Win1T102" style="border-radius:50%" /></a>
</p>

[See the full list of contributors →](https://github.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit/graphs/contributors)

## 👥 Contributing

Contributions are welcome! Here's the standard flow:

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/Win1T102/Finals-ELevate-Merch-Supabase-Xendit.git`
3. **Branch**: `git checkout -b feature/your-feature`
4. **Commit**: `git commit -m 'feat: add some feature'`
5. **Push**: `git push origin feature/your-feature`
6. **Open** a pull request

Please follow the existing code style and include tests for new behavior where applicable.

---

<div align="center">

[![Made with ReadmeBuddy](https://img.shields.io/badge/Made%20with-ReadmeBuddy-8B5CFF?style=for-the-badge&logo=markdown&logoColor=white)](https://readmebuddy.com)

<sub>Generate beautiful READMEs in seconds → <a href="https://readmebuddy.com">readmebuddy.com</a></sub>

</div>
