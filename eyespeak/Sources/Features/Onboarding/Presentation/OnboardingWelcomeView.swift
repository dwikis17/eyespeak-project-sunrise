import SwiftUI
import ARKit

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void
    var totalSteps: Int = 3
    var currentStep: Int = 0
    @State private var faceStatus = FaceStatus()
    @State private var trackingEnabled = true
    @StateObject private var blinkHoldHandler = BlinkHoldProgressHandler()
    @State private var areEyesClosed = false
    @State private var hasSeenEyesOpen = false
    
    
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

                            BlinkHoldCTAView(
                                title: "Blink and hold to continue",
                                action: { blinkHoldHandler.completeImmediately() },
                                progress: blinkHoldHandler.progress,
                                background: Color(.systemGray5),
                                foreground: .black,
                                cornerRadius: 20,
                                height: 120,
                                textSize: 22,
                                iconSize: 24
                            )
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
                        status: $faceStatus
                    )
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
                    .opacity(0.01)
                }
            }
        )
        .onAppear {
            hasSeenEyesOpen = false
            blinkHoldHandler.onCompleted = { handleBlinkHoldCompletion() }
            blinkHoldHandler.enable()
        }
        .onDisappear {
            trackingEnabled = false
            blinkHoldHandler.disable()
        }
        .onChange(of: faceStatus.leftBlink) { _ in handleBlinkStateChange() }
        .onChange(of: faceStatus.rightBlink) { _ in handleBlinkStateChange() }
    }

    private func handleBlinkStateChange() {
        let eyesClosed = faceStatus.leftBlink && faceStatus.rightBlink
        if !eyesClosed {
            hasSeenEyesOpen = true
        }
        guard hasSeenEyesOpen else { return }
        guard eyesClosed != areEyesClosed else { return }
        areEyesClosed = eyesClosed
        blinkHoldHandler.update(eyesClosed: eyesClosed)
    }

    private func handleBlinkHoldCompletion() {
        guard trackingEnabled else { return }
        trackingEnabled = false
        blinkHoldHandler.disable()
        onContinue()
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
