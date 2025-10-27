//
//  AACView.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import SwiftData
import SwiftUI
import ARKit
import SceneKit

struct AACView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AACViewModel
    @State private var faceStatus = FaceStatus()
    @State private var showDebugOverlay = true
    @State private var isCalibrating = false
    
    init(container: AACDIContainer = AACDIContainer.shared) {
        _viewModel = StateObject(wrappedValue: container.makeAACViewModel())
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack {
                    InformationView()
                        .frame(width: geo.size.width * 0.2)
                    Spacer()
                    CardGridView()
                        .frame(width: geo.size.width * 0.7)
                }
                .padding()
            }

            // Hidden ARKit face tracking layer used to feed gestures
            if viewModel.isGestureMode {
                AACFaceTrackingView(
                    status: $faceStatus,
                    isActive: viewModel.isGestureMode
                ) { gesture in
                    viewModel.registerDetectedGesture(gesture)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .opacity(0.001)
            }

            // Quick on-screen debug overlay
            if viewModel.isGestureMode && showDebugOverlay {
                AACDebugOverlay(status: faceStatus) {
                    showDebugOverlay = false
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding()
                .transition(.opacity)
            }

            // Calibration status + action chip (top-left)
            if viewModel.isGestureMode {
                HStack(spacing: 8) {
                    Label(faceStatus.isCalibrated ? "Calibrated" : "Not Calibrated",
                          systemImage: faceStatus.isCalibrated ? "checkmark.seal.fill" : "exclamationmark.triangle")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button(faceStatus.isCalibrated ? "Recalibrate" : "Calibrate") {
                        isCalibrating = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            }
        }
        // 👇 inject into environment so child views can use @EnvironmentObject
        .environmentObject(viewModel)
        .sheet(isPresented: $isCalibrating) {
            AACCalibrationSheet(status: $faceStatus, isCalibrating: $isCalibrating)
        }
    }
}


#Preview {
    let container = AACDIContainer.makePreviewContainer()
    return AACView(container: AACDIContainer.shared)
        .modelContainer(container)
}

// MARK: - ARKit Face Tracking (hidden capture layer)
private struct AACFaceTrackingView: UIViewRepresentable {
    @Binding var status: FaceStatus
    var isActive: Bool
    var onGesture: (GestureType) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(status: $status, onGesture: onGesture)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.session.delegate = context.coordinator
        view.delegate = context.coordinator
        view.scene = SCNScene()
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        context.coordinator.onGesture = onGesture
        if isActive {
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = true
            uiView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        } else {
            uiView.session.pause()
        }
    }

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        @Binding var status: FaceStatus
        var onGesture: (GestureType) -> Void

        private let blinkThreshold: Float = 0.6
        private let blinkSuppressionThreshold: Float = 0.5
        private let blinkSuppressionDecay: Float = 0.025
        private var dampedBlinkLevel: Float = 0
        private var lastLeftBlinkState = false
        private var lastRightBlinkState = false
        private var directionLatch: FaceStatus.Direction = .center

        init(status: Binding<FaceStatus>, onGesture: @escaping (GestureType) -> Void) {
            self._status = status
            self.onGesture = onGesture
        }

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            SCNNode()
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }

            // Head yaw/pitch
            let transform = faceAnchor.transform
            let (yaw, pitch) = Self.extractYawPitch(from: transform)
            let yawDeg = yaw * 180 / .pi
            let pitchDeg = pitch * 180 / .pi

            // Eye movement
            let li = faceAnchor.blendShapes[.eyeLookInLeft] as? Float ?? 0
            let lo = faceAnchor.blendShapes[.eyeLookOutLeft] as? Float ?? 0
            let ri = faceAnchor.blendShapes[.eyeLookInRight] as? Float ?? 0
            let ro = faceAnchor.blendShapes[.eyeLookOutRight] as? Float ?? 0
            let lu = faceAnchor.blendShapes[.eyeLookUpLeft] as? Float ?? 0
            let ld = faceAnchor.blendShapes[.eyeLookDownLeft] as? Float ?? 0
            let ru = faceAnchor.blendShapes[.eyeLookUpRight] as? Float ?? 0
            let rd = faceAnchor.blendShapes[.eyeLookDownRight] as? Float ?? 0

            // Blink
            let leftVal = faceAnchor.blendShapes[.eyeBlinkLeft] as? Float ?? 0
            let rightVal = faceAnchor.blendShapes[.eyeBlinkRight] as? Float ?? 0
            let leftBlink = leftVal > blinkThreshold
            let rightBlink = rightVal > blinkThreshold
            let blinkSuppressionLevel = max(leftVal, rightVal)
            dampedBlinkLevel = max(blinkSuppressionLevel, max(0, dampedBlinkLevel - blinkSuppressionDecay))

            // Horizontal: positive right
            let horiz = (ro + li) - (ri + lo)
            let eyeYawNorm = max(-1, min(1, Double(horiz / 2)))

            // Vertical: positive down (subtract blink bias)
            let vertRaw = (ld + rd) - (lu + ru)
            let blinkVerticalBias = Double(max(0, blinkSuppressionLevel - 0.2)) * 1.4
            let adjustedVert = Double(vertRaw) - blinkVerticalBias
            let eyePitchNorm = max(-1, min(1, adjustedVert / 2))

            let eyeYawDeg = eyeYawNorm * 30.0
            let eyePitchDeg = eyePitchNorm * 30.0

            DispatchQueue.main.async {
                var updated = self.status
                updated.yawDegrees = yawDeg
                updated.pitchDegrees = pitchDeg
                updated.leftBlink = leftBlink
                updated.rightBlink = rightBlink
                updated.leftBlinkValue = leftVal
                updated.rightBlinkValue = rightVal
                updated.eyeYawDegrees = eyeYawDeg
                updated.eyePitchDegrees = eyePitchDeg

                var (direction, activation) = updated.gazeDirection(for: eyeYawDeg, eyePitch: eyePitchDeg)
                if self.dampedBlinkLevel > self.blinkSuppressionThreshold {
                    direction = .center
                    activation = 0
                }
                updated.direction = direction
                updated.gazeActivation = activation
                self.status = updated

                // Wink gestures (mirrored mapping as in test view)
                let bothBlinking = leftBlink && rightBlink
                if !bothBlinking {
                    if leftBlink && !self.lastLeftBlinkState { self.onGesture(.winkRight) }
                    if rightBlink && !self.lastRightBlinkState { self.onGesture(.winkLeft) }
                }

                // Direction gestures
                if activation >= 0.75, self.directionLatch != direction, let gesture = Self.gesture(from: direction) {
                    self.onGesture(gesture)
                    self.directionLatch = direction
                } else if direction == .center || activation < 0.25 {
                    self.directionLatch = .center
                }

                self.lastLeftBlinkState = leftBlink
                self.lastRightBlinkState = rightBlink
            }
        }

        private static func gesture(from direction: FaceStatus.Direction) -> GestureType? {
            switch direction {
            case .left: return .lookLeft
            case .right: return .lookRight
            case .up: return .lookUp
            case .down: return .lookDown
            case .center: return nil
            }
        }

        private static func extractYawPitch(from m: simd_float4x4) -> (yaw: Double, pitch: Double) {
            let r02 = Double(m.columns.2.x)
            let r12 = Double(m.columns.2.y)
            let r22 = Double(m.columns.2.z)
            let yaw = atan2(r02, r22)
            let pitch = atan2(-r12, sqrt(r02*r02 + r22*r22))
            return (yaw, pitch)
        }
    }
}

// MARK: - Debug Overlay
private struct AACDebugOverlay: View {
    let status: FaceStatus
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AR Debug")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            Text("Eye: \(status.direction.rawValue)")
                .font(.subheadline)
            Text(String(format: "Activation: %.0f%%", status.gazeActivation * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "Gaze yaw: %.2f°, pitch: %.2f°", status.eyeYawDegrees, status.eyePitchDegrees))
                .font(.caption)
            Text(String(format: "Head yaw: %.2f°, pitch: %.2f°", status.yawDegrees, status.pitchDegrees))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "Blink L: %.2f  R: %.2f", status.leftBlinkValue, status.rightBlinkValue))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

// MARK: - Calibration Sheet (mirrors ARKitFaceTestView flow)
private struct AACCalibrationSheet: View {
    @Binding var status: FaceStatus
    @Binding var isCalibrating: Bool
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
            case .lookDown:
                return "Capture Down"
            case .neutral:
                return "Capture Center"
            case .lookLeft:
                return "Capture Left"
            case .lookRight:
                return "Capture Right"
            case .lookUp:
                return "Capture Up"
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
                        isCalibrating = false
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
                    Button("Close") { isCalibrating = false }
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
