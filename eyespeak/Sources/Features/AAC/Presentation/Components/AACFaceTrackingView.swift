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
import QuartzCore

struct AACFaceTrackingView: UIViewRepresentable {
    @Binding var status: FaceStatus
    var onGesture: ((GestureType) -> Void)?
    var onEyesClosed: (() -> Void)? = nil
    var eyesClosedDuration: CFTimeInterval = 3.0

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(status: $status, eyesClosedDuration: eyesClosedDuration)
        coordinator.onGesture = onGesture
        coordinator.onEyesClosed = onEyesClosed
        return coordinator
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.contentMode = .scaleAspectFill
        view.session.delegate = context.coordinator
        view.delegate = context.coordinator
        view.scene = SCNScene()
        // Run face tracking once on creation instead of on every SwiftUI update
        if ARFaceTrackingConfiguration.isSupported {
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = true
            view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.onGesture = onGesture
        context.coordinator.onEyesClosed = onEyesClosed
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        @Binding var status: FaceStatus
        private let blinkThreshold: Float = 0.5 // 0..1 blend shape value
        private let blinkSuppressionThreshold: Float = 0.45
        private let blinkSuppressionDecay: Float = 0.035
        private let mouthOpenThreshold: Float = 0.35
        private let eyebrowsRaiseThreshold: Float = 0.25
        private let lipShiftThreshold: Float = 0.18
        private let lipShiftDifference: Float = 0.06
        private let smileThreshold: Float = 0.35
        private let winkDominanceThreshold: Float = 0.2

        private var lastAnnouncedDirection: FaceStatus.Direction = .center
        private var lastPlayTime: CFAbsoluteTime = 0
        private let soundCooldown: CFTimeInterval = 0.6
        private var dampedBlinkLevel: Float = 0
        var onGesture: ((GestureType) -> Void)?
        private var lastLeftBlinkState = false
        private var lastRightBlinkState = false
        private var lastMouthOpenState = false
        private var lastBrowState = false
        private var lastLipLeftState = false
        private var lastLipRightState = false
        private var lastSmileState = false
        private var directionLatch: FaceStatus.Direction = .center
        private var eyesClosedStartTime: CFAbsoluteTime?
        private var eyesClosedTriggered = false
        private let eyesClosedDuration: CFTimeInterval
        var onEyesClosed: (() -> Void)?

        init(status: Binding<FaceStatus>, eyesClosedDuration: CFTimeInterval) {
            self._status = status
            self.eyesClosedDuration = eyesClosedDuration
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

        private var lastUpdateTime: CFTimeInterval = 0
        private let minUpdateInterval: CFTimeInterval = 1.0 / 30.0

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // no-op; we use didUpdate node for face anchor below
        }

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            SCNNode()
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }

            // Throttle processing to reduce frame retention in delegate
            let now = CACurrentMediaTime()
            if now - lastUpdateTime < minUpdateInterval { return }
            lastUpdateTime = now

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
            let jaw = faceAnchor.blendShapes[.jawOpen] as? Float ?? 0
            let brow = faceAnchor.blendShapes[.browOuterUpLeft] as? Float ?? 0
            let browRight = faceAnchor.blendShapes[.browOuterUpRight] as? Float ?? 0
            let mouthLeftShift = max(0, faceAnchor.blendShapes[.mouthLeft] as? Float ?? 0)
            let mouthRightShift = max(0, faceAnchor.blendShapes[.mouthRight] as? Float ?? 0)
            let smileLeft = faceAnchor.blendShapes[.mouthSmileLeft] as? Float ?? 0
            let smileRight = faceAnchor.blendShapes[.mouthSmileRight] as? Float ?? 0

            let leftVal = faceAnchor.blendShapes[.eyeBlinkLeft] as? Float ?? 0
            let rightVal = faceAnchor.blendShapes[.eyeBlinkRight] as? Float ?? 0
            let leftBlink = leftVal > blinkThreshold
            let rightBlink = rightVal > blinkThreshold
            let blinkSuppressionLevel = max(leftVal, rightVal)
            dampedBlinkLevel = max(blinkSuppressionLevel, max(0, dampedBlinkLevel - blinkSuppressionDecay))
            let mouthOpen = jaw > mouthOpenThreshold
            let browsRaised = (brow + browRight) * 0.5 > eyebrowsRaiseThreshold
            let lipsShiftMagnitude = max(mouthLeftShift, mouthRightShift)
            let lipsPuckerLeft = lipsShiftMagnitude > lipShiftThreshold && (mouthLeftShift - mouthRightShift) > lipShiftDifference
            let lipsPuckerRight = lipsShiftMagnitude > lipShiftThreshold && (mouthRightShift - mouthLeftShift) > lipShiftDifference
            let smiling = (smileLeft + smileRight) * 0.5 > smileThreshold
            let leftDominantWink = (leftVal - rightVal) > winkDominanceThreshold
            let rightDominantWink = (rightVal - leftVal) > winkDominanceThreshold

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
                updatedStatus.jawOpenValue = jaw
                updatedStatus.mouthOpen = mouthOpen
                updatedStatus.browRaiseValue = (brow + browRight) * 0.5
                updatedStatus.eyebrowsRaised = browsRaised
                updatedStatus.lipPuckerLeftValue = mouthRightShift
                updatedStatus.lipPuckerRightValue = mouthLeftShift
                updatedStatus.lipsPuckeredLeft = lipsPuckerRight
                updatedStatus.lipsPuckeredRight = lipsPuckerLeft
                updatedStatus.smileValue = (smileLeft + smileRight) * 0.5
                updatedStatus.isSmiling = smiling

                var (direction, activation) = updatedStatus.gazeDirection(for: eyeYawDeg, eyePitch: eyePitchDeg)
                if self.dampedBlinkLevel > self.blinkSuppressionThreshold {
                    direction = .center
                    activation = 0
                }
                updatedStatus.direction = direction
                updatedStatus.gazeActivation = activation
                self.status = updatedStatus

                self.handleDirectionChange(direction: direction, activation: activation)

                // Disable blink and wink derived gestures

                if let gesture = Self.gesture(for: direction, activation: activation, latch: self.directionLatch) {
                    self.onGesture?(gesture)
                    self.directionLatch = direction
                } else if direction == .center || activation < 0.25 {
                    self.directionLatch = .center
                }

                // Emit rising-edge events before updating flags
                if mouthOpen && !self.lastMouthOpenState { self.onGesture?(.mouthOpen) }
                if browsRaised && !self.lastBrowState { self.onGesture?(.raiseEyebrows) }
                
                // Front-facing camera is mirrored: swap wink mapping so
                // user's left-eye wink triggers .winkLeft semantically.
                if leftBlink && !rightBlink && leftDominantWink && !self.lastLeftBlinkState {
                    self.onGesture?(.winkRight)
                }
                if rightBlink && !leftBlink && rightDominantWink && !self.lastRightBlinkState {
                    self.onGesture?(.winkLeft)
                }
                
                if lipsPuckerLeft && !self.lastLipLeftState { self.onGesture?(.lipPuckerRight) }
                if lipsPuckerRight && !self.lastLipRightState { self.onGesture?(.lipPuckerLeft) }
                if smiling && !self.lastSmileState { self.onGesture?(.smile) }

                // Detect sustained eye closure for calibration trigger
                if leftBlink && rightBlink {
                    if self.eyesClosedStartTime == nil {
                        self.eyesClosedStartTime = CACurrentMediaTime()
                    }
                    if let start = self.eyesClosedStartTime,
                       !self.eyesClosedTriggered,
                       CACurrentMediaTime() - start >= self.eyesClosedDuration {
                        self.eyesClosedTriggered = true
                        self.onEyesClosed?()
                    }
                } else {
                    self.eyesClosedStartTime = nil
                    self.eyesClosedTriggered = false
                }

                // Update last-state flags
                self.lastLeftBlinkState = leftBlink
                self.lastRightBlinkState = rightBlink
                self.lastMouthOpenState = mouthOpen
                self.lastBrowState = browsRaised
                self.lastLipLeftState = lipsPuckerLeft
                self.lastLipRightState = lipsPuckerRight
                self.lastSmileState = smiling
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
