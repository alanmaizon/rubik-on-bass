# Copilot Instructions for Rubik Bass

## Project Overview

Rubik Bass is an interactive 4x4 Rubik's Cube audiovisual sequencer available as a **web app** and a **native iOS app**. The 16 stickers on the cube's front face map to musical notes, creating a looping 16-step arpeggio. Users can rotate the cube, mute individual stickers, and adjust tempo.

## Repository Structure

- `web/` — Web version (vanilla JavaScript with ES6 modules, Three.js for 3D, Tone.js for audio)
- `ios/RubikCube/` — iOS version (Swift, SwiftUI, SceneKit for 3D, AVFoundation for audio)
- `README.md` — Project documentation

## Key Domain Concepts

- **4x4 Rubik's Cube**: A fully interactive cube with 6 colored faces (white, red, blue, orange, green, yellow) and an internal black color for non-visible sides.
- **Front face detection**: The face most aligned with the camera is determined via dot product of face normals against the camera direction. This algorithm is shared across both platforms.
- **Color-to-note mapping**: Each face color maps to a fixed musical note — White→C4, Red→D4, Blue→E4, Orange→G4, Green→A4, Yellow→C5. This mapping must stay consistent across platforms.
- **16-step sequencer**: The 16 stickers on the front face are read left-to-right, top-to-bottom to form a looping arpeggio.
- **Muting**: Individual stickers can be muted/unmuted by tapping them. Muted stickers are skipped during playback.
- **Rotation moves**: Named face/slice turns (U, u, D, d, L, l, R, r, F, f, B, b) with clockwise/counter-clockwise variants. Rotations are queued and animated sequentially.

## Web Version (`web/`)

### Tech Stack
- Vanilla JavaScript with ES6 module imports
- Three.js for 3D rendering
- Tone.js for audio (`Tone.Sampler` + `Tone.Sequence`)
- No build tools, bundlers, or package managers — runs directly via a local HTTP server

### Code Conventions
- Single file (`script.js`) with global state variables at the top
- Function-based architecture (no classes)
- `camelCase` for variables and functions
- `UPPER_SNAKE_CASE` for constant objects (`CUBE_COLORS`, `CUBE_MOVES`, `COLOR_TO_NOTE_MAP`)
- `Set` used for tracking muted stickers
- Array used as a queue for rotation animations
- ES6 module imports from CDN (Three.js, Tone.js)
- Audio samples are `.wav` files in the `web/` directory

### Key Functions
- `init()` — Sets up Three.js scene, camera, renderer, lighting, and event listeners
- `createRubikCube()` — Builds the 4x4 cube geometry with colored sticker materials
- `rotateFace(moveName, clockwise)` — Queues and animates a face/slice rotation
- `getFrontFaceStickers()` — Identifies the 16 stickers on the camera-facing side
- `startSequencer()` / `stopSequencer()` — Controls Tone.js-based arpeggio playback
- `handleCanvasClick()` — Raycasts to detect sticker taps for muting
- `loadAudioAssets()` — Loads `.wav` samples into `Tone.Sampler`

## iOS Version (`ios/RubikCube/`)

### Tech Stack
- Swift with SwiftUI for UI
- SceneKit for 3D rendering
- AVFoundation (`AVAudioEngine` + `AVAudioPlayerNode`) for audio
- Xcode project (`.xcodeproj` distributed as a zip)
- Minimum deployment target: iOS 15.0

### Code Conventions
- MVVM architecture: `RubikCubeViewModel` (ObservableObject) drives the UI
- `PascalCase` for types/structs/enums, `camelCase` for properties and methods
- `@Published` properties for reactive UI state (BPM, playing state, highlighted stickers)
- `// MARK: -` comments to organize code sections
- File header comments with filename, project name, and creation date
- `private` access for internal methods (e.g., `setupAudio()`, `loadAudioSamples()`)
- Singleton pattern for `AudioManager` (`static let shared`)
- `Set<String>` for muted and highlighted sticker tracking

### Key Files
- `RubikCubeSequencerApp.swift` — App entry point (`@main`)
- `ContentView.swift` — Main SwiftUI layout with overlay controls
- `RubikCubeViewModel.swift` — Core logic: cube creation, rotation, sequencer, audio
- `SceneKitView.swift` — `UIViewRepresentable` wrapping `SCNView`
- `AudioManager.swift` — Audio engine setup and sample playback (singleton)
- `Models.swift` — Enums (`CubeFace`, `AxisType`), structs (`CubeColors`, `MoveConfig`, `StickerInfo`), helper functions
- `RotationControlsView.swift` — Row/Column/Aisle rotation button UI

### Key Types
- `CubeFace` — Enum for the six cube faces (front, right, back, left, top, bottom)
- `AxisType` — Enum for rotation axes (x, y, z)
- `CubeColors` — Static color definitions with `colorToNote` dictionary
- `MoveConfig` — Describes a rotation move (axis, layers, sign)
- `StickerInfo` — Identifiable struct representing a sticker with its cubie, face, color, note, and position

## Cross-Platform Consistency

When modifying the sequencer logic, color mappings, or cube behavior, keep both platforms in sync:
- The color-to-note mapping must be identical: White→C4, Red→D4, Blue→E4, Orange→G4, Green→A4, Yellow→C5
- Front face detection uses the same dot-product algorithm on both platforms
- The 4x4 cube dimensions and layer positions (±0.5, ±1.5) are shared
- Audio samples (`.wav` files) are the same across both versions
- BPM range is 20–200 on both platforms
