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
    public var jawOpenValue: Float = 0
    public var mouthOpen: Bool = false
    public var browRaiseValue: Float = 0
    public var eyebrowsRaised: Bool = false

    // Eye-gaze derived angles (pseudo-degrees from blend shapes)
    public var eyeYawDegrees: Double = 0 // right positive
    public var eyePitchDegrees: Double = 0 // down positive

    // Gaze calibration reference points
    public var neutralEyeYaw: Double? = nil
    public var neutralEyePitch: Double? = nil
    public var leftEyeYawEdge: Double? = nil
    public var leftEyeYawOuter: Double? = nil
    public var rightEyeYawEdge: Double? = nil
    public var rightEyeYawOuter: Double? = nil
    public var upEyePitchEdge: Double? = nil
    public var upEyePitchOuter: Double? = nil
    public var downEyePitchEdge: Double? = nil
    public var downEyePitchOuter: Double? = nil

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
        leftEyeYawEdge != nil &&
        leftEyeYawOuter != nil &&
        rightEyeYawEdge != nil &&
        rightEyeYawOuter != nil &&
        upEyePitchEdge != nil &&
        upEyePitchOuter != nil &&
        downEyePitchEdge != nil &&
        downEyePitchOuter != nil
    }

    public var isGazeCalibrated: Bool {
        neutralEyeYaw != nil &&
        neutralEyePitch != nil &&
        leftEyeYawEdge != nil &&
        leftEyeYawOuter != nil &&
        rightEyeYawEdge != nil &&
        rightEyeYawOuter != nil &&
        upEyePitchEdge != nil &&
        upEyePitchOuter != nil &&
        downEyePitchEdge != nil &&
        downEyePitchOuter != nil
    }

    public func gazeDirection(for eyeYaw: Double, eyePitch: Double) -> (Direction, Double) {
        let defaultThreshold = 12.0
        let defaultRange = 25.0
        let minimumActivation = 0.45

        guard let neutralEyeYaw,
              let neutralEyePitch else {
            return fallbackDirection(eyeYaw: eyeYaw, eyePitch: eyePitch, minimumActivation: minimumActivation, defaultThreshold: defaultThreshold, defaultRange: defaultRange)
        }

        let horizontalDelta = eyeYaw - neutralEyeYaw
        let verticalDelta = eyePitch - neutralEyePitch

        let leftStrength = activationWithEdge(current: eyeYaw, neutral: neutralEyeYaw, edge: leftEyeYawEdge, outer: leftEyeYawOuter)
            ?? fallbackDirectionalActivation(delta: horizontalDelta, threshold: defaultThreshold, range: defaultRange, positiveDirection: false)

        let rightStrength = activationWithEdge(current: eyeYaw, neutral: neutralEyeYaw, edge: rightEyeYawEdge, outer: rightEyeYawOuter)
            ?? fallbackDirectionalActivation(delta: horizontalDelta, threshold: defaultThreshold, range: defaultRange, positiveDirection: true)

        let upStrength = activationWithEdge(current: eyePitch, neutral: neutralEyePitch, edge: upEyePitchEdge, outer: upEyePitchOuter)
            ?? fallbackDirectionalActivation(delta: verticalDelta, threshold: defaultThreshold, range: defaultRange, positiveDirection: false)

        let downStrength = activationWithEdge(current: eyePitch, neutral: neutralEyePitch, edge: downEyePitchEdge, outer: downEyePitchOuter)
            ?? fallbackDirectionalActivation(delta: verticalDelta, threshold: defaultThreshold, range: defaultRange, positiveDirection: true)

        let candidates: [(Direction, Double)] = [
            (.left, leftStrength),
            (.right, rightStrength),
            (.up, upStrength),
            (.down, downStrength)
        ]

        let best = candidates.max { $0.1 < $1.1 } ?? (.center, 0)
        if best.1 < minimumActivation {
            return (.center, 0)
        }
        return best
    }

    private func activationWithEdge(current: Double, neutral: Double, edge: Double?, outer: Double?) -> Double? {
        guard let edge, let outer else { return nil }
        if outer == edge { return nil }

        if outer < neutral {
            // Direction is towards decreasing values (left/up). Edge is closer to neutral.
            if current >= edge { return 0 }
            let span = edge - outer
            if span == 0 { return nil }
            let progress = (edge - current) / span
            return max(0, min(1, progress))
        } else {
            // Direction towards increasing values (right/down)
            if current <= edge { return 0 }
            let span = outer - edge
            if span == 0 { return nil }
            let progress = (current - edge) / span
            return max(0, min(1, progress))
        }
    }

    private func fallbackDirection(eyeYaw: Double, eyePitch: Double, minimumActivation: Double, defaultThreshold: Double, defaultRange: Double) -> (Direction, Double) {
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

    private func fallbackDirectionalActivation(
        delta: Double,
        threshold: Double,
        range: Double,
        positiveDirection: Bool
    ) -> Double {
        if positiveDirection {
            guard delta >= threshold else { return 0 }
            return min(1, (delta - threshold) / range)
        } else {
            guard delta <= -threshold else { return 0 }
            return min(1, (-delta - threshold) / range)
        }
    }
}
