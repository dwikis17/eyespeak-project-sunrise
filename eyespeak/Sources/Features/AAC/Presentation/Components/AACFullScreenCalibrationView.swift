//
//  AACFullScreenCalibrationView.swift
//  eyespeak
//
//  Created by dio on 2024/07/08.
//

import SwiftUI
import AudioToolbox

struct AACFullScreenCalibrationView: View {
    @Binding var status: FaceStatus
    @Binding var isPresented: Bool
    var onHoldToSnooze: (() -> Void)? = nil

    @StateObject private var holdSoundPlayer = HoldProgressSoundPlayer(duration: 2.0)
    @State private var step: CalibrationStep = .center
    @State private var instruction: String = "Let's set up your app"
    @State private var showInstruction: Bool = true
    @State private var timerProgress: CGFloat = 0
    @State private var isCapturing: Bool = false
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var isCalibrating: Bool = false
    @State private var didTriggerSnooze = false

    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    private let holdTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    private let snoozeHoldDuration: CGFloat = 2.0

    enum CalibrationStep: CaseIterable {
        case center, left, right, up, down, offScreenLeft, offScreenRight, offScreenUp, offScreenDown

        var position: Alignment {
            switch self {
            case .center: return .center
            case .left, .offScreenLeft: return .leading
            case .right, .offScreenRight: return .trailing
            case .up, .offScreenUp: return .top
            case .down, .offScreenDown: return .bottom
            }
        }
        var instruction: String {
            switch self {
            case .center: return "Look At The Dot"
            case .left, .right, .up, .down: return "Hold your gaze steady on the dot"
            case .offScreenLeft: return "Look 5cm to the left of the edge"
            case .offScreenRight: return "Look 5cm to the right of the edge"
            case .offScreenUp: return "Look 5cm above the edge"
            case .offScreenDown: return "Look 5cm below the edge"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            AACFaceTrackingView(status: $status).opacity(0.0001)
            if !isCalibrating {
                ZStack {
                    if showInstruction {
                        VStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Text("Eye Calibration")
                                    .font(Typography.boldHeaderJumbo)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.energeticOrange)
                                Text(instruction)
                                    .font(Typography.boldHeaderLarge)
                                    .foregroundColor(Color.whiteWhite)
                                Text("This will only take a minute")
                                    .font(Typography.regularHeader)
                                    .foregroundColor(Color.whiteWhite)
                            }
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(height: 60)

                                GeometryReader { geometry in
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.energeticOrange)
                                        .frame(width: geometry.size.width * holdProgress, height: 60)
                                }

                                HStack(spacing: 16) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.white)
                                    Text("Hold to snooze")
                                        .font(Typography.boldHeader)
                                        .foregroundColor(Color.whiteWhite)
                                }
                            }
                            .frame(height: 60)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .cornerRadius(24)
                .padding(20)
                .edgesIgnoringSafeArea(.all)
            } else {
                // Show calibration UI
                ZStack {
                    if step.position != .center {
                        CalibrationDot()
                            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                            .opacity(0.0)
                    }
                    
                    VStack {
                        Text(step.instruction)
                            .font(Typography.boldHeaderLarge)
                            .foregroundColor(.energeticOrange)
                        Text("Hold your gaze steady on the dot")
                            .font(Typography.regularHeader)
                            .foregroundColor(.white)
                    }
                    .offset(y: -100)

                    let dotDirection = isOffScreenStep(step) ? arrowDirection(for: step) : nil
                    CalibrationDot(progress: timerProgress, direction: dotDirection)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: step.position)
                        .padding(100)
                }
                .onReceive(timer) { _ in
                    guard isCapturing else { return }
                    if timerProgress < 1.0 {
                        timerProgress += 0.005 // 1.0 / (2.0 / 0.01)
                    } else {
                        captureData()
                    }
                }
            }
        }
        .foregroundColor(Color.whiteWhite)
        .onReceive(holdTimer) { _ in
            guard showInstruction, !didTriggerSnooze else { return }
            let eyesClosed = status.leftBlink && status.rightBlink
            if eyesClosed {
                if !isHolding {
                    isHolding = true
                    holdSoundPlayer.startProgressTone()
                }
                if holdProgress < 1.0 {
                    holdProgress = min(
                        1.0,
                        holdProgress + (CGFloat(0.01) / snoozeHoldDuration)
                    )
                    if holdProgress >= 1.0 {
                        didTriggerSnooze = true
                        holdSoundPlayer.stopProgressTone()
                        holdSoundPlayer.playCompletionPop()
                        onHoldToSnooze?()
                    }
                }
            } else {
                if isHolding {
                    isHolding = false
                    holdSoundPlayer.stopProgressTone()
                }
                holdProgress = 0
                autoStartCalibrationIfPossible()
            }
        }
    }

    private func startCalibration() {
        guard !isCalibrating else { return }
        isCalibrating = true
        isCapturing = true
    }

    private func captureData() {
        isCapturing = false
        timerProgress = 0
        
        switch step {
        case .center:
            status.neutralEyeYaw = status.eyeYawDegrees
            status.neutralEyePitch = status.eyePitchDegrees
        case .left:
            status.leftEyeYawEdge = status.eyeYawDegrees
        case .right:
            status.rightEyeYawEdge = status.eyeYawDegrees
        case .up:
            status.upEyePitchEdge = status.eyePitchDegrees
        case .down:
            status.downEyePitchEdge = status.eyePitchDegrees
        case .offScreenLeft:
            status.leftEyeYawOuter = status.eyeYawDegrees
        case .offScreenRight:
            status.rightEyeYawOuter = status.eyeYawDegrees
        case .offScreenUp:
            status.upEyePitchOuter = status.eyePitchDegrees
        case .offScreenDown:
            status.downEyePitchOuter = status.eyePitchDegrees
        }

        moveToNextStep()
    }

    private func playSound() {
        AudioServicesPlayAlertSound(1103)
    }
    
    private func autoStartCalibrationIfPossible() {
        guard showInstruction else { return }
        guard !(status.leftBlink && status.rightBlink) else { return }
        guard !didTriggerSnooze else { return }
        holdProgress = 0
        isHolding = false
        withAnimation {
            showInstruction = false
        }
        startCalibration()
    }

    private func moveToNextStep() {
        if let currentIndex = CalibrationStep.allCases.firstIndex(of: step), currentIndex + 1 < CalibrationStep.allCases.count {
            withAnimation(.easeInOut(duration: 0.5)) {
                step = CalibrationStep.allCases[currentIndex + 1]
            }
            playSound()
            isCapturing = true
        } else {
            isPresented = false
        }
    }
    
    private func isOffScreenStep(_ step: CalibrationStep) -> Bool {
        switch step {
        case .offScreenLeft, .offScreenRight, .offScreenUp, .offScreenDown:
            return true
        default:
            return false
        }
    }

    private func arrowDirection(for step: CalibrationStep) -> Edge {
        switch step {
        case .offScreenLeft: return .leading
        case .offScreenRight: return .trailing
        case .offScreenUp: return .top
        case .offScreenDown: return .bottom
        default: return .leading
        }
    }
}

struct CalibrationDot: View {
    var progress: CGFloat = 0
    var direction: Edge? = nil

    var body: some View {
        ZStack {
            if let direction = direction {
                Image(systemName: arrowSystemName(for: direction))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(Color.whiteWhite)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 55, height: 55)
            }
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.energeticOrange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
        }
    }

    private func arrowSystemName(for direction: Edge) -> String {
        switch direction {
        case .top: return "arrow.up"
        case .bottom: return "arrow.down"
        case .leading: return "arrow.left"
        case .trailing: return "arrow.right"
        }
    }
}

#if DEBUG
struct AACFullScreenCalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        AACFullScreenCalibrationView(
            status: .constant(FaceStatus()),
            isPresented: .constant(true)
        )
    }
}
#endif
