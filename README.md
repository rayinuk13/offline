# Offline

A modern, clean iOS media player app for importing and playing MP3/MP4 files with playlist support and background audio.

## Features

- **📁 Upload** — Import MP3, MP4, M4A, AAC, WAV, MOV files from your device's Files app (supports multi-select)
- **🎵 Library** — Browse all imported media with title, artist, album artwork, and duration
- **📋 Playlists** — Create, rename, and delete playlists; add/remove songs; reorder tracks
- **⬇️ Download / Share** — Export playlist files via the iOS share sheet (save to Files, AirDrop, etc.)
- **🔊 Background Audio** — Continues playing when the screen is locked or the app is backgrounded
- **🎛️ Lock Screen Controls** — Full Control Centre and lock screen integration (MPNowPlayingInfoCenter)
- **▶️ Full Player** — Now-playing screen with progress slider, skip-forward/back 15s, shuffle, and repeat modes
- **📲 Mini Player** — Persistent mini-player bar visible across all tabs with playback progress

## Requirements

| | Version |
|---|---|
| iOS | 17.0+ |
| Xcode | 15.0+ |
| Swift | 5.9+ |

## Getting Started

1. Clone the repository
2. Open `Offline.xcodeproj` in Xcode 15+
3. Select your target device or simulator (iPhone or iPad)
4. Set your development team under **Signing & Capabilities**
5. Build & run (`⌘R`)

## Project Structure

```
Offline/
├── App/
│   ├── OfflineApp.swift          # @main entry point
│   └── Info.plist                # Background audio mode, permissions
├── Models/
│   ├── MediaItem.swift           # Audio/video file model
│   └── Playlist.swift            # Playlist model + helpers
├── Services/
│   ├── AppStore.swift            # Observable state + JSON persistence
│   ├── AudioPlayerService.swift  # AVPlayer, background audio, lock screen
│   ├── FileImportService.swift   # Document picker + AVFoundation metadata
│   └── DownloadService.swift     # Export / share playlist files
├── Views/
│   ├── ContentView.swift         # Tab bar root
│   ├── Library/LibraryView.swift
│   ├── Playlists/
│   │   ├── PlaylistsView.swift
│   │   └── PlaylistDetailView.swift
│   ├── Player/
│   │   ├── PlayerView.swift      # Full-screen now-playing
│   │   └── MiniPlayerView.swift  # Persistent mini-player
│   └── Components/
│       ├── MediaRowView.swift
│       └── AddToPlaylistSheet.swift
└── Extensions/
    └── Color+Offline.swift       # Design-system colours

OfflineCore/                      # Pure-Swift models (Linux-testable via SPM)
OfflineTests/                     # Unit tests for models and services
```

## Running Tests (SPM)

The core models and services are tested via Swift Package Manager and run on Linux CI:

```bash
swift test
```
