---
trigger: always_on
---

# Project Environment
- Framework: Flutter
- Game Engine: Flame (using flame_tiled for maps)
- Main Source Code: All custom Dart code is located in the `lib/` directory.
- Assets: Tiled maps are in `assets/tiles/` and Sprites/Images are in `assets/images/`.

# Access & Ignored Rules
- ALWAYS check `pubspec.yaml` for package versions before suggesting any third-party code.
- DO NOT read, analyze, or modify auto-generated folders: `build/`, `.dart_tool/`.
- DO NOT touch platform-specific folders (`ios/`, `android/`, `web/`, `windows/`, `macos/`, `linux/`) unless I explicitly ask you to fix a native platform bug.