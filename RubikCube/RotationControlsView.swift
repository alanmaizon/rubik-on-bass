//  RotationControlsView.swift
//  RubikCube
//
//  Created by Alan Maizon on 22/11/2025.
//

import SwiftUI

struct RotationControlsView: View {
    @ObservedObject var viewModel: RubikCubeViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Rotate Faces")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                Button(action: { viewModel.rotateFace("U", clockwise: true) }) {
                    Image(systemName: "arrow.up.circle")
                        .font(.title)
                }
                Button(action: { viewModel.rotateFace("D", clockwise: true) }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.title)
                }
            }
            HStack(spacing: 12) {
                Button(action: { viewModel.rotateFace("L", clockwise: true) }) {
                    Image(systemName: "arrow.left.circle")
                        .font(.title)
                }
                Button(action: { viewModel.rotateFace("R", clockwise: true) }) {
                    Image(systemName: "arrow.right.circle")
                        .font(.title)
                }
            }
            HStack(spacing: 12) {
                Button(action: { viewModel.rotateFace("F", clockwise: true) }) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.title)
                }
                Button(action: { viewModel.rotateFace("B", clockwise: true) }) {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .font(.title)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

#Preview {
    RotationControlsView(viewModel: RubikCubeViewModel())
        .padding()
        .background(Color.gray)
}
