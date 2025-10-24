//
//  AACFaceTrackingView.swift
//  eyespeak
//
//  Thin wrapper around ARKit face tracking that reports gaze/blink gestures back
//  to the AAC view model. Lifted from ARKitFaceTestView so it can be embedded in
//  the production AAC experience.
//

import SwiftUI
import ARKit
import SceneKit
import AudioToolbox

struct AACFaceTrackingView: UIViewRepresentable {
    @Binding var status: FaceStatus
    var onGesture: ((GestureType) -> Void)?

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(status: $status)
        coordinator.onGesture = onGesture
        return coordinator
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
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        uiView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        context.coordinator.onGesture = onGesture
    }

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        @Binding var status: FaceStatus
        private let blinkThreshold: Float = 0.6 // 0..1 blend shape value
        private let blinkSuppressionThreshold: Float = 0.5
        private let blinkSuppressionDecay: Float = 0.025

        private var lastAnnouncedDirection: FaceStatus.Direction = .center
        private var lastPlayTime: CFAbsoluteTime = 0
        private let soundCooldown: CFTimeInterval = 0.6
        private var dampedBlinkLevel: Float = 0
        var onGesture: ((GestureType) -> Void)?
        private var lastLeftBlinkState = false
        private var lastRightBlinkState = false
        private var directionLatch: FaceStatus.Direction = .center

        init(status: Binding<FaceStatus>) {
            self._status = status
        }

        private func playSound(for direction: FaceStatus.Direction) {
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
            SCNNode()
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }

            let transform = faceAnchor.transform
            let (yaw, pitch) = Self.extractYawPitch(from: transform)
            let yawDeg = yaw * 180 / .pi
            let pitchDeg = pitch * 180 / .pi

            let li = faceAnchor.blendShapes[.eyeLookInLeft] as? Float ?? 0
            let lo = faceAnchor.blendShapes[.eyeLookOutLeft] as? Float ?? 0
            let ri = faceAnchor.blendShapes[.eyeLookInRight] as? Float ?? 0
            let ro = faceAnchor.blendShapes[.eyeLookOutRight] as? Float ?? 0
            let lu = faceAnchor.blendShapes[.eyeLookUpLeft] as? Float ?? 0
            let ld = faceAnchor.blendShapes[.eyeLookDownLeft] as? Float ?? 0
            let ru = faceAnchor.blendShapes[.eyeLookUpRight] as? Float ?? 0
            let rd = faceAnchor.blendShapes[.eyeLookDownRight] as? Float ?? 0

            let leftVal = faceAnchor.blendShapes[.eyeBlinkLeft] as? Float ?? 0
            let rightVal = faceAnchor.blendShapes[.eyeBlinkRight] as? Float ?? 0
            let leftBlink = leftVal > blinkThreshold
            let rightBlink = rightVal > blinkThreshold
            let blinkSuppressionLevel = max(leftVal, rightVal)
            dampedBlinkLevel = max(blinkSuppressionLevel, max(0, dampedBlinkLevel - blinkSuppressionDecay))

            let horiz = (ro + li) - (ri + lo) // positive -> right
            let eyeYawNorm = max(-1, min(1, Double(horiz / 2)))

            let vertRaw = (ld + rd) - (lu + ru) // positive -> down
            let blinkVerticalBias = Double(max(0, blinkSuppressionLevel - 0.2)) * 1.4
            let adjustedVert = Double(vertRaw) - blinkVerticalBias
            let eyePitchNorm = max(-1, min(1, adjustedVert / 2))

            let eyeYawDeg = eyeYawNorm * 30.0
            let eyePitchDeg = eyePitchNorm * 30.0

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
                if self.dampedBlinkLevel > self.blinkSuppressionThreshold {
                    direction = .center
                    activation = 0
                }
                updatedStatus.direction = direction
                updatedStatus.gazeActivation = activation
                self.status = updatedStatus

                self.handleDirectionChange(direction: direction, activation: activation)

                let bothBlinking = leftBlink && rightBlink
                if !bothBlinking {
                    if leftBlink && !self.lastLeftBlinkState {
                        self.onGesture?(.winkRight)
                    }
                    if rightBlink && !self.lastRightBlinkState {
                        self.onGesture?(.winkLeft)
                    }
                }

                if let gesture = Self.gesture(for: direction, activation: activation, latch: self.directionLatch) {
                    self.onGesture?(gesture)
                    self.directionLatch = direction
                } else if direction == .center || activation < 0.25 {
                    self.directionLatch = .center
                }

                self.lastLeftBlinkState = leftBlink
                self.lastRightBlinkState = rightBlink
            }
        }

        private static func gesture(for direction: FaceStatus.Direction, activation: Double, latch: FaceStatus.Direction) -> GestureType? {
            guard activation >= 0.75, direction != .center, direction != latch else {
                return nil
            }
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
            let r00 = Double(m.columns.0.x)
            let r20 = Double(m.columns.0.z)

            let yaw = atan2(r02, r22)
            let pitch = atan2(-r12, sqrt(r02 * r02 + r22 * r22))

            // Silence unused variable warnings while keeping readability above
            _ = r00
            _ = r20
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
