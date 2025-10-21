import SwiftUI
import ARKit
import SceneKit
import AudioToolbox

struct ARKitFaceTestView: View {
    @State private var status = FaceStatus()
    @State private var isCalibrating = false

    var body: some View {
        ZStack(alignment: .bottom) {
            FaceTrackingView(status: $status)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    // Calibration status and action
                    Label(status.isCalibrated ? "Calibrated" : "Not Calibrated", systemImage: status.isCalibrated ? "checkmark.seal.fill" : "exclamationmark.triangle")
                        .font(.subheadline)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    Button(status.isCalibrated ? "Recalibrate" : "Calibrate") {
                        isCalibrating = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                // Head direction and raw angles
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Eye: \(status.direction.rawValue)")
                            .font(.headline)
                        Text(String(format: "Strength: %.0f%%", status.gazeActivation * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    Text(String(format: "yaw: %.2f°, pitch: %.2f°", status.yawDegrees, status.pitchDegrees))
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Gaze arrow and blink gauges
                HStack(spacing: 12) {
                    GazeArrowView(yaw: status.eyeYawDegrees, pitch: status.eyePitchDegrees)
                        .frame(width: 100, height: 100)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .bottom) {
                            Text("Gaze")
                                .font(.caption2)
                                .padding(4)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(4)
                        }

                    VStack(spacing: 8) {
                        BlinkGauge(title: "Left", value: status.leftBlinkValue, neutral: status.neutralLeftBlink)
                        BlinkGauge(title: "Right", value: status.rightBlinkValue, neutral: status.neutralRightBlink)
                    }
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Tip: Hold the phone in front of your face. During calibration, look straight ahead and then just past each edge of the screen to lock in your gaze thresholds.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
            .padding(.horizontal)
            .sheet(isPresented: $isCalibrating) {
                CalibrationSheet(status: $status, isCalibrating: $isCalibrating)
            }
        }
        .navigationTitle("ARKit Face Test")
        .onAppear {
            // no-op
        }
    }
}

// MARK: - Model
struct FaceStatus {
    enum Direction: String { case center = "Center", left = "Left", right = "Right", up = "Up", down = "Down" }
    // Raw readings
    var yawDegrees: Double = 0
    var pitchDegrees: Double = 0
    var direction: Direction = .center
    var leftBlink: Bool = false
    var rightBlink: Bool = false
    var leftBlinkValue: Float = 0
    var rightBlinkValue: Float = 0

    // Eye-gaze derived angles (pseudo-degrees from blend shapes)
    var eyeYawDegrees: Double = 0 // right positive
    var eyePitchDegrees: Double = 0 // down positive

    // Gaze calibration reference points
    var neutralEyeYaw: Double? = nil
    var neutralEyePitch: Double? = nil
    var leftEyeYaw: Double? = nil
    var rightEyeYaw: Double? = nil
    var upEyePitch: Double? = nil
    var downEyePitch: Double? = nil

    // Gaze strength for UI/debugging
    var gazeActivation: Double = 0

    // Neutral calibration baselines
    var neutralYaw: Double? = nil
    var neutralPitch: Double? = nil
    var neutralLeftBlink: Float? = nil
    var neutralRightBlink: Float? = nil

    // Calibrated readings
    var calibratedYaw: Double { yawDegrees - (neutralYaw ?? 0) }
    var calibratedPitch: Double { pitchDegrees - (neutralPitch ?? 0) }
    var calibratedLeftBlink: Float { max(0, leftBlinkValue - (neutralLeftBlink ?? 0)) }
    var calibratedRightBlink: Float { max(0, rightBlinkValue - (neutralRightBlink ?? 0)) }

    var isCalibrated: Bool {
        neutralYaw != nil &&
        neutralPitch != nil &&
        neutralLeftBlink != nil &&
        neutralRightBlink != nil &&
        neutralEyeYaw != nil &&
        neutralEyePitch != nil &&
        leftEyeYaw != nil &&
        rightEyeYaw != nil &&
        upEyePitch != nil &&
        downEyePitch != nil
    }

    var isGazeCalibrated: Bool {
        neutralEyeYaw != nil &&
        neutralEyePitch != nil &&
        leftEyeYaw != nil &&
        rightEyeYaw != nil &&
        upEyePitch != nil &&
        downEyePitch != nil
    }

    func gazeDirection(for eyeYaw: Double, eyePitch: Double) -> (Direction, Double) {
        let defaultThreshold = 10.0
        let defaultRange = 20.0
        let minimumActivation = 0.35

        guard isGazeCalibrated,
              let neutralEyeYaw,
              let neutralEyePitch,
              let leftEyeYaw,
              let rightEyeYaw,
              let upEyePitch,
              let downEyePitch else {
            let horizontalStrength = abs(eyeYaw) > defaultThreshold ? min(1, (abs(eyeYaw) - defaultThreshold) / defaultRange) : 0
            let verticalStrength = abs(eyePitch) > defaultThreshold ? min(1, (abs(eyePitch) - defaultThreshold) / defaultRange) : 0
            let dominantStrength = max(horizontalStrength, verticalStrength)

            guard dominantStrength >= minimumActivation else {
                return (.center, 0)
            }

            if horizontalStrength >= verticalStrength && eyeYaw <= -defaultThreshold {
                return (.left, horizontalStrength)
            }
            if horizontalStrength >= verticalStrength && eyeYaw >= defaultThreshold {
                return (.right, horizontalStrength)
            }
            if verticalStrength > horizontalStrength && eyePitch <= -defaultThreshold {
                return (.up, verticalStrength)
            }
            if verticalStrength > horizontalStrength && eyePitch >= defaultThreshold {
                return (.down, verticalStrength)
            }
            return (.center, 0)
        }

        let deadzoneFraction = 0.35 // require ~35% of calibrated travel before activating

        func activation(current: Double, neutral: Double, target: Double) -> Double {
            let delta = target - neutral
            if abs(delta) < 0.001 { return 0 }
            let threshold = neutral + delta * deadzoneFraction
            let span = delta * (1 - deadzoneFraction)
            if span == 0 { return 0 }

            if delta > 0 {
                let beyond = current - threshold
                guard beyond > 0 else { return 0 }
                return max(0, min(1, beyond / span))
            } else {
                let beyond = threshold - current
                guard beyond > 0 else { return 0 }
                return max(0, min(1, beyond / -span))
            }
        }

        let leftStrength = activation(current: eyeYaw, neutral: neutralEyeYaw, target: leftEyeYaw)
        let rightStrength = activation(current: eyeYaw, neutral: neutralEyeYaw, target: rightEyeYaw)
        let upStrength = activation(current: eyePitch, neutral: neutralEyePitch, target: upEyePitch)
        let downStrength = activation(current: eyePitch, neutral: neutralEyePitch, target: downEyePitch)

        var best: (Direction, Double) = (.center, 0)
        let candidates: [(Direction, Double)] = [
            (.left, leftStrength),
            (.right, rightStrength),
            (.up, upStrength),
            (.down, downStrength)
        ]
        for candidate in candidates {
            if candidate.1 > best.1 {
                best = candidate
            }
        }
        if best.1 < minimumActivation {
            return (.center, 0)
        }
        return best
    }
}

// MARK: - Overlay Helpers
private struct BlinkGauge: View {
    let title: String
    let value: Float // 0..1 raw
    let neutral: Float?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("\(title) Eye", systemImage: title == "Left" ? "eye" : "eye")
                    .font(.caption)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule().fill(Color.blue.opacity(0.6))
                        .frame(width: max(0, min(CGFloat(value), 1)) * geo.size.width)
                    if let n = neutral {
                        let x = max(0, min(CGFloat(n), 1)) * geo.size.width
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 2)
                            .position(x: x, y: geo.size.height/2)
                    }
                }
            }
            .frame(height: 10)
        }
    }
}

private struct GazeArrowView: View {
    let yaw: Double // degrees, positive right
    let pitch: Double // degrees, positive down
    private let maxDeg: Double = 30 // clamp for visualization

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let radius = min(size.width, size.height)/2 - 6

            // background circle
            let circle = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius*2, height: radius*2))
            context.stroke(circle, with: .color(.secondary.opacity(0.3)), lineWidth: 1)

            // map yaw/pitch to point
            let clampedYaw = max(-maxDeg, min(maxDeg, yaw))
            let clampedPitch = max(-maxDeg, min(maxDeg, pitch))
            let nx = clampedYaw / maxDeg // -1..1
            let ny = clampedPitch / maxDeg // -1..1 (down positive)
            let end = CGPoint(x: center.x + CGFloat(nx) * radius, y: center.y + CGFloat(ny) * radius)

            var path = Path()
            path.move(to: center)
            path.addLine(to: end)
            context.stroke(path, with: .color(.blue), lineWidth: 3)

            // endpoint dot
            let dotRect = CGRect(x: end.x - 4, y: end.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: dotRect), with: .color(.blue))
        }
    }
}

private struct CalibrationSheet: View {
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

// MARK: - UIViewRepresentable wrapper
private struct FaceTrackingView: UIViewRepresentable {
    @Binding var status: FaceStatus

    func makeCoordinator() -> Coordinator { Coordinator(status: $status) }

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
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        uiView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        @Binding var status: FaceStatus
        private let blinkThreshold: Float = 0.6 // 0..1 blend shape value
        private let blinkSuppressionThreshold: Float = 0.45

        private var lastAnnouncedDirection: FaceStatus.Direction = .center
        private var lastPlayTime: CFAbsoluteTime = 0
        private let soundCooldown: CFTimeInterval = 0.6

        init(status: Binding<FaceStatus>) {
            self._status = status
        }

        private func playSound(for direction: FaceStatus.Direction) {
            // Map directions to system sounds
            // Note: SystemSoundID values are subject to change; replace with custom audio in your bundle for production.
            let soundID: SystemSoundID
            switch direction {
            case .left:
                soundID = 1104 // Tock-like
            case .right:
                soundID = 1103 // Tink-like
            case .up:
                soundID = 1057 // Tweet-like
            case .down:
                soundID = 1156 // Bell-like
            case .center:
                return
            }
            AudioServicesPlaySystemSound(soundID)
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // no-op; we use didUpdate node for face anchor below
        }

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            return SCNNode()
        }

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // no-op
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }

            // Extract yaw/pitch from face transform
            let transform = faceAnchor.transform
            let (yaw, pitch) = Self.extractYawPitch(from: transform)
            let yawDeg = yaw * 180 / .pi
            let pitchDeg = pitch * 180 / .pi

            // Eye movement detection via blend shapes
            let li = faceAnchor.blendShapes[.eyeLookInLeft] as? Float ?? 0
            let lo = faceAnchor.blendShapes[.eyeLookOutLeft] as? Float ?? 0
            let ri = faceAnchor.blendShapes[.eyeLookInRight] as? Float ?? 0
            let ro = faceAnchor.blendShapes[.eyeLookOutRight] as? Float ?? 0
            let lu = faceAnchor.blendShapes[.eyeLookUpLeft] as? Float ?? 0
            let ld = faceAnchor.blendShapes[.eyeLookDownLeft] as? Float ?? 0
            let ru = faceAnchor.blendShapes[.eyeLookUpRight] as? Float ?? 0
            let rd = faceAnchor.blendShapes[.eyeLookDownRight] as? Float ?? 0

            // Horizontal: looking right increases right-out + left-in, left increases right-in + left-out
            let horiz = (ro + li) - (ri + lo) // positive -> right
            // Vertical: looking down increases left-down + right-down, up increases left-up + right-up
            let vert = (ld + rd) - (lu + ru) // positive -> down

            // Normalize roughly to [-1, 1]
            let eyeYawNorm = max(-1, min(1, Double(horiz / 2)))
            let eyePitchNorm = max(-1, min(1, Double(vert / 2)))

            // Convert to pseudo-degrees for visualization (match GazeArrowView expectations)
            let eyeYawDeg = eyeYawNorm * 30.0
            let eyePitchDeg = eyePitchNorm * 30.0

            // Blink detection
            let leftVal = faceAnchor.blendShapes[.eyeBlinkLeft] as? Float ?? 0
            let rightVal = faceAnchor.blendShapes[.eyeBlinkRight] as? Float ?? 0
            let leftBlink = leftVal > blinkThreshold
            let rightBlink = rightVal > blinkThreshold
            let blinkSuppressionLevel = min(leftVal, rightVal)

            DispatchQueue.main.async {
                var updatedStatus = self.status
                updatedStatus.yawDegrees = yawDeg
                updatedStatus.pitchDegrees = pitchDeg
                updatedStatus.leftBlink = leftBlink
                updatedStatus.rightBlink = rightBlink
                updatedStatus.leftBlinkValue = leftVal
                updatedStatus.rightBlinkValue = rightVal
                updatedStatus.eyeYawDegrees = eyeYawDeg
                updatedStatus.eyePitchDegrees = eyePitchDeg

                var (direction, activation) = updatedStatus.gazeDirection(for: eyeYawDeg, eyePitch: eyePitchDeg)
                if blinkSuppressionLevel > self.blinkSuppressionThreshold {
                    direction = .center
                    activation = 0
                }
                updatedStatus.direction = direction
                updatedStatus.gazeActivation = activation
                self.status = updatedStatus

                self.handleDirectionChange(direction: direction, activation: activation)
            }
        }

        // Extract yaw/pitch from a 4x4 matrix
        private static func extractYawPitch(from m: simd_float4x4) -> (yaw: Double, pitch: Double) {
            // Based on converting rotation matrix to Euler angles (YXZ order approximation)
            let r00 = Double(m.columns.0.x)
            let r01 = Double(m.columns.1.x)
            let r02 = Double(m.columns.2.x)
            let r10 = Double(m.columns.0.y)
            let r11 = Double(m.columns.1.y)
            let r12 = Double(m.columns.2.y)
            let r20 = Double(m.columns.0.z)
            let r21 = Double(m.columns.1.z)
            let r22 = Double(m.columns.2.z)

            // yaw (around Y), pitch (around X). Roll not needed here.
            let yaw = atan2(r02, r22)
            let pitch = atan2(-r12, sqrt(r02*r02 + r22*r22))
            return (yaw, pitch)
        }

        private func handleDirectionChange(direction: FaceStatus.Direction, activation: Double) {
            let now = CFAbsoluteTimeGetCurrent()
            if direction != .center && activation > 0.2 {
                if direction != lastAnnouncedDirection || (now - lastPlayTime) > soundCooldown {
                    playSound(for: direction)
                    lastAnnouncedDirection = direction
                    lastPlayTime = now
                }
            } else {
                lastAnnouncedDirection = .center
            }
        }
    }
}

#Preview {
    NavigationStack { ARKitFaceTestView() }
}
