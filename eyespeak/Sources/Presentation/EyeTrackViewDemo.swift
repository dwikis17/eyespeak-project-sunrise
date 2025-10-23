//
//  EyeTrackViewDemo.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import SwiftUI

// MARK: - Eye Tracking States (Simplified)
enum SimpleEyeTrackingState {
    case idle           // No gaze detected
    case gazing         // Gaze detected, building up
    case selected       // Gaze held long enough to select
    case activated      // Button was activated
}

// MARK: - Simple Eye Tracking Configuration
struct SimpleEyeTrackingConfig {
    let gazeThreshold: TimeInterval = 0.6      // Faster threshold
    let activationDelay: TimeInterval = 0.2    // Quicker activation
    let resetDelay: TimeInterval = 0.3         // Faster reset
}

// MARK: - Simple Eye Tracking Button (No Accessibility)
struct SimpleEyeTrackingButton: View {
    var title: String
    var icon: String = "play.rectangle.fill"
    var action: () -> Void
    var config: SimpleEyeTrackingConfig = SimpleEyeTrackingConfig()
    
    @State private var eyeTrackingState: SimpleEyeTrackingState = .idle
    @State private var gazeProgress: Double = 0.0
    @State private var gazeTimer: Timer?
    @State private var activationTimer: Timer?
    @State private var resetTimer: Timer?
    
    var body: some View {
        Button(action: handleButtonPress) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .background(backgroundView)
            .cornerRadius(10)
            .overlay(overlayView)
            .scaleEffect(scaleEffect)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: eyeTrackingState)
            .animation(.linear(duration: 0.1), value: gazeProgress)
        }
        .onReceive(NotificationCenter.default.publisher(for: .gazeEntered)) { _ in
            handleGazeEntered()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gazeExited)) { _ in
            handleGazeExited()
        }
    }
    
    // MARK: - Visual Components
    
    private var backgroundView: some View {
        ZStack {
            // Base background
            Color(.systemBackground)
            
            // Gaze progress overlay
            if eyeTrackingState == .gazing {
                Color.blue.opacity(gazeProgress * 0.4)
            }
            
            // Selected state overlay
            if eyeTrackingState == .selected {
                Color.green.opacity(0.5)
            }
            
            // Activated state overlay
            if eyeTrackingState == .activated {
                Color.orange.opacity(0.7)
            }
        }
    }
    
    private var overlayView: some View {
        ZStack {
            // Base border
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: borderWidth)
            
            // Gaze progress ring
            if eyeTrackingState == .gazing {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: [2, 6]
                        )
                    )
                    .opacity(gazeProgress)
            }
            
            // Selection ring
            if eyeTrackingState == .selected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.green, lineWidth: 3)
                    .shadow(color: .green, radius: 6, x: 0, y: 0)
            }
            
            // Activation ring
            if eyeTrackingState == .activated {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange, lineWidth: 4)
                    .shadow(color: .orange, radius: 8, x: 0, y: 0)
            }
        }
    }
    
    private var scaleEffect: CGFloat {
        switch eyeTrackingState {
        case .idle:
            return 1.0
        case .gazing:
            return 1.0 + (gazeProgress * 0.08)
        case .selected:
            return 1.08
        case .activated:
            return 1.15
        }
    }
    
    private var borderColor: Color {
        switch eyeTrackingState {
        case .idle:
            return .secondary.opacity(0.3)
        case .gazing:
            return .blue
        case .selected:
            return .green
        case .activated:
            return .orange
        }
    }
    
    private var borderWidth: CGFloat {
        switch eyeTrackingState {
        case .idle:
            return 1
        case .gazing:
            return 2
        case .selected:
            return 3
        case .activated:
            return 4
        }
    }
    
    private var iconColor: Color {
        switch eyeTrackingState {
        case .idle:
            return .primary
        case .gazing:
            return .blue
        case .selected:
            return .green
        case .activated:
            return .orange
        }
    }
    
    // MARK: - Gaze Handling
    
    private func handleGazeEntered() {
        resetTimers()
        
        // Start gaze timer
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                gazeProgress += 0.05 / config.gazeThreshold
                if gazeProgress >= 1.0 {
                    gazeProgress = 1.0
                    handleGazeThresholdReached()
                }
            }
        }
        
        withAnimation {
            eyeTrackingState = .gazing
        }
    }
    
    private func handleGazeExited() {
        resetTimers()
        
        // Start reset timer
        resetTimer = Timer.scheduledTimer(withTimeInterval: config.resetDelay, repeats: false) { _ in
            withAnimation {
                eyeTrackingState = .idle
                gazeProgress = 0.0
            }
        }
    }
    
    private func handleGazeThresholdReached() {
        gazeTimer?.invalidate()
        
        withAnimation {
            eyeTrackingState = .selected
        }
        
        // Start activation timer
        activationTimer = Timer.scheduledTimer(withTimeInterval: config.activationDelay, repeats: false) { _ in
            handleActivation()
        }
    }
    
    private func handleActivation() {
        withAnimation {
            eyeTrackingState = .activated
        }
        
        // Execute action
        action()
        
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                eyeTrackingState = .idle
                gazeProgress = 0.0
            }
        }
    }
    
    private func handleButtonPress() {
        // Manual button press - immediate activation
        resetTimers()
        withAnimation {
            eyeTrackingState = .activated
        }
        action()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                eyeTrackingState = .idle
                gazeProgress = 0.0
            }
        }
    }
    
    private func resetTimers() {
        gazeTimer?.invalidate()
        activationTimer?.invalidate()
        resetTimer?.invalidate()
        gazeTimer = nil
        activationTimer = nil
        resetTimer = nil
    }
}

// MARK: - Simple Eye Tracking Demo View
struct EyeTrackViewDemo: View {
    @State private var selectedButton: String?
    @State private var columns = 5
    
    // Sample button data for the grid
    private let buttonData = [
        ("Play", "play.rectangle.fill", "Play Video"),
        ("Pause", "pause.rectangle.fill", "Pause Video"),
        ("Stop", "stop.rectangle.fill", "Stop Video"),
        ("Settings", "gear", "Open Settings"),
        ("Help", "questionmark.circle", "Get Help"),
        ("Home", "house", "Go Home"),
        ("Back", "arrow.left", "Go Back"),
        ("Forward", "arrow.right", "Go Forward"),
        ("Search", "magnifyingglass", "Search"),
        ("Favorites", "heart", "Favorites"),
        ("History", "clock", "History"),
        ("Download", "arrow.down.circle", "Downloads"),
        ("Share", "square.and.arrow.up", "Share"),
        ("Like", "hand.thumbsup", "Like"),
        ("Dislike", "hand.thumbsdown", "Dislike"),
        ("Subscribe", "person.badge.plus", "Subscribe"),
        ("Profile", "person.circle", "Profile"),
        ("Notifications", "bell", "Notifications"),
        ("Messages", "message", "Messages"),
        ("Camera", "camera", "Camera"),
        ("Gallery", "photo", "Gallery"),
        ("Music", "music.note", "Music"),
        ("Books", "book", "Books"),
        ("News", "newspaper", "News"),
        ("Weather", "cloud.sun", "Weather"),
        ("Maps", "map", "Maps"),
        ("Calendar", "calendar", "Calendar"),
        ("Notes", "note.text", "Notes"),
        ("Calculator", "plus.forwardslash.minus", "Calculator"),
        ("Clock", "clock", "Clock"),
        ("Timer", "timer", "Timer"),
        ("Alarm", "alarm", "Alarm"),
        ("Contacts", "person.2", "Contacts"),
        ("Phone", "phone", "Phone"),
        ("Mail", "envelope", "Mail"),
        ("Safari", "safari", "Safari"),
        ("App Store", "app.badge", "App Store"),
        ("Files", "folder", "Files"),
        ("Keychain", "key", "Keychain"),
        ("Wallet", "creditcard", "Wallet"),
        ("Health", "heart.text.square", "Health"),
        ("Fitness", "figure.walk", "Fitness"),
        ("Sleep", "bed.double", "Sleep"),
        ("Mindfulness", "brain.head.profile", "Mindfulness"),
        ("Shortcuts", "app.badge", "Shortcuts"),
        ("Siri", "mic", "Siri"),
        ("Control Center", "slider.horizontal.3", "Control Center"),
        ("General", "gear", "General"),
        ("Privacy", "hand.raised", "Privacy"),
        ("Security", "lock", "Security"),
        ("Display", "display", "Display"),
        ("Sound", "speaker.wave.2", "Sound"),
        ("Battery", "battery.100", "Battery"),
        ("Storage", "internaldrive", "Storage"),
        ("iCloud", "icloud", "iCloud"),
        ("Wi-Fi", "wifi", "Wi-Fi"),
        ("Bluetooth", "bluetooth", "Bluetooth"),
        ("Cellular", "antenna.radiowaves.left.and.right", "Cellular"),
        ("Hotspot", "personalhotspot", "Hotspot"),
        ("VPN", "network", "VPN"),
        ("AirDrop", "airplay", "AirDrop"),
        ("AirPlay", "airplay", "AirPlay"),
        ("Screen Mirroring", "airplay", "Screen Mirroring"),
        ("Do Not Disturb", "moon", "Do Not Disturb"),
        ("Focus", "target", "Focus"),
        ("Sleep Focus", "bed.double", "Sleep Focus"),
        ("Work Focus", "briefcase", "Work Focus"),
        ("Personal Focus", "person", "Personal Focus"),
        ("Fitness Focus", "figure.walk", "Fitness Focus"),
        ("Gaming Focus", "gamecontroller", "Gaming Focus"),
        ("Reading Focus", "book", "Reading Focus"),
        ("Driving Focus", "car", "Driving Focus"),
        ("Emergency SOS", "sos", "Emergency SOS"),
        ("Emergency Contacts", "person.2", "Emergency Contacts"),
        ("Medical ID", "cross.case", "Medical ID"),
        ("Emergency Location", "location", "Emergency Location"),
        ("Emergency Call", "phone", "Emergency Call"),
        ("Emergency Text", "message", "Emergency Text"),
        ("Emergency Video", "video", "Emergency Video"),
        ("Emergency Audio", "mic", "Emergency Audio"),
        ("Emergency Photo", "camera", "Emergency Photo"),
        ("Emergency Recording", "record.circle", "Emergency Recording"),
        ("Emergency Share", "square.and.arrow.up", "Emergency Share"),
        ("Emergency Broadcast", "antenna.radiowaves.left.and.right", "Emergency Broadcast"),
        ("Emergency Alert", "exclamationmark.triangle", "Emergency Alert"),
        ("Emergency Warning", "exclamationmark.triangle.fill", "Emergency Warning"),
        ("Emergency Danger", "exclamationmark.octagon", "Emergency Danger"),
        ("Emergency Critical", "exclamationmark.octagon.fill", "Emergency Critical"),
        ("Emergency Fatal", "xmark.octagon", "Emergency Fatal"),
        ("Emergency Fatal Fill", "xmark.octagon.fill", "Emergency Fatal Fill")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Grid of buttons
                gridView(geometry: geometry)
                
                // Footer with controls
                footerView
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Simple Eye Tracking Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("No Accessibility Features - Pure Eye Tracking")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let selected = selectedButton {
                Text("Last activated: \(selected)")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func gridView(geometry: GeometryProxy) -> some View {
        let availableWidth = geometry.size.width - 32 // Account for padding
        let buttonWidth = (availableWidth - CGFloat(columns - 1) * 12) / CGFloat(columns) // 12pt spacing
        let buttonHeight = max(buttonWidth * 0.7, 80) // Smaller aspect ratio, minimum 80pt
        
        return ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
                spacing: 12
            ) {
                ForEach(Array(buttonData.enumerated()), id: \.offset) { index, data in
                    let (title, icon, fullTitle) = data
                    
                    SimpleEyeTrackingButton(
                        title: title,
                        icon: icon,
                        action: { handleButtonAction(fullTitle) }
                    )
                    .frame(width: buttonWidth, height: buttonHeight)
                }
            }
            .padding()
        }
    }
    
    private var footerView: some View {
        VStack(spacing: 16) {
            // Column control
            HStack {
                Text("Columns:")
                    .font(.headline)
                
                Picker("Columns", selection: $columns) {
                    Text("4").tag(4)
                    Text("5").tag(5)
                    Text("6").tag(6)
                    Text("7").tag(7)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Info text
            Text("Simplified version - faster animations, smaller buttons, no accessibility features")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func handleButtonAction(_ buttonTitle: String) {
        selectedButton = buttonTitle
        print("🎯 Simple button activated: \(buttonTitle)")
    }
}

#Preview {
    EyeTrackViewDemo()
}
