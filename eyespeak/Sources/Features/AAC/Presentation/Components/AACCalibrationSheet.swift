//
//  AACCalibrationSheet.swift
//  eyespeak
//
//  Shared calibration flow for eye tracking, extracted from ARKitFaceTestView so the
//  production AAC experience can reuse the same steps.
//

import SwiftUI

struct AACCalibrationSheet: View {
    @Binding var status: FaceStatus
    @Binding var isPresented: Bool
    @State private var step: Step = .neutral

    private enum Step: Int, CaseIterable, Identifiable {
        case neutral, lookLeft, lookRight, lookUp, lookDown

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .neutral: "Find Center"
            case .lookLeft: "Look Left"
            case .lookRight: "Look Right"
            case .lookUp: "Look Up"
            case .lookDown: "Look Down"
            }
        }

        var instruction: String {
            switch self {
            case .neutral:
                return "Hold the device at eye level. Relax your face, keep both eyes naturally open, and stare straight ahead."
            case .lookLeft:
                return "Shift your gaze just past the left edge of the screen without moving your head."
            case .lookRight:
                return "Shift your gaze just past the right edge of the screen without moving your head."
            case .lookUp:
                return "Lift your gaze just above the top edge of the screen."
            case .lookDown:
                return "Drop your gaze just below the bottom edge of the screen."
            }
        }

        var buttonTitle: String {
            switch self {
            case .lookDown: "Capture Down"
            case .neutral: "Capture Center"
            case .lookLeft: "Capture Left"
            case .lookRight: "Capture Right"
            case .lookUp: "Capture Up"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(step.title)
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(step.instruction)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Readings")
                        .font(.headline)
                    Text(String(format: "Gaze Yaw: %.2f°  Pitch: %.2f°", status.eyeYawDegrees, status.eyePitchDegrees))
                    Text(String(format: "Head Yaw: %.2f°  Pitch: %.2f°", status.yawDegrees, status.pitchDegrees))
                    Text(String(format: "Left Blink: %.2f  Right Blink: %.2f", status.leftBlinkValue, status.rightBlinkValue))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: captureCurrent) {
                    Text(step.buttonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Captured Positions")
                        .font(.headline)
                    ForEach(Step.allCases) { entry in
                        Button {
                            step = entry
                        } label: {
                            HStack {
                                Image(systemName: isStepComplete(entry) ? "checkmark.circle.fill" : "circle.dashed")
                                    .foregroundStyle(isStepComplete(entry) ? .green : .secondary)
                                Text(entry.title)
                                Spacer()
                                Text(summary(for: entry))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if status.isCalibrated {
                    Button {
                        isPresented = false
                    } label: {
                        Text("Finish Calibration")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if hasAnyCalibration {
                    Button(role: .destructive, action: resetCalibration) {
                        Text("Reset All Calibration")
                            .frame(maxWidth: .infinity)
                    }
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if hasAnyCalibration {
                        Button("Reset", role: .destructive, action: resetCalibration)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .onAppear {
            step = firstIncompleteStep() ?? .lookDown
        }
    }

    private var hasAnyCalibration: Bool {
        status.neutralYaw != nil ||
        status.neutralPitch != nil ||
        status.neutralLeftBlink != nil ||
        status.neutralRightBlink != nil ||
        status.neutralEyeYaw != nil ||
        status.neutralEyePitch != nil ||
        status.leftEyeYaw != nil ||
        status.rightEyeYaw != nil ||
        status.upEyePitch != nil ||
        status.downEyePitch != nil
    }

    private func captureCurrent() {
        if step != .neutral && !isStepComplete(.neutral) {
            step = .neutral
            return
        }

        switch step {
        case .neutral:
            status.neutralYaw = status.yawDegrees
            status.neutralPitch = status.pitchDegrees
            status.neutralLeftBlink = status.leftBlinkValue
            status.neutralRightBlink = status.rightBlinkValue
            status.neutralEyeYaw = status.eyeYawDegrees
            status.neutralEyePitch = status.eyePitchDegrees
        case .lookLeft:
            status.leftEyeYaw = status.eyeYawDegrees
        case .lookRight:
            status.rightEyeYaw = status.eyeYawDegrees
        case .lookUp:
            status.upEyePitch = status.eyePitchDegrees
        case .lookDown:
            status.downEyePitch = status.eyePitchDegrees
        }

        if let next = firstIncompleteStep() {
            step = next
        } else {
            step = .lookDown
        }
    }

    private func isStepComplete(_ step: Step) -> Bool {
        switch step {
        case .neutral:
            return status.neutralEyeYaw != nil && status.neutralEyePitch != nil
        case .lookLeft:
            return status.leftEyeYaw != nil
        case .lookRight:
            return status.rightEyeYaw != nil
        case .lookUp:
            return status.upEyePitch != nil
        case .lookDown:
            return status.downEyePitch != nil
        }
    }

    private func summary(for step: Step) -> String {
        switch step {
        case .neutral:
            if let yaw = status.neutralEyeYaw, let pitch = status.neutralEyePitch {
                return String(format: "yaw %.1f°, pitch %.1f°", yaw, pitch)
            }
        case .lookLeft:
            if let value = status.leftEyeYaw {
                return String(format: "%.1f°", value)
            }
        case .lookRight:
            if let value = status.rightEyeYaw {
                return String(format: "%.1f°", value)
            }
        case .lookUp:
            if let value = status.upEyePitch {
                return String(format: "%.1f°", value)
            }
        case .lookDown:
            if let value = status.downEyePitch {
                return String(format: "%.1f°", value)
            }
        }
        return "Not captured"
    }

    private func firstIncompleteStep() -> Step? {
        Step.allCases.first { !isStepComplete($0) }
    }

    private func resetCalibration() {
        status.neutralYaw = nil
        status.neutralPitch = nil
        status.neutralLeftBlink = nil
        status.neutralRightBlink = nil
        status.neutralEyeYaw = nil
        status.neutralEyePitch = nil
        status.leftEyeYaw = nil
        status.rightEyeYaw = nil
        status.upEyePitch = nil
        status.downEyePitch = nil
        step = .neutral
    }
}
