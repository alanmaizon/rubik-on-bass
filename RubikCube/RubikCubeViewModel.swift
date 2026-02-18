//  RubikCubeViewModel.swift
//  RubikCube
//

import SwiftUI
import SceneKit
import AVFoundation
import Combine

class RubikCubeViewModel: ObservableObject {
    @Published var bpm: Double = 120 { didSet { updateSequencerTempo() } }
    @Published var isHalfLength: Bool = false { didSet { if isPlaying { startSequencer() } } }
    @Published var isPlaying: Bool = false
    @Published var isAnimating: Bool = false
    @Published var currentStep: Int = -1
    @Published var highlightedStickers: Set<String> = []

    // Tracked front face (face most facing the camera)
    @Published var currentFrontFace: CubeFace = .front

    var cubeNode: SCNNode?
    var sceneView: SCNView?
    var allCubies: [SCNNode] = []
    var currentFrontFaceStickers: [StickerInfo] = []
    var mutedStickers: Set<String> = []

    private var rotationQueue: [(move: String, clockwise: Bool)] = []
    private var audioEngine = AVAudioEngine()
    private var audioPlayers: [String: AVAudioPlayerNode] = [:]
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]
    private var sequencerTimer: Timer?
    private var sequenceIndex: Int = 0

    init() {
        setupAudio()
    }

    // MARK: - Audio
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

    // MARK: - Cube creation
    func createCube() -> SCNNode {
        let cube = SCNNode()
        allCubies.removeAll()

        let size: CGFloat = 0.8
        let spacing: CGFloat = 0.05
        let extent: Float = 1.5

        for i in 0..<4 {
            for j in 0..<4 {
                for k in 0..<4 {
                    // hollow inner cubies removed for a 4x4 outer shell
                    if i > 0 && i < 3 && j > 0 && j < 3 && k > 0 && k < 3 { continue }

                    let x = Float(i) - extent
                    let y = Float(j) - extent
                    let z = Float(k) - extent

                    let cubie = createCubie(at: SCNVector3(x, y, z), size: size, spacing: spacing)
                    cube.addChildNode(cubie)
                    allCubies.append(cubie)
                }
            }
        }

        cubeNode = cube
        return cube
    }

    private func createCubie(at position: SCNVector3, size: CGFloat, spacing: CGFloat) -> SCNNode {
        let cubie = SCNNode()
        let faceColors = getFaceColors(for: position)

        let box = SCNBox(width: size, height: size, length: size, chamferRadius: 0)

        var materials: [SCNMaterial] = []
        let colorOrder: [CubeFace] = [.front, .right, .back, .left, .top, .bottom]

        for face in colorOrder {
            let material = SCNMaterial()
            material.diffuse.contents = faceColors[face]!
            material.specular.contents = UIColor.white
            material.shininess = 0.3
            materials.append(material)
        }

        box.materials = materials
        cubie.geometry = box

        let actualPos = SCNVector3(
            position.x * Float(size + spacing),
            position.y * Float(size + spacing),
            position.z * Float(size + spacing)
        )
        cubie.position = actualPos

        cubie.name = "cubie_\(position.x)_\(position.y)_\(position.z)"
        cubie.setValue(NSValue(scnVector3: position), forKey: "originalPosition")
        cubie.setValue(faceColors, forKey: "faceColors")

        return cubie
    }

    private func getFaceColors(for position: SCNVector3) -> [CubeFace: UIColor] {
        var colors: [CubeFace: UIColor] = [:]

        // Right face (+X)
        colors[.right] = (position.x == 1.5) ? CubeColors.blue : CubeColors.black
        // Left face (-X)
        colors[.left]  = (position.x == -1.5) ? CubeColors.green : CubeColors.black
        // Top face (+Y)
        colors[.top]   = (position.y == 1.5) ? CubeColors.yellow : CubeColors.black
        // Bottom face (-Y)
        colors[.bottom] = (position.y == -1.5) ? CubeColors.orange : CubeColors.black
        // Front face (+Z)
        colors[.front] = (position.z == 1.5) ? CubeColors.white : CubeColors.black
        // Back face (-Z)
        colors[.back]  = (position.z == -1.5) ? CubeColors.red : CubeColors.black

        return colors
    }

    // MARK: - Classic single-face rotations (kept)
    func rotateFace(_ move: String, clockwise: Bool) {
        if isAnimating {
            rotationQueue.append((move, clockwise))
            return
        }

        guard let config = CubeMoves.moves[move], let cube = cubeNode else { return }

        isAnimating = true
        let angle = (Float.pi / 2) * config.sign * (clockwise ? 1 : -1)
        let duration: TimeInterval = 0.3

        let cubiesToRotate = allCubies.filter { cubie in
            guard let posValue = cubie.value(forKey: "originalPosition") as? NSValue else { return false }
            let pos = posValue.scnVector3Value
            return config.layers.contains { layer in abs(pos[config.axis] - layer) < 0.1 }
        }

        let rotationGroup = SCNNode()
        cube.addChildNode(rotationGroup)

        for cubie in cubiesToRotate {
            let worldTransform = cubie.worldTransform
            cubie.removeFromParentNode()
            rotationGroup.addChildNode(cubie)
            cubie.transform = cube.convertTransform(worldTransform, from: nil)
        }

        let rotationAxis: SCNVector3
        switch config.axis {
        case .x: rotationAxis = SCNVector3(1,0,0)
        case .y: rotationAxis = SCNVector3(0,1,0)
        case .z: rotationAxis = SCNVector3(0,0,1)
        }

        let rotation = SCNAction.rotate(by: CGFloat(angle), around: rotationAxis, duration: duration)

        rotationGroup.runAction(rotation) { [weak self] in
            guard let self = self else { return }
            for cubie in cubiesToRotate {
                let worldTransform = cubie.worldTransform
                cubie.removeFromParentNode()
                cube.addChildNode(cubie)
                cubie.transform = worldTransform
            }
            rotationGroup.removeFromParentNode()
            self.updateCubiePositions(cubiesToRotate, axis: config.axis, angle: angle)
            self.isAnimating = false

            if let next = self.rotationQueue.first {
                self.rotationQueue.removeFirst()
                self.rotateFace(next.move, clockwise: next.clockwise)
            } else {
                self.updateFrontFaceStickers()
            }
        }
    }

    // MARK: - Generic layer rotation (used by face-relative slices)
    func rotateLayer(axis: AxisType, coordinate: Float, clockwise: Bool) {
        if isAnimating {
            rotationQueue.append((move: "LAYER:\(axis):\(coordinate)", clockwise: clockwise))
            return
        }
        guard let cube = cubeNode else { return }
        isAnimating = true

        let angle = (Float.pi / 2) * (clockwise ? 1 : -1)
        let duration: TimeInterval = 0.28
        let tolerance: Float = 0.1

        let cubiesToRotate = allCubies.filter { cubie in
            guard let posValue = cubie.value(forKey: "originalPosition") as? NSValue else { return false }
            let pos = posValue.scnVector3Value
            switch axis {
            case .x: return abs(pos.x - coordinate) < tolerance
            case .y: return abs(pos.y - coordinate) < tolerance
            case .z: return abs(pos.z - coordinate) < tolerance
            }
        }

        let rotationGroup = SCNNode()
        cube.addChildNode(rotationGroup)

        for cubie in cubiesToRotate {
            let worldTransform = cubie.worldTransform
            cubie.removeFromParentNode()
            rotationGroup.addChildNode(cubie)
            cubie.transform = cube.convertTransform(worldTransform, from: nil)
        }

        let rotationAxis: SCNVector3
        switch axis {
        case .x: rotationAxis = SCNVector3(1,0,0)
        case .y: rotationAxis = SCNVector3(0,1,0)
        case .z: rotationAxis = SCNVector3(0,0,1)
        }

        let rotation = SCNAction.rotate(by: CGFloat(angle), around: rotationAxis, duration: duration)

        rotationGroup.runAction(rotation) { [weak self] in
            guard let self = self else { return }
            for cubie in cubiesToRotate {
                let worldTransform = cubie.worldTransform
                cubie.removeFromParentNode()
                cube.addChildNode(cubie)
                cubie.transform = worldTransform
            }
            rotationGroup.removeFromParentNode()
            self.updateCubiePositions(cubiesToRotate, axis: axis, angle: angle)
            self.isAnimating = false

            if let next = self.rotationQueue.first {
                self.rotationQueue.removeFirst()
                if next.move.starts(with: "LAYER:") {
                    let parts = next.move.split(separator: ":")
                    if parts.count == 3 {
                        let axRaw = String(parts[1])
                        let ax: AxisType = (axRaw == "x") ? .x : (axRaw == "y") ? .y : .z
                        let coord = Float(parts[2]) ?? 1.5
                        self.rotateLayer(axis: ax, coordinate: coord, clockwise: next.clockwise)
                    }
                } else {
                    self.rotateFace(next.move, clockwise: next.clockwise)
                }
            } else {
                self.updateFrontFaceStickers()
            }
        }
    }

    // MARK: - Simple orientation-independent slice APIs
    func rotateRow(_ index: Int, clockwise: Bool) {
        let coords: [Float] = [1.5, 0.5, -0.5, -1.5]
        rotateLayer(axis: .y, coordinate: coords[index], clockwise: clockwise)
    }
    
    func rotateColumn(_ index: Int, clockwise: Bool) {
        let coords: [Float] = [-1.5, -0.5, 0.5, 1.5]
        rotateLayer(axis: .x, coordinate: coords[index], clockwise: clockwise)
    }
    
    func rotateAisle(_ index: Int, clockwise: Bool) {
        let coords: [Float] = [1.5, 0.5, -0.5, -1.5]
        rotateLayer(axis: .z, coordinate: coords[index], clockwise: clockwise)
    }

    // MARK: - Front-face detection and sticker collection
    func updateFrontFaceStickers() {
        guard let sceneView = sceneView, let camera = sceneView.pointOfView, let cube = cubeNode else { return }

        currentFrontFaceStickers.removeAll()

        // 1) compute view vector from camera to cube center
        let camPos = camera.presentation.worldPosition
        let cubePos = cube.presentation.worldPosition
        var viewVec = cubePos - camPos
        viewVec = viewVec.normalized()

        // 2) local face normals (this matches the getFaceColors local coordinate system)
        let faceNormals: [CubeFace: SCNVector3] = [
            .front: SCNVector3(0,0,1),
            .back:  SCNVector3(0,0,-1),
            .right: SCNVector3(1,0,0),
            .left:  SCNVector3(-1,0,0),
            .top:   SCNVector3(0,1,0),
            .bottom:SCNVector3(0,-1,0)
        ]

        // 3) choose the face whose world-normal has the highest dot with viewVec
        var bestFace: CubeFace = .front
        var bestScore: Float = -Float.infinity

        for (face, localNormal) in faceNormals {
            let worldNormal = cube.presentation.convertVector(localNormal, to: nil).normalized()
            let score = dotProduct(worldNormal, viewVec)
            if score > bestScore {
                bestScore = score
                bestFace = face
            }
        }

        currentFrontFace = bestFace

        // 4) gather stickers that belong to that face only, compute depth score
        var stickers: [(StickerInfo, Float)] = []
        guard let localNormalForFace = faceNormals[bestFace] else { return }

        for cubie in allCubies {
            guard let faceColors = cubie.value(forKey: "faceColors") as? [CubeFace: UIColor],
                  let posValue = cubie.value(forKey: "originalPosition") as? NSValue else { continue }

            if let color = faceColors[bestFace], color != CubeColors.black {
                let normalWorld = cubie.presentation.convertVector(localNormalForFace, to: nil)
                let depthDot = dotProduct(normalWorld, viewVec)
                let note = CubeColors.colorToNote[color] ?? ""
                let sticker = StickerInfo(cubie: cubie, face: bestFace, color: color, note: note, position: posValue.scnVector3Value)
                stickers.append((sticker, depthDot))
            }
        }

        // 5) pick top 16 by visibility and sort into grid top->bottom left->right
        stickers.sort { $0.1 > $1.1 }
        let visible = stickers.map { $0.0 }

        if visible.count >= 16 {
            // camera up/right vectors for sorting
            let camUp = cameraUpVector(camera)
            let camRight = cameraRightVector(camera)
            if camUp == nil || camRight == nil { currentFrontFaceStickers = visible; return }

            let sorted = visible.sorted { a, b in
                let pa = a.cubie.presentation.worldPosition
                let pb = b.cubie.presentation.worldPosition

                let yA = dotProduct(pa, camUp!)
                let yB = dotProduct(pb, camUp!)
                if abs(yA - yB) > 0.01 { return yA > yB }

                let xA = dotProduct(pa, camRight!)
                let xB = dotProduct(pb, camRight!)
                return xA < xB
            }
            currentFrontFaceStickers = sorted
        }

        sequenceIndex = 0
        currentStep = -1
        highlightedStickers.removeAll()
    }

    // MARK: - Camera helpers
    private func cameraRightVector(_ camera: SCNNode) -> SCNVector3? {
        let t = camera.presentation.worldTransform
        return SCNVector3(t.m11, t.m12, t.m13).normalized()
    }

    private func cameraUpVector(_ camera: SCNNode) -> SCNVector3? {
        let t = camera.presentation.worldTransform
        return SCNVector3(t.m21, t.m22, t.m23).normalized()
    }

    private func getNormalForFace(_ face: CubeFace) -> SCNVector3 {
        switch face {
        case .right: return SCNVector3(1, 0, 0)
        case .left: return SCNVector3(-1, 0, 0)
        case .top: return SCNVector3(0, 1, 0)
        case .bottom: return SCNVector3(0, -1, 0)
        case .front: return SCNVector3(0, 0, 1)
        case .back: return SCNVector3(0, 0, -1)
        }
    }

    // MARK: - Interaction / Sequencer
    func handleCubieTap(node: SCNNode) {
        var targetNode = node
        while targetNode.parent != cubeNode && targetNode.parent != nil {
            targetNode = targetNode.parent!
        }

        guard let posValue = targetNode.value(forKey: "originalPosition") as? NSValue else { return }
        let pos = posValue.scnVector3Value

        let stickerId = "x:\(pos.x),y:\(pos.y),z:\(pos.z)_face:front"

        if mutedStickers.contains(stickerId) { mutedStickers.remove(stickerId) }
        else { mutedStickers.insert(stickerId) }

        if isPlaying { startSequencer() }
    }

    func togglePlayback() { if isPlaying { stopSequencer() } else { startSequencer() } }

    func startSequencer() {
        guard !currentFrontFaceStickers.isEmpty else { return }
        stopSequencer()
        let bpmInterval = 60.0 / bpm / 4
        isPlaying = true
        sequenceIndex = 0
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: bpmInterval, repeats: true) { [weak self] _ in self?.playNextNote() }
    }

    private func playNextNote() {
        guard !currentFrontFaceStickers.isEmpty else { return }
        if sequenceIndex >= currentFrontFaceStickers.count { sequenceIndex = 0 }
        currentStep = sequenceIndex
        highlightCurrentSticker()
        let sticker = currentFrontFaceStickers[sequenceIndex]
        if !mutedStickers.contains(sticker.id), !sticker.note.isEmpty { playSound(note: sticker.note) }
        sequenceIndex += 1
    }

    private func highlightCurrentSticker() {
        highlightedStickers.removeAll()
        guard sequenceIndex < currentFrontFaceStickers.count else { return }
        let sticker = currentFrontFaceStickers[sequenceIndex]
        highlightedStickers.insert(sticker.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in self?.highlightedStickers.remove(sticker.id) }
    }

    private func playSound(note: String) {
        guard let player = audioPlayers[note], let buffer = audioBuffers[note] else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }

    func stopSequencer() { sequencerTimer?.invalidate(); sequencerTimer = nil; isPlaying = false; sequenceIndex = 0 }

    private func updateSequencerTempo() { if isPlaying { startSequencer() } }

    func scrambleCube() {
        guard !isAnimating else { return }
        var lastAxis: AxisType?
        let allMoves = Array(CubeMoves.moves.keys)
        for _ in 0..<30 {
            let availableMoves = allMoves.filter { move in
                guard let config = CubeMoves.moves[move] else { return false }
                return config.axis != lastAxis
            }
            if let randomMove = availableMoves.randomElement() {
                rotateFace(randomMove, clockwise: Bool.random())
                lastAxis = CubeMoves.moves[randomMove]?.axis
            }
        }
    }

    func resetCube() {
        stopSequencer()
        isAnimating = false
        rotationQueue.removeAll()
        mutedStickers.removeAll()

        cubeNode?.removeFromParentNode()
        allCubies.removeAll()

        if let sceneView = sceneView {
            let newCube = createCube()
            sceneView.scene?.rootNode.addChildNode(newCube)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.updateFrontFaceStickers() }
        }
    }

    func muteAllStickers(_ shouldMute: Bool) {
        if shouldMute {
            for cubie in allCubies {
                guard let faceColors = cubie.value(forKey: "faceColors") as? [CubeFace: UIColor],
                      let posValue = cubie.value(forKey: "originalPosition") as? NSValue else { continue }
                let pos = posValue.scnVector3Value
                for (face, color) in faceColors {
                    if color != CubeColors.black {
                        let stickerId = "x:\(pos.x),y:\(pos.y),z:\(pos.z)_face:\(face)"
                        mutedStickers.insert(stickerId)
                    }
                }
            }
        } else { mutedStickers.removeAll() }
        if isPlaying { startSequencer() }
    }

    // MARK: - Position updates
    private func updateCubiePositions(_ cubies: [SCNNode], axis: AxisType, angle: Float) {
        let rotationMatrix = SCNMatrix4MakeRotation(angle,
            axis == .x ? 1 : 0,
            axis == .y ? 1 : 0,
            axis == .z ? 1 : 0)

        for cubie in cubies {
            guard let posValue = cubie.value(forKey: "originalPosition") as? NSValue else { continue }
            var pos = posValue.scnVector3Value

            let rotated = SCNVector3(
                pos.x * rotationMatrix.m11 + pos.y * rotationMatrix.m21 + pos.z * rotationMatrix.m31,
                pos.x * rotationMatrix.m12 + pos.y * rotationMatrix.m22 + pos.z * rotationMatrix.m32,
                pos.x * rotationMatrix.m13 + pos.y * rotationMatrix.m23 + pos.z * rotationMatrix.m33
            )

            pos.x = round(rotated.x * 2) / 2
            pos.y = round(rotated.y * 2) / 2
            pos.z = round(rotated.z * 2) / 2

            cubie.setValue(NSValue(scnVector3: pos), forKey: "originalPosition")
        }
    }
}

// MARK: - Helpers & Extensions
extension SCNVector3 {
    func length() -> Float { sqrt(x*x + y*y + z*z) }
    func normalized() -> SCNVector3 { let l = length(); return l > 0 ? SCNVector3(x/l, y/l, z/l) : self }
    func dot(_ other: SCNVector3) -> Float { x*other.x + y*other.y + z*other.z }
    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 { SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z) }
}
