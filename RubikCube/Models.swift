//
//  Models.swift
//  RubikCube
//
//  Created by Alan Maizon on 19/11/2025.
//

import SwiftUI
import SceneKit

// MARK: - Enums
enum CubeFace: String {
    case front
    case right
    case back
    case left
    case top
    case bottom

    var materialIndex: Int {
        switch self {
        case .front:  return 0
        case .right:  return 1
        case .back:   return 2
        case .left:   return 3
        case .top:    return 4
        case .bottom: return 5
        }
    }
}

enum AxisType {
    case x, y, z
}

// MARK: - Cube Colors
struct CubeColors {
    static let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static let red = UIColor(red: 0.72, green: 0.07, blue: 0.20, alpha: 1.0)
    static let yellow = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
    static let orange = UIColor(red: 1.0, green: 0.35, blue: 0.0, alpha: 1.0)
    static let green = UIColor(red: 0.0, green: 0.61, blue: 0.28, alpha: 1.0)
    static let blue = UIColor(red: 0.0, green: 0.27, blue: 0.68, alpha: 1.0)
    static let black = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    static let colorToNote: [UIColor: String] = [
        white: "C4",
        red: "D4",
        blue: "E4",
        orange: "G4",
        green: "A4",
        yellow: "C5"
    ]
}

// MARK: - Cube Moves Configuration
struct MoveConfig {
    let axis: AxisType
    let layers: [Float]
    let sign: Float
}

struct CubeMoves {
    static let moves: [String: MoveConfig] = [
        "U": MoveConfig(axis: .y, layers: [1.5], sign: -1),
        "u": MoveConfig(axis: .y, layers: [0.5], sign: -1),
        "Uw": MoveConfig(axis: .y, layers: [1.5, 0.5], sign: 1),
        "Uw'": MoveConfig(axis: .y, layers: [1.5, 0.5], sign: -1),
        "D": MoveConfig(axis: .y, layers: [-1.5], sign: 1),
        "d": MoveConfig(axis: .y, layers: [-0.5], sign: 1),
        "Dw": MoveConfig(axis: .y, layers: [-1.5, -0.5], sign: -1),
        "Dw'": MoveConfig(axis: .y, layers: [-1.5, -0.5], sign: 1),
        "L": MoveConfig(axis: .x, layers: [-1.5], sign: 1),
        "l": MoveConfig(axis: .x, layers: [-0.5], sign: 1),
        "R": MoveConfig(axis: .x, layers: [1.5], sign: -1),
        "r": MoveConfig(axis: .x, layers: [0.5], sign: -1),
        "F": MoveConfig(axis: .z, layers: [1.5], sign: -1),
        "f": MoveConfig(axis: .z, layers: [0.5], sign: -1),
        "B": MoveConfig(axis: .z, layers: [-1.5], sign: 1),
        "b": MoveConfig(axis: .z, layers: [-0.5], sign: 1)
    ]
}

// MARK: - Sticker Info
struct StickerInfo: Identifiable {
    let id: String
    
    let cubie: SCNNode
    let face: CubeFace
    let color: UIColor
    let note: String
    let position: SCNVector3
    let materialIndex: Int
    
    init(cubie: SCNNode, face: CubeFace, color: UIColor, note: String, position: SCNVector3) {
        self.id = "x:\(position.x),y:\(position.y),z:\(position.z)_face:\(face.rawValue)"
        self.cubie = cubie
        self.face = face
        self.color = color
        self.note = note
        self.position = position
        self.materialIndex = face.materialIndex
    }
}

// MARK: - Helper Functions
func dotProduct(_ a: SCNVector3, _ b: SCNVector3) -> Float {
    return a.x * b.x + a.y * b.y + a.z * b.z
}

extension SCNVector3 {
    subscript(axis: AxisType) -> Float {
        get {
            switch axis {
            case .x: return self.x
            case .y: return self.y
            case .z: return self.z
            }
        }
    }
}
