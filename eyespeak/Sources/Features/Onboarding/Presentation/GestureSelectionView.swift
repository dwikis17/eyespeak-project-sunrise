//
//  GestureSelectionView.swift
//  eyespeak
//
//  Created by Dwiki on 20/10/25.
//

import SwiftUI
import SwiftData
import ARKit
import AVKit
import AVFoundation

struct GestureSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateManager.self) private var appState
    @State private var viewModel: OnboardingViewModel?
    @State private var isInitialized = false
    private let contentMaxWidth: CGFloat = 900
    // EQUAL COLUMNS - 50/50 split
    private let leftColumnRatio: CGFloat = 0.50
    // Show exactly 6 rows per view
    private let rowsVisible: Int = 6
    private let rowHeight: CGFloat = 108
    private let rowSpacing: CGFloat = 18
    private let columnsExtraHeight: CGFloat = 40
    private var panelHeight: CGFloat {
        // Height for EXACTLY 6 rows - no more, no less
        CGFloat(rowsVisible) * rowHeight + CGFloat(rowsVisible - 1) * rowSpacing + 24
    }

    // Scanning + blink selection
    @State private var scanIndex: Int = 0
    @State private var scanTimer: Timer?
    @State private var faceStatus = FaceStatus()
    @State private var isScanPaused: Bool = false
    @State private var speechSynth = AVSpeechSynthesizer()
    @State private var playedBlinkStartCue = false
    @State private var trackingEnabled = false

    var body: some View {
        VStack(spacing: 16) {
            // Top centered header to match screenshot
            Text("Choose Your Actions")
                .font(Typography.boldHeaderLarge)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 12)
                .zIndex(2)
                

            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView("Loading gestures...")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        // Ensure the top header never gets clipped by the device notch/status bar
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 40)
        }
        .onAppear {
            initializeViewModel()
        }
        .overlay(
            Group {
                if trackingEnabled {
                    AACFaceTrackingView(
                        status: $faceStatus,
                        onEyesClosed: { handleBlinkHoldSelection() },
                        eyesClosedDuration: 2.0
                    )
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
                    .opacity(0.01)
                }
            }
        )
        .onAppear {
            // Delay activating tracking to avoid camera conflicts during transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                trackingEnabled = true
            }
        }
        .onDisappear { trackingEnabled = false }
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
            // Two-column layout with fixed height to prevent overlap
            HStack(alignment: .top, spacing: 20) {
                // Left column: gesture list with fixed height
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: rowSpacing) {
                            ForEach(Array(viewModel.userGestures.enumerated()), id: \.element.id) { idx, userGesture in
                                SelectableGestureRow(
                                    userGesture: userGesture,
                                    isSelected: viewModel.isGestureSelected(userGesture),
                                    isHighlighted: scanIndex == idx,
                                    rowHeight: rowHeight,
                                    onTap: { viewModel.toggleGestureSelection(userGesture) }
                                )
                                .id(idx)
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                    }
                    .clipShape(Rectangle())
                    .onChange(of: scanIndex) { newVal in
                        if newVal < viewModel.userGestures.count {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(newVal, anchor: .center)
                            }
                        }
                    }
                }
                .frame(height: panelHeight)
                .frame(maxWidth: .infinity)

                // Right column: tutorial preview + detail + CTA inside white box
                let ctaButtonHeight: CGFloat = 70
                let containerPadding: CGFloat = 16
                let totalSpacing: CGFloat = 32  // 2 gaps of 16pt each
                let availableHeight = panelHeight - totalSpacing - ctaButtonHeight - (containerPadding * 2)
                let boxHeight = availableHeight / 2  // Split remaining space equally between two boxes
                
                VStack(spacing: 16) {
                    // Video tutorial box
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemBackground))
                        .overlay(
                            VideoTutorialPreview(
                                gesture: currentHighlightedGesture(viewModel: viewModel),
                                highlightIndex: scanIndex
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: boxHeight)

                    // Gesture detail box
                    if let selected = currentHighlightedGesture(viewModel: viewModel) {
                        GestureDetailCard(userGesture: selected, isSelected: viewModel.isGestureSelected(selected))
                            .frame(maxWidth: .infinity)
                            .frame(height: boxHeight)
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: boxHeight)
                    }

                    // Blink and hold CTA button
                    BlinkHoldCTAView(
                        title: scanIndex == viewModel.userGestures.count
                            ? "Blink and hold to select Next to continue/save gestures"
                            : "Blink and hold to select",
                        action: { toggleCurrentSelection(viewModel: viewModel) }
                    )
                        .frame(height: ctaButtonHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(scanIndex == viewModel.userGestures.count ? Color.accentColor : .clear, lineWidth: 3)
                        )
                }
                .padding(containerPadding)
                .frame(height: panelHeight)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                )
            }
            .frame(maxWidth: contentMaxWidth)
            .frame(height: panelHeight)
            .onAppear { startScan(totalItems: viewModel.userGestures.count + 1) }
            .onDisappear { stopScan() }
            .onChange(of: faceStatus.leftBlink) { newVal in
                if newVal && !playedBlinkStartCue {
                    AudioServicesPlaySystemSound(1057)
                    playedBlinkStartCue = true
                } else if !faceStatus.leftBlink && !faceStatus.rightBlink {
                    playedBlinkStartCue = false
                }
                maybePauseScan()
                maybeResumeScan()
            }
            .onChange(of: faceStatus.rightBlink) { newVal in
                if newVal && !playedBlinkStartCue {
                    AudioServicesPlaySystemSound(1057)
                    playedBlinkStartCue = true
                } else if !faceStatus.leftBlink && !faceStatus.rightBlink {
                    playedBlinkStartCue = false
                }
                maybePauseScan()
                maybeResumeScan()
            }

            // Bottom Next button
            Button(action: { performNext(viewModel: viewModel) }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient.redOrange, lineWidth: 2)
                            .opacity(scanIndex == viewModel.userGestures.count ? 1 : 0)
                    )
            }
            .frame(maxWidth: contentMaxWidth)
            .padding(.top, 8)
            
        }
    }

    // MARK: - Scanning
    private func startScan(totalItems: Int) {
        stopScan()
        scheduleNextScanTick(totalItems: totalItems)
    }

    private func scheduleNextScanTick(totalItems: Int) {
        // Default interval 1.5s; dwell 2.0s when highlighting Next button
        let isOnNextButton = (scanIndex == totalItems - 1)
        let interval: TimeInterval = isOnNextButton ? 2.0 : 1.5
        scanTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            guard !isScanPaused else { return }
            scanIndex = (scanIndex + 1) % totalItems
            scheduleNextScanTick(totalItems: totalItems)
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
        let wasSelected = viewModel.isGestureSelected(target)
        viewModel.toggleGestureSelection(target)
        let nowSelected = !wasSelected
        speak(nowSelected ? "selected" : "unselected")
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

    private func maybePauseScan() {
        // Pause scan immediately when both eyes are closed to stabilize highlight
        if faceStatus.leftBlink && faceStatus.rightBlink && !isScanPaused {
            isScanPaused = true
            stopScan()
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9
        speechSynth.speak(utterance)
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
    let rowHeight: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient.redOrange)
                        .frame(width: 90, height: 90)
                    Image(systemName: userGesture.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 38, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(userGesture.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle(for: userGesture))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray.opacity(0.5))
                    .font(.system(size: 28))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LinearGradient.redOrange, lineWidth: 3)
                    .opacity(isHighlighted ? 1 : 0)
            )
            .frame(height: rowHeight)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func subtitle(for gesture: UserGesture) -> String {
        switch gesture.gestureType {
        case .lookRight: return "Look away from the screen toward your right side"
        case .lookLeft: return "Look away from the screen toward your left side"
        case .lookUp: return "Look away from the screen toward your up side"
        case .lookDown: return "Look away from the screen toward your down side"
        case .winkLeft: return "Close your left eye while keeping your right eye open"
        case .winkRight: return "Close your right eye while keeping your left eye open"
        case .blink: return "Close both eyes briefly and open them again"
        case .mouthOpen: return "Open your mouth wide"
        case .raiseEyebrows: return "Lift both eyebrows upward"
        case .lipPuckerLeft: return "Push your lips to the left side"
        case .lipPuckerRight: return "Push your lips to the right side"
        case .smile: return "Curve your lips upward into a smile"
        default: return "Perform the gesture"
        }
    }
}

// MARK: - Detail Card (right column)
private struct GestureDetailCard: View {
    let userGesture: UserGesture
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient.redOrange)
                    .frame(width: 84, height: 84)
                Image(systemName: userGesture.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 32, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(userGesture.displayName)
                        .font(.system(size: 20, weight: .semibold))
                    Text(isSelected ? "Selected" : "Unselected")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((isSelected ? Color.green : Color.red).opacity(0.2))
                        .foregroundColor(isSelected ? .green : .red)
                        .clipShape(Capsule())
                }
                Text(detailText(for: userGesture))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
    }

    private func detailText(for gesture: UserGesture) -> String {
        switch gesture.gestureType {
        case .lookRight: return "Look away from the screen toward your right side"
        case .lookLeft: return "Look away from the screen toward your left side"
        case .lookUp: return "Look away from the screen toward your up side"
        case .lookDown: return "Look away from the screen toward your down side"
        case .winkLeft: return "Close your left eye while keeping your right eye open"
        case .winkRight: return "Close your right eye while keeping your left eye open"
        case .blink: return "Close both eyes briefly and open them again"
        case .mouthOpen: return "Open your mouth wide"
        case .raiseEyebrows: return "Lift both eyebrows upward"
        case .lipPuckerLeft: return "Push your lips to the left side"
        case .lipPuckerRight: return "Push your lips to the right side"
        case .smile: return "Curve your lips upward into a smile"
        default: return "Perform the gesture"
        }
    }
}

// MARK: - Tutorial Video Preview
private struct VideoTutorialPreview: View {
    let gesture: UserGesture?
    let highlightIndex: Int

    var body: some View {
        Group {
            if let gesture, let url = tutorialURL(for: gesture) {
                VideoPlayerView(url: url)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle").font(.largeTitle)
                    Text("Select a gesture to preview tutorial")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
}

private struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer? = nil
    @State private var fadeOpacity: Double = 0.0

    var body: some View {
        Group {
            if let player {
                ZStack {
                    VideoPlayer(player: player)
                        .onAppear { player.playImmediately(atRate: 1.0) }
                        .onDisappear { player.pause() }
                        .onChange(of: url) { newURL in
                            // Crossfade to hide brief swap glitches
                            withAnimation(.easeInOut(duration: 0.18)) { fadeOpacity = 1.0 }

                            // Replace player item instantly when URL changes
                            let item = AVPlayerItem(url: newURL)
                            item.preferredForwardBufferDuration = 0
                            player.replaceCurrentItem(with: item)
                            player.isMuted = true
                            player.actionAtItemEnd = .none
                            player.automaticallyWaitsToMinimizeStalling = true
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
                                player.seek(to: .zero)
                                player.playImmediately(atRate: 1.0)
                            }
                            player.playImmediately(atRate: 1.0)

                            // Fade back in once playback resumes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                withAnimation(.easeInOut(duration: 0.18)) { fadeOpacity = 0.0 }
                            }
                        }

                    // Overlay to smooth out the item swap
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .opacity(fadeOpacity)
                        .allowsHitTesting(false)
                }
            } else {
                Color.clear.onAppear {
                    let newPlayer = AVPlayer(url: url)
                    newPlayer.actionAtItemEnd = .none
                    newPlayer.isMuted = true
                    newPlayer.automaticallyWaitsToMinimizeStalling = true
                    newPlayer.currentItem?.preferredForwardBufferDuration = 0
                    print("[Tutorial] Created AVPlayer for URL: \(url.lastPathComponent)")
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: newPlayer.currentItem, queue: .main) { _ in
                        newPlayer.seek(to: .zero)
                        newPlayer.playImmediately(atRate: 1.0)
                        print("[Tutorial] Looping video: \(url.lastPathComponent)")
                    }
                    player = newPlayer
                    fadeOpacity = 0.0
                }
            }
        }
    }
}

private func tutorialURL(for gesture: UserGesture) -> URL? {
    let baseName = videoName(for: gesture.gestureType)
    print("[Tutorial] Resolving video for: \(gesture.gestureType) baseName=\(baseName)")
    // Try common extensions and casings first
    for ext in ["mp4", "MP4", "mov", "MOV"] {
        // First try inside preserved subdirectory (blue folder reference)
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: "TutorialVideos") {
            print("[Tutorial] Found in subdirectory: \(baseName).\(ext)")
            return url
        }
        // Fallback: if Xcode did not preserve folder hierarchy, search the whole bundle
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
            print("[Tutorial] Found in bundle root: \(baseName).\(ext)")
            return url
        }
    }
    // Fallback: scan all files in subdirectory and match filename (case-insensitive or contains)
    if let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "TutorialVideos") {
        let lower = baseName.lowercased()
        print("[Tutorial] Scanning subdirectory files: \(urls.count) items")
        if let match = urls.first(where: { url in
            let name = url.deletingPathExtension().lastPathComponent
            let lname = name.lowercased()
            return lname == lower || lname.contains(lower)
        }) {
            print("[Tutorial] Matched in subdirectory by name: \(match.lastPathComponent)")
            return match
        }
    }
    // Global scan: match across entire bundle if folder not preserved
    if let all = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) {
        let lower = baseName.lowercased()
        print("[Tutorial] Scanning whole bundle: \(all.count) items")
        if let match = all.first(where: { url in
            let name = url.deletingPathExtension().lastPathComponent.lowercased()
            return name == lower || name.contains(lower)
        }) {
            print("[Tutorial] Matched in bundle by name: \(match.lastPathComponent)")
            return match
        }
    }
    print("[Tutorial] No video found for baseName=\(baseName). Ensure target membership & placement.")
    return nil
}

private func videoName(for type: GestureType) -> String {
    switch type {
    case .lookLeft: return "LookLeft"
    case .lookRight: return "LookRight"
    case .lookUp: return "LookUp"
    case .lookDown: return "LookDown"
    case .winkLeft: return "WinkLeft"
    case .winkRight: return "WinkRight"
    case .smile: return "Smile"
    case .mouthOpen: return "MouthOpen"
    case .raiseEyebrows: return "RaiseEyebrows"
    case .lipPuckerLeft: return "LipPuckerLeft"
    case .lipPuckerRight: return "LipPuckerRight"
    default: return "LookRight"
    }
}

#Preview {
    let appState = AppStateManager()
    
    GestureSelectionView()
        .modelContainer(ModelContainer.preview)
        .environment(AppStateManager())
}
