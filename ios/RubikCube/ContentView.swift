//
//  ContentView.swift
//  RubikCube
//
//  Created by Alan Maizon on 19/11/2025.
//

import SwiftUI
import SceneKit

struct ContentView: View {
    @StateObject private var cubeViewModel = RubikCubeViewModel()
    
    var body: some View {
        ZStack {
            // Fullscreen 3D scene
            SceneKitView(viewModel: cubeViewModel)
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geo in
                
                // ---------------------------------------------------------
                // TOP ROW BUTTONS (R1–R4)
                // ---------------------------------------------------------
                VStack {
                    HStack(spacing: 12) {
                        Spacer(minLength: 40)
                        
                        ForEach(0..<4) { idx in
                            FaceSliceButton(label: "R\(idx+1)") {
                                cubeViewModel.rotateRow(idx, clockwise: true)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                }
                
                // ---------------------------------------------------------
                // RIGHT COLUMN BUTTONS (C1–C4)
                // ---------------------------------------------------------
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ForEach(0..<4) { idx in
                                FaceSliceButton(label: "C\(idx+1)") {
                                    cubeViewModel.rotateColumn(idx, clockwise: true)
                                }
                            }
                        }
                        .padding(.trailing, 14)
                    }
                    Spacer()
                }
                
                // ---------------------------------------------------------
                // LEFT AISLE BUTTONS (A1–A4)
                // ---------------------------------------------------------
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        VStack(spacing: 12) {
                            ForEach(0..<4) { idx in
                                FaceSliceButton(label: "A\(idx+1)") {
                                    cubeViewModel.rotateAisle(idx, clockwise: true)
                                }
                            }
                        }
                        .padding(.leading, 14)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .allowsHitTesting(true)
            
            
            // ---------------------------------------------------------
            // BOTTOM MAIN CONTROLS (play, random, reset)
            // ---------------------------------------------------------
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    ControlButton(
                        system: cubeViewModel.isPlaying ? "stop.fill" : "play.fill",
                        color: .blue
                    ) { cubeViewModel.togglePlayback() }
                    
                    ControlButton(system: "shuffle", color: .orange) {
                        cubeViewModel.scrambleCube()
                    }
                    
                    ControlButton(system: "arrow.clockwise", color: .red) {
                        cubeViewModel.resetCube()
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}


// MARK: - Small Controls

struct ControlButton: View {
    let system: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
        }
    }
}


/// Small universal slice button
struct FaceSliceButton: View {
    let label: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption2).bold()
                .foregroundColor(.white)
                .frame(width: 42, height: 36)
                .background(Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
