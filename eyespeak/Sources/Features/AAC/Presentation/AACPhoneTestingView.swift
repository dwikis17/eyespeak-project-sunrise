//
//  AACPhoneTestingView.swift
//  eyespeak
//
//  Created for on-device testing of the AAC face tracking pipeline on iPhone.
//  Presents the live AR feed, calibration controls, combo status, and a compact grid.
//

import SwiftData
import SwiftUI

struct AACPhoneTestingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AACViewModel
    
    init(container: AACDIContainer = AACDIContainer.shared) {
        _viewModel = StateObject(wrappedValue: container.makeAACViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    trackingPanel
                    gestureControls
                    comboSection
                    gridSection
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Eye Tracking Lab")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSettings()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .environmentObject(viewModel)
        .onAppear {
            viewModel.setupManagers()
        }
    }
    
    // MARK: - Sections
    
    private var trackingPanel: some View {
        AACFaceTrackingPanel()
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var gestureControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gesture Input")
                .font(.headline)
            
            Text("Use gesture mode to map eye combos to grid cards. Calibration is available while gesture mode is active.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button {
                    viewModel.toggleGestureMode()
                } label: {
                    Label(viewModel.isGestureMode ? "Stop Gesture Mode" : "Start Gesture Mode",
                          systemImage: viewModel.isGestureMode ? "pause.circle.fill" : "play.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isGestureMode ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundColor(viewModel.isGestureMode ? .red : .blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            
            if viewModel.isGestureMode {
                Button {
                    if viewModel.isCalibrating {
                        viewModel.endCalibration()
                    } else {
                        viewModel.beginCalibration()
                    }
                } label: {
                    Label(viewModel.isCalibrating ? "Calibrating…" : "Calibrate",
                          systemImage: "camera.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private var comboSection: some View {
        let combos = viewModel.positions
            .compactMap { position -> (GridPosition, ActionCombo)? in
                guard let combo = position.actionCombo else { return nil }
                return (position, combo)
            }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Combo Assignments")
                    .font(.headline)
                Spacer()
                Text("\(combos.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if combos.isEmpty {
                Text("Assign combos to grid positions to trigger cards with eye gestures.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(combos, id: \.0.id) { pair in
                    let position = pair.0
                    let combo = pair.1
                    HStack(spacing: 12) {
                        Text("#\(position.order + 1)")
                            .font(.footnote.monospacedDigit())
                            .padding(6)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(combo.name)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 6) {
                                Image(systemName: combo.firstGesture.iconName)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                Image(systemName: combo.secondGesture.iconName)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        if let card = position.card {
                            Text(card.title)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grid Preview")
                .font(.headline)
            
            Text(viewModel.isGestureMode ?
                 "Tap a card to play it manually or use gaze combos to trigger highlights."
                 : "Enable gesture mode to drive the board with your eyes. You can still tap cards to play them.")
           .font(.footnote)
           .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Mouth", systemImage: "face.smiling")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.faceStatus.mouthOpen ? "Open" : "Closed")
                        .font(.subheadline)
                    Text(String(format: "Jaw %.0f%%", viewModel.faceStatus.jawOpenValue * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Label("Eyebrows", systemImage: "face.smiling.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.faceStatus.eyebrowsRaised ? "Raised" : "Neutral")
                        .font(.subheadline)
                    Text(String(format: "Brow %.0f%%", viewModel.faceStatus.browRaiseValue * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Smile", systemImage: "face.smiling")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.faceStatus.isSmiling ? "Smiling" : "Neutral")
                        .font(.subheadline)
                    Text(String(format: "Smile %.0f%%", viewModel.faceStatus.smileValue * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Label("Lip Pucker", systemImage: "lips")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("L:")
                        Text(viewModel.faceStatus.lipsPuckeredLeft ? "Puckered" : "Neutral")
                        Text(String(format: "%.0f%%", viewModel.faceStatus.lipPuckerLeftValue * 100))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    HStack {
                        Text("R:")
                        Text(viewModel.faceStatus.lipsPuckeredRight ? "Puckered" : "Neutral")
                        Text(String(format: "%.0f%%", viewModel.faceStatus.lipPuckerRightValue * 100))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: phoneColumnCount),
                spacing: 12
            ) {
                ForEach(viewModel.positions) { position in
                    CardCell(
                        position: position,
                        dataManager: viewModel.dataManagerInstance,
                        columns: phoneColumnCount,
                        isHighlighted: viewModel.selectedPosition?.id == position.id,
                        viewModel: viewModel
                    )
                    .frame(height: 140)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private var phoneColumnCount: Int {
        min(max(viewModel.columns, 2), 3)
    }
}

#Preview {
    let container = AACDIContainer.makePreviewContainer()
    return AACPhoneTestingView(container: AACDIContainer.shared)
        .modelContainer(container)
}
