//
//  RubikCubeSequencerApp.swift
//  RubikCube
//
//  Created by Alan Maizon on 19/11/2025.
//

import SwiftUI

@main
struct RubikCubeSequencerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Info.plist Configuration Notes
/*
 Make sure to add these permissions to your Info.plist:
 
 1. For audio playback:
    - Background Modes: Audio, AirPlay, and Picture in Picture
 
 2. Add the following audio files to your project:
    - white.wav (for C4)
    - red.wav (for D4)
    - blue.wav (for E4)
    - orange.wav (for G4)
    - green.wav (for A4)
    - yellow.wav (for C5)
 
 3. Required frameworks in your project:
    - SwiftUI
    - SceneKit
    - AVFoundation
    - Combine
 
 4. Minimum iOS version: iOS 15.0 or later
 */

// MARK: - Implementation Notes
/*
 This Swift/SceneKit implementation provides:
 
 1. Full 3D Rubik's Cube with proper face rotations
 2. Audio sequencer with BPM control (20-200 BPM)
 3. Half-length note toggle
 4. Individual sticker muting via tap
 5. Mute all/Unmute all controls
 6. Scramble function (30 random moves)
 7. Reset to solved state
 8. Play/Stop sequencer
 9. Side menu with all controls
 10. Touch gesture support for rotation and tap detection
 
 Key differences from Three.js version:
 - Uses AVAudioEngine instead of Tone.js for audio
 - SceneKit for 3D rendering instead of Three.js
 - Native SwiftUI controls instead of HTML/CSS
 - Timer-based sequencer instead of Tone.Transport
 
 Audio files needed:
 You'll need to create or source six short audio samples (WAV format):
 - C4 (Middle C) - mapped to white
 - D4 - mapped to red
 - E4 - mapped to blue
 - G4 - mapped to orange
 - A4 - mapped to green
 - C5 (High C) - mapped to yellow
 
 Performance considerations:
 - The cube consists of 56 cubie entities (4x4x4 minus hollow center)
 - Animations run at 0.3 seconds per rotation
 - Sequencer updates every 16th note based on BPM
 - Audio engine is optimized for low latency playback
 */
