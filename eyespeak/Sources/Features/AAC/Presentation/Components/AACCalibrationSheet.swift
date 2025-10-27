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
    @State private var capturePhase: CapturePhase = .edge

    private enum CapturePhase {
        case edge
        case offScreen
    }

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

        var requiresDirectionalCapture: Bool {
            self != .neutral
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(step.title)
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(instruction(for: step))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if step.requiresDirectionalCapture {
                        phaseIndicator
                            .padding(.top, 6)
                    }
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
                    Text(captureButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(step.requiresDirectionalCapture && capturePhase == .offScreen && edgeValue(for: step) == nil)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Captured Positions")
                        .font(.headline)
                ForEach(Step.allCases) { entry in
                    Button {
                        step = entry
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: isStepComplete(entry) ? "checkmark.circle.fill" : "circle.dashed")
                                    .foregroundStyle(isStepComplete(entry) ? .green : .secondary)
                                Text(entry.title)
                                Spacer()
                                if entry.requiresDirectionalCapture {
                                    Text(phaseSummary(for: entry))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if entry.requiresDirectionalCapture {
                                directionalSummaryRows(for: entry)
                            } else {
                                Text(summary(for: entry))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
            resetCapturePhase(for: step)
        }
        .onChange(of: step) { newValue in
            resetCapturePhase(for: newValue)
        }
    }

    private var hasAnyCalibration: Bool {
        status.neutralYaw != nil ||
        status.neutralPitch != nil ||
        status.neutralLeftBlink != nil ||
        status.neutralRightBlink != nil ||
        status.neutralEyeYaw != nil ||
        status.neutralEyePitch != nil ||
        status.leftEyeYawEdge != nil ||
        status.leftEyeYawOuter != nil ||
        status.rightEyeYawEdge != nil ||
        status.rightEyeYawOuter != nil ||
        status.upEyePitchEdge != nil ||
        status.upEyePitchOuter != nil ||
        status.downEyePitchEdge != nil ||
        status.downEyePitchOuter != nil
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
            advanceStepIfNeeded()
        case .lookLeft, .lookRight, .lookUp, .lookDown:
            handleDirectionalCapture(for: step)
        }
    }

    private func handleDirectionalCapture(for step: Step) {
        switch capturePhase {
        case .edge:
            setEdgeValue(measurementValue(for: step), for: step)
            clearOuterValue(for: step)
            capturePhase = .offScreen
        case .offScreen:
            setOuterValue(measurementValue(for: step), for: step)
            capturePhase = .edge
            advanceStepIfNeeded()
        }
    }

    private func advanceStepIfNeeded() {
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
        case .lookLeft, .lookRight, .lookUp, .lookDown:
            return edgeValue(for: step) != nil && outerValue(for: step) != nil
        }
    }

    private func summary(for step: Step) -> String {
        switch step {
        case .neutral:
            if let yaw = status.neutralEyeYaw, let pitch = status.neutralEyePitch {
                return String(format: "yaw %.1f°, pitch %.1f°", yaw, pitch)
            }
        case .lookLeft, .lookRight, .lookUp, .lookDown:
            return phaseSummary(for: step)
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
        status.leftEyeYawEdge = nil
        status.leftEyeYawOuter = nil
        status.rightEyeYawEdge = nil
        status.rightEyeYawOuter = nil
        status.upEyePitchEdge = nil
        status.upEyePitchOuter = nil
        status.downEyePitchEdge = nil
        status.downEyePitchOuter = nil
        step = .neutral
        capturePhase = .edge
    }

    private func instruction(for step: Step) -> String {
        switch step {
        case .neutral:
            return "Hold the device at eye level. Relax your face, keep both eyes naturally open, and stare straight ahead."
        case .lookLeft:
            return capturePhase == .edge
            ? "Focus your gaze on the left edge of the screen without moving your head."
            : "Shift your gaze slightly past the left bezel until the screen leaves your view."
        case .lookRight:
            return capturePhase == .edge
            ? "Focus on the right edge of the screen while keeping your head still."
            : "Move your gaze just beyond the right bezel so the display leaves your peripheral vision."
        case .lookUp:
            return capturePhase == .edge
            ? "Look at the top edge of the screen, keeping your head steady."
            : "Lift your gaze slightly above the screen so you are looking past the top bezel."
        case .lookDown:
            return capturePhase == .edge
            ? "Look at the bottom edge of the screen while keeping your head steady."
            : "Drop your gaze just below the device so you are looking past the bottom bezel."
        }
    }

    private var captureButtonTitle: String {
        switch step {
        case .neutral:
            return "Capture Center"
        default:
            return capturePhase == .edge ? "Capture Screen Edge" : "Capture Off-Screen"
        }
    }

    private var phaseIndicator: some View {
        HStack(spacing: 12) {
            Label {
                Text(capturePhase == .edge ? "Edge (on-screen)" : "Off-screen")
            } icon: {
                Image(systemName: capturePhase == .edge ? "rectangle" : "arrow.uturn.forward")
            }
            .font(.caption)
            .padding(6)
            .background(Color.blue.opacity(0.12))
            .foregroundColor(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            if capturePhase == .offScreen, let currentEdge = edgeValue(for: step) {
                Text(String(format: "Edge %.1f°", currentEdge))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func resetCapturePhase(for step: Step) {
        guard step.requiresDirectionalCapture else {
            capturePhase = .edge
            return
        }
        if edgeValue(for: step) == nil {
            capturePhase = .edge
        } else if outerValue(for: step) == nil {
            capturePhase = .offScreen
        } else {
            capturePhase = .edge
        }
    }

    private func measurementValue(for step: Step) -> Double {
        switch step {
        case .neutral:
            return 0
        case .lookLeft, .lookRight:
            return status.eyeYawDegrees
        case .lookUp, .lookDown:
            return status.eyePitchDegrees
        }
    }

    private func edgeValue(for step: Step) -> Double? {
        switch step {
        case .neutral: return nil
        case .lookLeft: return status.leftEyeYawEdge
        case .lookRight: return status.rightEyeYawEdge
        case .lookUp: return status.upEyePitchEdge
        case .lookDown: return status.downEyePitchEdge
        }
    }

    private func outerValue(for step: Step) -> Double? {
        switch step {
        case .neutral: return nil
        case .lookLeft: return status.leftEyeYawOuter
        case .lookRight: return status.rightEyeYawOuter
        case .lookUp: return status.upEyePitchOuter
        case .lookDown: return status.downEyePitchOuter
        }
    }

    private func setEdgeValue(_ value: Double, for step: Step) {
        switch step {
        case .neutral: break
        case .lookLeft: status.leftEyeYawEdge = value
        case .lookRight: status.rightEyeYawEdge = value
        case .lookUp: status.upEyePitchEdge = value
        case .lookDown: status.downEyePitchEdge = value
        }
    }

    private func setOuterValue(_ value: Double, for step: Step) {
        switch step {
        case .neutral: break
        case .lookLeft: status.leftEyeYawOuter = value
        case .lookRight: status.rightEyeYawOuter = value
        case .lookUp: status.upEyePitchOuter = value
        case .lookDown: status.downEyePitchOuter = value
        }
    }

    private func clearOuterValue(for step: Step) {
        switch step {
        case .neutral: break
        case .lookLeft: status.leftEyeYawOuter = nil
        case .lookRight: status.rightEyeYawOuter = nil
        case .lookUp: status.upEyePitchOuter = nil
        case .lookDown: status.downEyePitchOuter = nil
        }
    }

    private func formatEdgeOuter(edge: Double?, outer: Double?) -> String {
        let edgeString = edge.map { String(format: "edge %.1f°", $0) } ?? "edge —"
        let outerString = outer.map { String(format: "off %.1f°", $0) } ?? "off —"
        return "\(edgeString), \(outerString)"
    }

    private func phaseSummary(for step: Step) -> String {
        let edge = edgeValue(for: step)
        let outer = outerValue(for: step)
        let completed = (edge != nil ? 1 : 0) + (outer != nil ? 1 : 0)
        return "\(completed)/2 complete"
    }

    @ViewBuilder
    private func directionalSummaryRows(for step: Step) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Edge")
                    .font(.caption2.weight(.semibold))
                Spacer()
                if let edge = edgeValue(for: step) {
                    Text(String(format: "%.1f°", edge))
                        .font(.caption2)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            HStack {
                Text("Off-screen")
                    .font(.caption2.weight(.semibold))
                Spacer()
                if let outer = outerValue(for: step) {
                    Text(String(format: "%.1f°", outer))
                        .font(.caption2)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .foregroundStyle(.secondary)
    }
}
