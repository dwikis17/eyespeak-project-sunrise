import SwiftUI
import ARKit
import AudioToolbox

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void
    var totalSteps: Int = 3
    var currentStep: Int = 0
    @State private var faceStatus = FaceStatus()
    @State private var playedBlinkStartCue = false
    @State private var trackingEnabled = true
    
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                OnboardingCardContainer {
                    HStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .center, spacing: 16) {
                            Spacer()
                            
                            WelcomeHeaderView(
                                title: "Welcome!",
                                subtitle: "Let's set up your app",
                                alignment: .center,
                                titleSize: 72,
                                subtitleSize: 32
                            )
                            Text("This will only take a minute")
                                .font(Typography.regularHeader)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                            ProgressDotsView(current: currentStep, total: totalSteps, dotSize: 12, spacing: 8)
                                .frame(maxWidth: .infinity)

                            Spacer()

                            BlinkHoldCTAView(title: "Blink and hold to continue", action: {
                                // First cue: simulate blink start when button tapped
                                trackingEnabled = false
                                AudioServicesPlaySystemSound(1057)
                                onContinue() // Second cue handled by parent during page change
                            }, background: Color(.systemGray5), foreground: .black, cornerRadius: 20, height: 120, textSize: 22, iconSize: 24)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                        DiagonalBrandPatternView()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: geo.size.height - 40)
            }
            .padding(20)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color(.systemGroupedBackground))
        // Invisible face-tracking view to enable blink-and-hold continue
        .overlay(
            Group {
                if trackingEnabled {
                    AACFaceTrackingView(
                        status: $faceStatus,
                        onEyesClosed: {
                            trackingEnabled = false
                            AudioServicesPlaySystemSound(1057)
                            onContinue()
                        },
                        eyesClosedDuration: 1.5
                    )
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
                    .opacity(0.01)
                }
            }
        )
        .onDisappear { trackingEnabled = false }
        .onChange(of: faceStatus.leftBlink) { newVal in
            if newVal && !playedBlinkStartCue {
                AudioServicesPlaySystemSound(1057)
                playedBlinkStartCue = true
            } else if !faceStatus.leftBlink && !faceStatus.rightBlink {
                playedBlinkStartCue = false
            }
        }
        .onChange(of: faceStatus.rightBlink) { newVal in
            if newVal && !playedBlinkStartCue {
                AudioServicesPlaySystemSound(1057)
                playedBlinkStartCue = true
            } else if !faceStatus.leftBlink && !faceStatus.rightBlink {
                playedBlinkStartCue = false
            }
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
