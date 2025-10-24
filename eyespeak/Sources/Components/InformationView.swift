//
//  InformationView.swift
//  eyespeak
//
//  Created by Dwiki on 22/10/25.
//

import SwiftUI

struct InformationView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            currentInputSection
            if viewModel.isGestureMode {
                AACFaceTrackingPanel()
            } else {
                gestureModePlaceholder
            }
        }
    }
    
    private var currentInputSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .frame(height: 60)
            HStack {
                Text("CURRENT INPUT")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: viewModel.isGestureMode ? "eye.fill" : "eye")
                    .foregroundStyle(viewModel.isGestureMode ? .green : .red)
            }
            .padding()
        }
    }
    
    private var gestureModePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .frame(height: 200)
            
            VStack(spacing: 16) {
                Text("Gesture Mode")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Text("Turn on gesture mode to control the grid with your eyes.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 40) {
                        Image(systemName: "arrow.left")
                        Image(systemName: "eye")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.blue.opacity(0.3))
                }
            }
            .padding()
        }
    }
}


#Preview {
    InformationView()
        .environmentObject(AACDIContainer.shared.makeAACViewModel())
        .frame(width: 300)
}
