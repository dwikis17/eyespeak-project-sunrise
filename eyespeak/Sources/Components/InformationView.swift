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
            gestureSequenceSection
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
    
    private var gestureSequenceSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .frame(height: 200)
            
            VStack(spacing: 16) {
                // Current gesture sequence
                if viewModel.isGestureMode {
                    VStack(spacing: 8) {
                        Text("Gesture Sequence")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if viewModel.gestureInputManager.gestureSequence.isEmpty {
                            Text("No gestures detected")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        } else {
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.gestureInputManager.gestureSequence.enumerated()), id: \.offset) { index, gesture in
                                    HStack(spacing: 4) {
                                        if index > 0 {
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: gesture.iconName)
                                            Text(gesture.rawValue)
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Default display when not in gesture mode
                    VStack(spacing: 16) {
                        Text("Gesture Mode")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 40) {
                            Image(systemName: "arrow.up")
                            Image(systemName: "arrow.up")
                        }
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.blue.opacity(0.3))
                    }
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
