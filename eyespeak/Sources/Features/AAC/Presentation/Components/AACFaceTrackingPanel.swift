//
//  AACFaceTrackingPanel.swift
//  eyespeak
//
//  Lightweight overlay that embeds the face tracking camera inside the AAC experience.
//

import ARKit
import SwiftUI

struct AACFaceTrackingPanel: View {
    @EnvironmentObject private var viewModel: AACViewModel

    var body: some View {
        let statusBinding = Binding<FaceStatus>(
            get: { viewModel.faceStatus },
            set: { viewModel.faceStatus = $0 }
        )
        let calibratingBinding = Binding<Bool>(
            get: { viewModel.isCalibrating },
            set: { viewModel.isCalibrating = $0 }
        )

        VStack(alignment: .leading, spacing: 0) {
            trackingPreview(statusBinding: statusBinding)
            //            statusSummary statusSummary
        }
        .fullScreenCover(
            isPresented: calibratingBinding,
            onDismiss: viewModel.endCalibration
        ) {
            AACFullScreenCalibrationView(
                status: statusBinding,
                isPresented: calibratingBinding
            )
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func trackingPreview(statusBinding: Binding<FaceStatus>)
        -> some View
    {
        Group {
            if ARFaceTrackingConfiguration.isSupported {
                ZStack(alignment: .topLeading) {
                    AACFaceTrackingView(
                        status: statusBinding,
                        onGesture: { viewModel.handleDetectedGesture($0) },
                        onEyesClosed: {
                            viewModel.toggleCalibration()
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    previewHeader
                        .padding(4)
                }

                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "faceid")
                        .font(.largeTitle)
                    Text(
                        "Face tracking requires a device with a TrueDepth camera."
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    
    }

    private var previewHeader: some View {
        HStack {
            Label(
                viewModel.faceStatus.isCalibrated
                    ? "Calibrated" : "Not Calibrated",
                systemImage: viewModel.faceStatus.isCalibrated
                    ? "checkmark.seal.fill" : "exclamationmark.triangle"
            )
            .font(.caption)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            Spacer()
        }
    }

    private var statusSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Direction", systemImage: "eyes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.faceStatus.direction.rawValue)
                    .font(.headline)
                Text(
                    String(
                        format: "%.0f%%",
                        viewModel.faceStatus.gazeActivation * 100
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Label("Last Gesture", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let gesture = viewModel.gestureInputManager.lastGesture {
                    HStack(spacing: 6) {
                        Image(systemName: gesture.iconName)
                        Text(gesture.rawValue)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                } else {
                    Text("Waiting…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label("Mouth", systemImage: "face.smiling")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.faceStatus.mouthOpen ? "Open" : "Closed")
                    .font(.subheadline)
                Text(
                    String(
                        format: "%.0f%%",
                        viewModel.faceStatus.jawOpenValue * 100
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                Label("Eyebrows", systemImage: "face.smiling.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.faceStatus.eyebrowsRaised ? "Raised" : "Neutral")
                    .font(.subheadline)
                Text(
                    String(
                        format: "%.0f%%",
                        viewModel.faceStatus.browRaiseValue * 100
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                Label("Smile", systemImage: "face.smiling")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.faceStatus.isSmiling ? "Smiling" : "Neutral")
                    .font(.subheadline)
                Text(
                    String(
                        format: "%.0f%%",
                        viewModel.faceStatus.smileValue * 100
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                Label("Lip Pucker", systemImage: "lips")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Left")
                        Text(
                            viewModel.faceStatus.lipsPuckeredLeft
                                ? "Puckered" : "Neutral"
                        )
                        Text(
                            String(
                                format: "%.0f%%",
                                viewModel.faceStatus.lipPuckerLeftValue * 100
                            )
                        )
                    }
                    .font(.caption)

                    HStack {
                        Text("Right")
                        Text(
                            viewModel.faceStatus.lipsPuckeredRight
                                ? "Puckered" : "Neutral"
                        )
                        Text(
                            String(
                                format: "%.0f%%",
                                viewModel.faceStatus.lipPuckerRightValue * 100
                            )
                        )
                    }
                    .font(.caption)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label(
                    "Active Sequence",
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if viewModel.gestureInputManager.gestureSequence.isEmpty {
                    Text("No gestures detected yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(
                                Array(
                                    viewModel.gestureInputManager
                                        .gestureSequence.enumerated()
                                ),
                                id: \.offset
                            ) { _, gesture in
                                HStack(spacing: 4) {
                                    Image(systemName: gesture.iconName)
                                    Text(gesture.rawValue)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Calibrate button moved to InformationView
}
