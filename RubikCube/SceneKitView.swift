//
//  SceneKitView.swift
//  RubikCube
//
//  Created by Alan Maizon on 19/11/2025.
//

import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @ObservedObject var viewModel: RubikCubeViewModel
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.backgroundColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        
        // Create scene
        let scene = SCNScene()
        scnView.scene = scene
        
        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 2, z: -8)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(cameraNode)
        
        // Add lights
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = UIColor.white
        ambientLight.light!.intensity = 1000
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .directional
        directionalLight.light!.color = UIColor.white
        directionalLight.light!.intensity = 800
        directionalLight.position = SCNVector3(x: 5, y: 10, z: 7.5)
        directionalLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(directionalLight)
        
        // Create cube
        let cubeNode = viewModel.createCube()
        scene.rootNode.addChildNode(cubeNode)
        viewModel.sceneView = scnView
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // Update front face after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            viewModel.updateFrontFaceStickers()
        }
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Handle updates if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject {
        var viewModel: RubikCubeViewModel
        
        init(viewModel: RubikCubeViewModel) {
            self.viewModel = viewModel
        }
        
        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let scnView = gestureRecognizer.view as? SCNView else { return }
            let location = gestureRecognizer.location(in: scnView)
            
            let hitResults = scnView.hitTest(location, options: [:])
            if let hit = hitResults.first {
                viewModel.handleCubieTap(node: hit.node)
            }
        }
    }
}
