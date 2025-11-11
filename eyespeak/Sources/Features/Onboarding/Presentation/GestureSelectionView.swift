//
//  GestureSelectionView.swift
//  eyespeak
//
//  Created by Dwiki on 20/10/25.
//

import SwiftUI
import SwiftData
import ARKit

struct GestureSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateManager.self) private var appState
    @State private var viewModel: OnboardingViewModel?
    @State private var isInitialized = false
    private let contentMaxWidth: CGFloat = 900

    // Scanning + blink selection
    @State private var scanIndex: Int = 0
    @State private var scanTimer: Timer?
    @State private var faceStatus = FaceStatus()
    @State private var isScanPaused: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Top centered header to match screenshot
            Text("Choose Your Actions")
                .font(.system(size: 36, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)

            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView("Loading gestures...")
            }
        }
        .padding(24)
        .onAppear {
            initializeViewModel()
        }
        .overlay(
            AACFaceTrackingView(
                status: $faceStatus,
                onEyesClosed: { handleBlinkHoldSelection() },
                eyesClosedDuration: 2.0
            )
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .opacity(0.01)
        )
    }

    @ViewBuilder
    private func contentView(viewModel: OnboardingViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
        } else if let errorMessage = viewModel.errorMessage {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text(errorMessage)
                    .foregroundColor(.red)
                Button("Retry") {
                    Task { await viewModel.loadUserGestures() }
                }
            }
        } else {
            HStack(alignment: .top, spacing: 20) {
                // Left column: gesture list with scroll showing ~6 items
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 14) {
                            ForEach(Array(viewModel.userGestures.enumerated()), id: \.element.id) { idx, userGesture in
                                SelectableGestureRow(
                                    userGesture: userGesture,
                                    isSelected: viewModel.isGestureSelected(userGesture),
                                    isHighlighted: scanIndex == idx,
                                    onTap: { viewModel.toggleGestureSelection(userGesture) }
                                )
                                .id(idx)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(width: 300, height: 520)
                    .onChange(of: scanIndex) { newVal in
                        if newVal < viewModel.userGestures.count {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(newVal, anchor: .top)
                            }
                        }
                    }
                }

                // Vertical divider between columns to match screenshot
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 2)
                    .frame(maxHeight: 560)

                // Right column wrapped in card container: camera preview + detail + CTA
                OnboardingCardContainer {
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemBackground))
                            .overlay(
                                Group {
                                    if ARFaceTrackingConfiguration.isSupported {
                                        AACFaceTrackingView(status: $faceStatus)
                                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    } else {
                                        VStack(spacing: 12) {
                                            Image(systemName: "faceid").font(.largeTitle)
                                            Text("TrueDepth camera required for preview")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            )
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)

                        if let selected = currentHighlightedGesture(viewModel: viewModel) {
                            GestureDetailCard(userGesture: selected)
                        }

                        BlinkHoldCTAView(action: { toggleCurrentSelection(viewModel: viewModel) })
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(scanIndex == viewModel.userGestures.count ? Color.accentColor : .clear, lineWidth: 3)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: contentMaxWidth)

            // Bottom Next button
            Button(action: { performNext(viewModel: viewModel) }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(scanIndex == viewModel.userGestures.count ? Color.accentColor : .clear, lineWidth: 0)
                    )
            }
            .frame(maxWidth: contentMaxWidth)
            .padding(.top, 8)
            .onAppear { startScan(totalItems: viewModel.userGestures.count + 1) }
            .onDisappear { stopScan() }
            .onChange(of: faceStatus.leftBlink) { _ in maybeResumeScan() }
            .onChange(of: faceStatus.rightBlink) { _ in maybeResumeScan() }
        }
    }

    // MARK: - Scanning
    private func startScan(totalItems: Int) {
        stopScan()
        let interval = max(0.5, appState.settings.timerSpeed)
        scanTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard !isScanPaused else { return }
            scanIndex = (scanIndex + 1) % totalItems
        }
    }

    private func stopScan() {
        scanTimer?.invalidate()
        scanTimer = nil
    }

    // MARK: - Blink-Hold selection
    private func handleBlinkHoldSelection() {
        guard let vm = viewModel else { return }
        if scanIndex < vm.userGestures.count {
            toggleCurrentSelection(viewModel: vm)
        } else {
            performNext(viewModel: vm)
        }
        // Pause scanning until eyes reopen
        isScanPaused = true
        stopScan()
    }

    private func toggleCurrentSelection(viewModel: OnboardingViewModel) {
        guard scanIndex < viewModel.userGestures.count else { return }
        let target = viewModel.userGestures[scanIndex]
        viewModel.toggleGestureSelection(target)
    }

    private func performNext(viewModel: OnboardingViewModel) {
        Task {
            do {
                try await viewModel.saveGestureSelection()
                appState.completeOnboarding()
                print("Onboarding completed successfully!")
            } catch {
                print("Failed to save gesture selection: \(error.localizedDescription)")
            }
        }
    }

    private func maybeResumeScan() {
        // Resume once both eyes are open
        if !faceStatus.leftBlink && !faceStatus.rightBlink && isScanPaused {
            isScanPaused = false
            let total = (viewModel?.userGestures.count ?? 0) + 1
            startScan(totalItems: total)
        }
    }

    private func currentHighlightedGesture(viewModel: OnboardingViewModel) -> UserGesture? {
        guard scanIndex < viewModel.userGestures.count else { return nil }
        return viewModel.userGestures[scanIndex]
    }

    private func initializeViewModel() {
        guard !isInitialized else { return }
        isInitialized = true

        let viewModel = OnboardingViewModel(modelContext: modelContext)
        self.viewModel = viewModel

        Task { await viewModel.loadUserGestures() }
    }
}

// MARK: - Selectable Row (left list)
private struct SelectableGestureRow: View {
    let userGesture: UserGesture
    let isSelected: Bool
    let isHighlighted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.orange)
                        .frame(width: 64, height: 64)
                    Image(systemName: userGesture.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(userGesture.displayName)
                        .font(.system(size: 18, weight: .semibold))
                    Text(subtitle(for: userGesture))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isHighlighted ? Color.orange : Color.clear, lineWidth: 3)
            )
        }
    }

    private func subtitle(for gesture: UserGesture) -> String {
        switch gesture.gestureType {
        case .lookRight: return "Look away from the screen toward your right side"
        case .lookLeft: return "Look away from the screen toward your left side"
        case .lookUp: return "Look away from the screen toward your up side"
        case .lookDown: return "Look away from the screen toward your down side"
        case .winkLeft: return "Look away from the screen toward your right side"
        case .winkRight: return "Look away from the screen toward your left side"
        default: return "Perform the gesture"
        }
    }
}

// MARK: - Detail Card (right column)
private struct GestureDetailCard: View {
    let userGesture: UserGesture

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.orange)
                    .frame(width: 84, height: 84)
                Image(systemName: userGesture.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 32, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(userGesture.displayName)
                        .font(.system(size: 20, weight: .semibold))
                    Text("Selected")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
                Text(detailText(for: userGesture))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private func detailText(for gesture: UserGesture) -> String {
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    }
}

#Preview {
    GestureSelectionView()
        .modelContainer(ModelContainer.preview)
}
