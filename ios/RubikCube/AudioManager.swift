//
//  AudioManager.swift
//  RubikCube
//
//  Created by Alan Maizon on 22/11/2025.
//

import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var audioEngine = AVAudioEngine()
    private var audioPlayers: [String: AVAudioPlayerNode] = [:]
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]

    init() {
        setupAudio()
    }
    
    private func playSoundInternal(note: String) {
        guard let player = audioPlayers[note], let buffer = audioBuffers[note] else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }
    
    private func setupAudio() {
        let mainMixer = audioEngine.mainMixerNode
        let notes = ["C4", "D4", "E4", "G4", "A4", "C5"]

        for note in notes {
            let player = AVAudioPlayerNode()
            audioEngine.attach(player)
            audioEngine.connect(player, to: mainMixer, format: nil)
            audioPlayers[note] = player
        }

        do {
            try audioEngine.start()
            loadAudioSamples()
        } catch {
            print("Audio engine failed: \(error)")
        }
    }

    private func loadAudioSamples() {
        let sampleMap = ["C4": "white", "D4": "red", "E4": "blue", "G4": "orange", "A4": "green", "C5": "yellow"]

        for (note, filename) in sampleMap {
            if let url = Bundle.main.url(forResource: filename, withExtension: "wav"),
               let file = try? AVAudioFile(forReading: url),
               let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(file.length)) {
                try? file.read(into: buffer)
                audioBuffers[note] = buffer
            }
        }
    }



}

