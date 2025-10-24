//
//  FaceStatus.swift
//  eyespeak
//
//  Shared face tracking status model previously defined inside ARKitFaceTestView.swift.
//  Extracted so AACViewModel and other features can observe and mutate tracking state.
//

import Foundation

public struct FaceStatus {
    public enum Direction: String { case center = "Center", left = "Left", right = "Right", up = "Up", down = "Down" }

    public init() {}

    // Raw readings
    public var yawDegrees: Double = 0
    public var pitchDegrees: Double = 0
    public var direction: Direction = .center
    public var leftBlink: Bool = false
    public var rightBlink: Bool = false
    public var leftBlinkValue: Float = 0
    public var rightBlinkValue: Float = 0

    // Eye-gaze derived angles (pseudo-degrees from blend shapes)
    public var eyeYawDegrees: Double = 0 // right positive
    public var eyePitchDegrees: Double = 0 // down positive

    // Gaze calibration reference points
    public var neutralEyeYaw: Double? = nil
    public var neutralEyePitch: Double? = nil
    public var leftEyeYaw: Double? = nil
    public var rightEyeYaw: Double? = nil
    public var upEyePitch: Double? = nil
    public var downEyePitch: Double? = nil

    // Gaze strength for UI/debugging
    public var gazeActivation: Double = 0

    // Neutral calibration baselines
    public var neutralYaw: Double? = nil
    public var neutralPitch: Double? = nil
    public var neutralLeftBlink: Float? = nil
    public var neutralRightBlink: Float? = nil

    // Calibrated readings
    public var calibratedYaw: Double { yawDegrees - (neutralYaw ?? 0) }
    public var calibratedPitch: Double { pitchDegrees - (neutralPitch ?? 0) }
    public var calibratedLeftBlink: Float { max(0, leftBlinkValue - (neutralLeftBlink ?? 0)) }
    public var calibratedRightBlink: Float { max(0, rightBlinkValue - (neutralRightBlink ?? 0)) }

    public var isCalibrated: Bool {
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

    public var isGazeCalibrated: Bool {
        neutralEyeYaw != nil &&
        neutralEyePitch != nil &&
        leftEyeYaw != nil &&
        rightEyeYaw != nil &&
        upEyePitch != nil &&
        downEyePitch != nil
    }

    public func gazeDirection(for eyeYaw: Double, eyePitch: Double) -> (Direction, Double) {
        let defaultThreshold = 12.0
        let defaultRange = 25.0
        let minimumActivation = 0.45

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

        let deadzoneFraction = 0.45 // require ~45% of calibrated travel before activating

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
        for candidate in candidates where candidate.1 > best.1 {
            best = candidate
        }
        if best.1 < minimumActivation {
            return (.center, 0)
        }
        return best
    }
}
