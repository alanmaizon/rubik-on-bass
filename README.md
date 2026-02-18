# Rubik Bass

An interactive 4x4 Rubik's Cube audiovisual sequencer available as a **web app** and a **native iOS app**.

## About The Project

Rubik Bass is a unique musical instrument that transforms a fully interactive 4x4 Rubik's Cube into a 16-step arpeggio sequencer. The colors on the face of the cube directly map to musical notes, creating a dynamic and visually engaging way to compose music.

What started as a simple 3D model has evolved into a feature-rich creative tool with controls for tempo, note muting, and cube manipulation — available on both the web and iOS.

## Repository Structure

```
rubik-on-bass/
├── web/            # Web version (HTML/JS)
│   ├── index.html
│   ├── script.js
│   └── *.wav       # Audio samples
├── ios/            # iOS version (Swift/SwiftUI)
│   ├── RubikCube/          # Xcode project source files
│   │   ├── Assets.xcassets/
│   │   ├── Audio/          # Audio samples
│   │   ├── AudioManager.swift
│   │   ├── ContentView.swift
│   │   ├── Models.swift
│   │   ├── RotationControlsView.swift
│   │   ├── RubikCubeSequencerApp.swift
│   │   ├── RubikCubeViewModel.swift
│   │   └── SceneKitView.swift
│   └── RubikCube.xcodeproj.zip
└── README.md
```

## Features (Both Versions)

  * **Interactive 4x4 Rubik's Cube:** A fully functional 4x4 cube that can be rotated and scrambled.
  * **Audiovisual Sequencer:** The 16 colors on the front face are read in real-time to create a looping 16-note arpeggio.
  * **Custom Audio Samples:** Six `.wav` audio samples mapped to cube face colors and musical notes.
  * **Interactive Muting:** Tap directly on any sticker on the cube to toggle its note on or off.
  * **Real-time Tempo Control:** Adjustable BPM (Beats Per Minute) for precise sequencer speed.
  * **Master Controls:** Includes Mute All, Unmute All, Reset Cube, and Scramble.
  * **Visual Feedback:** Active stickers are highlighted in sync with the sequencer.

## Differences Between Web and iOS Versions

| Feature | Web | iOS |
|---|---|---|
| **3D Engine** | Three.js | SceneKit |
| **Audio Engine** | Tone.js (`Tone.Sampler` + `Tone.Sequence`) | AVAudioEngine (`AVAudioPlayerNode`) |
| **Sequencer Timing** | `Tone.Transport` (sample-accurate scheduling) | `Timer` (run-loop based scheduling) |
| **UI Framework** | HTML/CSS with collapsible side menu | SwiftUI with overlay controls |
| **Rotation Controls** | Named face turns: U, L, R, D + inner slices (u, l, r) with clockwise/counter-clockwise | Orientation-independent slice buttons: R1–R4 (rows), C1–C4 (columns), A1–A4 (aisles) |
| **Note Length Toggle** | Half Note Length checkbox (e.g. `16n` → `32n`) | Half-length toggle (planned) |
| **Orbit / Camera** | OrbitControls (mouse drag + touch) | Built-in SceneKit camera control (`allowsCameraControl`) |
| **Touch Handling** | Custom drag vs. tap detection with threshold + duration | Native `UITapGestureRecognizer` (SceneKit handles orbit separately) |
| **Mute Visuals** | Color dimmed to 40% brightness | Managed via published state (highlight set) |
| **Sticker Halo Effect** | Emissive material glow on note play | Highlight state via `@Published` set |
| **Front Face Detection** | Camera-relative dot product on face normals | Camera-relative dot product on face normals (same algorithm) |
| **Minimum Requirements** | Modern browser with ES6 module support | iOS 15.0 or later |

## Getting Started

### Web Version

1.  **Clone the repository** and navigate to the `web/` directory.

2.  **Run a local server** (required for audio loading due to CORS policy):

      * **Python:** `cd web && python -m http.server`
      * **Node.js:** `npx live-server web`
      * **VS Code:** Use the Live Server extension on `web/index.html`.

3.  **Open** `http://localhost:8000` (or the address shown) in your browser.

#### Customizing Audio Samples

Place your own `.wav` files in the `web/` directory and update the `synthSamples` object in `web/script.js`:

```javascript
const synthSamples = {
    'C4': 'your_white_note.wav',
    'D4': 'your_red_note.wav',
    // etc...
};
```

### iOS Version

1.  **Clone the repository.**
2.  **Unzip** `ios/RubikCube.xcodeproj.zip` into the `ios/` directory.
3.  **Open** the `.xcodeproj` in Xcode.
4.  **Build and run** on a simulator or device (iOS 15.0+).

Audio samples are bundled in `ios/RubikCube/Audio/`.

## How to Use

  * **Rotate the Cube:** Click and drag (web) or use touch gestures (both) to orbit the 3D view.
  * **Turn Faces:**
      * *Web:* Open the **MENU** panel and use the `U`, `L`, `R`, `D` buttons for outer faces and `u`, `l`, `r` for inner slices. The apostrophe (') indicates counter-clockwise.
      * *iOS:* Use the **R1–R4** (row), **C1–C4** (column), and **A1–A4** (aisle) buttons around the screen edges.
  * **Control the Sequencer:** Adjust **BPM**, toggle **Half Note Length**, and press **Play/Stop**.
  * **Mute Notes:** Tap any colored sticker on the cube to mute or unmute its note.
  * **Master Controls:** Use Mute All, Unmute All, Reset Cube, and Scramble.

## Technologies Used

  * **Web:** JavaScript (ES6 Modules), Three.js, Tone.js
  * **iOS:** Swift, SwiftUI, SceneKit, AVFoundation

It's been a pleasure building this incredible project with help of Gemini 2.5
