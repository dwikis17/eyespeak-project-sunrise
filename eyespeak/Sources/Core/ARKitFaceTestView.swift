import SwiftUI
import ARKit
import SceneKit
import AudioToolbox

struct ARKitFaceTestView: View {
    @State private var status = FaceStatus()
    @State private var isCalibrating = false
    @State private var currentCombo: [GestureType] = []
    @State private var lastCombo: [GestureType]? = nil
    @State private var comboResetWorkItem: DispatchWorkItem? = nil
    private let comboTimeout: TimeInterval = 2.0

    var body: some View {
        ZStack(alignment: .bottom) {
            AACFaceTrackingView(status: $status, onGesture: handleGesture)
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

                ComboTrackerView(currentCombo: currentCombo, lastCombo: lastCombo)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Tip: Hold the phone in front of your face. During calibration, look straight ahead and then just past each edge of the screen to lock in your gaze thresholds.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
            .padding(.horizontal)
            .sheet(isPresented: $isCalibrating) {
                AACCalibrationSheet(status: $status, isPresented: $isCalibrating)
            }
        }
        .navigationTitle("ARKit Face Test")
        .onAppear {
            // no-op
        }
    }

    private func handleGesture(_ gesture: GestureType) {
        comboResetWorkItem?.cancel()

        if currentCombo.isEmpty {
            currentCombo = [gesture]
            scheduleComboReset()
            return
        }

        if currentCombo.count == 1 {
            currentCombo.append(gesture)
            lastCombo = currentCombo
            currentCombo = []
            comboResetWorkItem = nil
            return
        }

        // Fallback: start a new combo
        currentCombo = [gesture]
        scheduleComboReset()
    }

    private func scheduleComboReset() {
        let workItem = DispatchWorkItem {
            currentCombo = []
            comboResetWorkItem = nil
        }
        comboResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + comboTimeout, execute: workItem)
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

private struct ComboTrackerView: View {
    let currentCombo: [GestureType]
    let lastCombo: [GestureType]?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Combo Input")
                    .font(.headline)
                Spacer()
                if !currentCombo.isEmpty {
                    Text("\(currentCombo.count)/2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if currentCombo.isEmpty {
                Text("Waiting for actions…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ComboActionRow(actions: currentCombo)
            }

            if let lastCombo, !lastCombo.isEmpty {
                Divider()
                    .opacity(0.3)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last Combo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ComboActionRow(actions: lastCombo)
                }
            }
        }
    }
}

private struct ComboActionRow: View {
    let actions: [GestureType]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                ComboActionPill(action: action)
            }
        }
    }
}

private struct ComboActionPill: View {
    let action: GestureType

    var body: some View {
        Label(action.rawValue, systemImage: action.iconName)
            .font(.caption2)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack { ARKitFaceTestView() }
}
