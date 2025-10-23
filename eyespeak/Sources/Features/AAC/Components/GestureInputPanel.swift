//
//  GestureInputPanel.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import SwiftUI

struct GestureInputPanel: View {
    @Bindable var gestureManager: GestureInputManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Current sequence display
            HStack(spacing: 8) {
                Text("Sequence:")
                    .font(.headline)
                
                if gestureManager.gestureSequence.isEmpty {
                    Text("None")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(gestureManager.gestureSequence.enumerated()), id: \.offset) { index, gesture in
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    gestureManager.reset()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            // Gesture control pad
            VStack(spacing: 12) {
                // Top row: Look Up
                Button {
                    gestureManager.registerGesture(.lookUp)
                } label: {
                    GestureButton(
                        icon: "arrow.up",
                        label: "Look Up",
                        gesture: .lookUp
                    )
                }
                
                // Middle row: Look Left, Blink, Look Right
                HStack(spacing: 12) {
                    Button {
                        gestureManager.registerGesture(.lookLeft)
                    } label: {
                        GestureButton(
                            icon: "arrow.left",
                            label: "Look Left",
                            gesture: .lookLeft
                        )
                    }
                    
                    Button {
                        gestureManager.registerGesture(.blink)
                    } label: {
                        GestureButton(
                            icon: "eye",
                            label: "Blink",
                            gesture: .blink
                        )
                    }
                    
                    Button {
                        gestureManager.registerGesture(.lookRight)
                    } label: {
                        GestureButton(
                            icon: "arrow.right",
                            label: "Look Right",
                            gesture: .lookRight
                        )
                    }
                }
                
                // Bottom row: Look Down
                Button {
                    gestureManager.registerGesture(.lookDown)
                } label: {
                    GestureButton(
                        icon: "arrow.down",
                        label: "Look Down",
                        gesture: .lookDown
                    )
                }
                
                // Wink controls
                HStack(spacing: 12) {
                    Button {
                        gestureManager.registerGesture(.winkLeft)
                    } label: {
                        GestureButton(
                            icon: "eye.slash",
                            label: "Wink Left",
                            gesture: .winkLeft
                        )
                    }
                    
                    Button {
                        gestureManager.registerGesture(.winkRight)
                    } label: {
                        GestureButton(
                            icon: "eye.slash.fill",
                            label: "Wink Right",
                            gesture: .winkRight
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Gesture Button Component

struct GestureButton: View {
    let icon: String
    let label: String
    let gesture: GestureType
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    GestureInputPanel(gestureManager: GestureInputManager())
}
