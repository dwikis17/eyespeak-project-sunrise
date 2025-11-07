

//
//  KeyboardView.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import SwiftUI
import UIKit
import Combine
// FoundationModels types are imported in SentencePredictionService.swift

// MARK: - Inline TextField with Prediction

struct InlineTextFieldWithPrediction: View {
    @Binding var text: String
    let prediction: String
    let onAcceptPrediction: () -> Void
    @State private var textFieldHeight: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Main text field
            TextField("Start typing here...", text: $text, axis: .vertical)
                .font(.system(size: 24))
                .padding(20)
                .lineLimit(10...20)
                .background(Color.clear)
            
            // Prediction overlay - only show when there's both text and prediction
            if !prediction.isEmpty && !text.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    // Invisible text to align prediction properly
                    Text(text)
                        .font(.system(size: 24))
                        .opacity(0)
                    
                    // Actual prediction text
                    Text(prediction)
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .allowsHitTesting(false)
                    
                    Spacer(minLength: 0)
                }
                .padding(20)
            }
        }
        .onTapGesture(count: 2) {
            // Double tap to accept prediction
            if !prediction.isEmpty {
                onAcceptPrediction()
            }
        }
    }
}

// MARK: - Keyboard Components

struct KeyboardRowView: View {
    let keys: [String]
    let onKeyTap: (String) -> Void
    let highlightedIndex: Int?
    // New: per-key combo display and assignment
    let comboForKey: (String) -> ActionCombo?
    let onAssignCombo: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(keys.enumerated()), id: \.element) { index, key in
                KeyButton(
                    key: key,
                    action: { onKeyTap(key) },
                    isHighlighted: highlightedIndex == index,
                    assignedCombo: comboForKey(key),
                    onAssignCombo: { onAssignCombo(key) }
                )
            }
        }
        .frame(height: 70)
    }
}

struct KeyButton: View {
    let key: String
    let action: () -> Void
    let isHighlighted: Bool
    // New: show assigned combo + allow assignment
    let assignedCombo: ActionCombo?
    let onAssignCombo: (() -> Void)?

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                Text(key)
                    .font(.system(size: 24, weight: .medium))
                    .frame(minWidth: 60, minHeight: 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(isHighlighted ? Color.accentColor.opacity(0.25) : Color(.systemGray4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .cornerRadius(8)
                // New: combo badge
                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}

struct ComboBadgeView: View {
    let combo: ActionCombo
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: combo.firstGesture.iconName)
            Image(systemName: "arrow.left.and.right").font(.caption2)
            Image(systemName: combo.secondGesture.iconName)
        }
        .font(.caption)
        .foregroundColor(.accentColor)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.7), lineWidth: 1)
                .background(Color.white.opacity(0.9).cornerRadius(10))
        )
    }
}

struct SentencePredictionRowView: View {
    let predictions: [String]
    let onTap: (String) -> Void
    let highlightedIndex: Int?
    let comboForIndex: (Int) -> ActionCombo?
    let onAssignComboIndex: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(predictions.enumerated()), id: \.element) { index, prediction in
                    Button(action: { onTap(prediction) }) {
                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 4) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Text(prediction)
                                        .font(.system(size: 16, weight: .medium))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(highlightedIndex == index ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(highlightedIndex == index ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                )
                                
                                Circle()
                                    .fill(highlightedIndex == index ? Color.accentColor : Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                            if let combo = comboForIndex(index) {
                                ComboBadgeView(combo: combo)
                                    .padding(6)
                            }
                        }
                    }
                    .contextMenu {
                        Button("Assign combo") { onAssignComboIndex(index) }
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 70)
    }
}

struct SuggestionRowView: View {
    let suggestions: [String]
    let onTap: (String) -> Void
    let highlightedIndex: Int?
    let comboForIndex: (Int) -> ActionCombo?
    let onAssignComboIndex: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                    Button(action: { onTap(suggestion) }) {
                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 6) {
                                Text(suggestion)
                                    .font(.system(size: 18, weight: .medium))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(highlightedIndex == index ? Color.accentColor : Color.clear, lineWidth: 3)
                                    )
                                    .cornerRadius(20)
                                Circle()
                                    .fill(highlightedIndex == index ? Color.accentColor : Color.clear)
                                    .frame(width: 8, height: 8)
                            }
                            if let combo = comboForIndex(index) {
                                ComboBadgeView(combo: combo)
                                    .padding(6)
                            }
                        }
                    }
                    .contextMenu {
                        Button("Assign combo") { onAssignComboIndex(index) }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 70)
    }
}

struct CapsLockKeyView: View {
    @Binding var isOn: Bool
    let assignedCombo: ActionCombo?
    let onAssignCombo: (() -> Void)?
    
    init(isOn: Binding<Bool>, assignedCombo: ActionCombo? = nil, onAssignCombo: (() -> Void)? = nil) {
        self._isOn = isOn
        self.assignedCombo = assignedCombo
        self.onAssignCombo = onAssignCombo
    }
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            ZStack(alignment: .top) {
                Image(systemName: isOn ? "capslock.fill" : "capslock")
                    .font(.system(size: 24))
                    .frame(width: 80, height: 60)
                    .background(isOn ? Color.accentColor.opacity(0.2) : Color(.systemGray4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isOn ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .cornerRadius(8)
                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}

struct ShiftKeyView: View {
    @Binding var isOn: Bool
    let assignedCombo: ActionCombo?
    let onAssignCombo: (() -> Void)?
    
    init(isOn: Binding<Bool>, assignedCombo: ActionCombo? = nil, onAssignCombo: (() -> Void)? = nil) {
        self._isOn = isOn
        self.assignedCombo = assignedCombo
        self.onAssignCombo = onAssignCombo
    }
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            ZStack(alignment: .top) {
                Image(systemName: isOn ? "shift.fill" : "shift")
                    .font(.system(size: 24))
                    .frame(width: 80, height: 60)
                    .background(isOn ? Color.accentColor.opacity(0.2) : Color(.systemGray4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isOn ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .cornerRadius(8)
                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}

struct DeleteKeyView: View {
    let onDelete: () -> Void
    let assignedCombo: ActionCombo?
    let onAssignCombo: (() -> Void)?
    
    init(onDelete: @escaping () -> Void, assignedCombo: ActionCombo? = nil, onAssignCombo: (() -> Void)? = nil) {
        self.onDelete = onDelete
        self.assignedCombo = assignedCombo
        self.onAssignCombo = onAssignCombo
    }
    
    var body: some View {
        Button(action: onDelete) {
            ZStack(alignment: .top) {
                Image(systemName: "delete.left")
                    .font(.system(size: 24))
                    .frame(width: 80, height: 60)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}

struct NumbersKeyView: View {
    let assignedCombo: ActionCombo?
    let onAssignCombo: (() -> Void)?
    
    init(assignedCombo: ActionCombo? = nil, onAssignCombo: (() -> Void)? = nil) {
        self.assignedCombo = assignedCombo
        self.onAssignCombo = onAssignCombo
    }
    
    var body: some View {
        Button(action: {
            // Numbers toggle
        }) {
            ZStack(alignment: .top) {
                Text("123")
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 100, height: 60)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}

struct SpaceKeyView: View {
    let onTap: () -> Void
    let assignedCombo: ActionCombo?
    let onAssignCombo: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                Text("space")
                    .font(.system(size: 20, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}

struct ReturnKeyView: View {
    let onTap: () -> Void
    let assignedCombo: ActionCombo?
    let onAssignCombo: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                Text("return")
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 120, height: 60)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}

// MARK: - Main Keyboard View

struct KeyboardView: View {
    @State private var text: String = ""
    @State private var suggestions: [String] = []
    @State private var shortcuts: [String: String] = [:]
    @State private var isShiftOn: Bool = false
    @State private var isCapsLockOn: Bool = false
    
    @StateObject private var predictionService = SentencePredictionService()
    
    @State private var predictionTask: Task<Void, Never>?
    @State private var isAcceptingPrediction = false
    
    private let textChecker = UITextChecker()
    
    private let topRowKeys = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let middleRowKeys = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let bottomRowKeys = ["Z", "X", "C", "V", "B", "N", "M"]
    
    @EnvironmentObject private var aacVM: AACViewModel
    @Environment(AppStateManager.self) private var appState
    
    // Combo assignment for Space action (demo)
@State private var spaceCombo: ActionCombo?
@State private var showingSpacePicker = false
// Per-key combo assignment
@State private var showingKeyComboPicker = false
@State private var pickerSelectedCombo: ActionCombo?
@State private var keyToAssign: String?
@State private var keyToAssignActionId: Int?
@State private var keyboardCombosByActionId: [Int: ActionCombo] = [:]
    
    private var isUppercase: Bool { isCapsLockOn || isShiftOn }
    private var displayedTopRowKeys: [String] {
        isUppercase ? topRowKeys : topRowKeys.map { $0.lowercased() }
    }
    private var displayedMiddleRowKeys: [String] {
        isUppercase ? middleRowKeys : middleRowKeys.map { $0.lowercased() }
    }
    private var displayedBottomRowKeys: [String] {
        isUppercase ? bottomRowKeys : bottomRowKeys.map { $0.lowercased() }
    }
    
    private enum ScanGroup: CaseIterable { case sentencePredictions, suggestions, top, middle, bottom, function }
    @State private var scanningEnabled = true
    @State private var scanInterval: Double = 1.2
    @State private var scanGroup: ScanGroup = .sentencePredictions
    @State private var scanIndex: Int = 0
    @State private var timer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()
    
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Invisible InformationView to keep camera/gesture pipeline alive
                InformationView()
                    .environmentObject(aacVM)
                    .environment(appState)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .allowsHitTesting(false)
                
                // Keyboard only UI
                HStack(spacing: 16) {
                    VStack(spacing: 0) {
                        textInputView
                            .frame(height: geometry.size.height * 0.2)

                        sentencePredictionsView
                            .frame(height: 80)

                        suggestionsView
                            .frame(height: 70)

                        // Simple controls to assign a keyboard combo (demo: Space)
                        HStack {
                            Button("Assign Space Combo") {
                                showingSpacePicker = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 20)

                        keyboardLayoutView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            loadShortcuts()
            // Ensure AACViewModel loads keyboard-specific combos
            aacVM.setCurrentMenu(.keyboard)
            // Route keyboard menu combo matches directly to action handler
            aacVM.onMenuComboMatched = { menuName, _, actionId in
                guard menuName == "keyboard" else { return }
                handleKeyboardCombo(actionId: actionId)
            }
            
            // Load saved Space combo (actionId: 1) if present
            let combos = aacVM.getCombosForMenu(.keyboard)
            if let (combo, _) = combos.first(where: { $0.value == 1 }) {
                spaceCombo = combo
            }
            // Generate default combos to fill missing actions, then refresh
            generateDefaultKeyboardCombos()
            // Refresh per-key combos
            refreshKeyboardMenuCombos()
        }
        .onDisappear {
            predictionService.cancelPredictionIfNeeded()
            // Clear handler to avoid stale references when view disappears
            aacVM.onMenuComboMatched = nil
        }
        .onReceive(timer) { _ in
            if scanningEnabled { advanceScan() }
        }
        // Note: keyboard combos are handled via aacVM.onMenuComboMatched above
        // Show the shared ComboPicker to bind a two-gesture combo to Space
        .sheet(isPresented: $showingSpacePicker) {
            ComboPickerView(selectedCombo: $spaceCombo) { combo in
                aacVM.assignComboToMenu(combo, menu: .keyboard, actionId: 1)
                spaceCombo = combo
            }
        }
        .sheet(isPresented: $showingKeyComboPicker) {
            ComboPickerView(selectedCombo: $pickerSelectedCombo) { combo in
                if let key = keyToAssign {
                    var actionId = keyboardActionId(forKey: key)
                    if key.hasPrefix("prediction:"),
                       let idxString = key.split(separator: ":").last,
                       let idx = Int(idxString) {
                        actionId = 500 + idx
                    } else if key.hasPrefix("suggestion:"),
                              let idxString = key.split(separator: ":").last,
                              let idx = Int(idxString) {
                        actionId = 400 + idx
                    }
                    aacVM.assignComboToMenu(combo, menu: .keyboard, actionId: actionId)
                    refreshKeyboardMenuCombos()
                } else if let actionId = keyToAssignActionId {
                    aacVM.assignComboToMenu(combo, menu: .keyboard, actionId: actionId)
                    refreshKeyboardMenuCombos()
                }
                keyToAssign = nil
                keyToAssignActionId = nil
            }
        }
    }
    
    private var textInputView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Type your message:")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                if !predictionService.inlinePrediction.isEmpty {
                    Button("Accept") {
                        acceptInlinePrediction()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
                    .contextMenu {
                        Button("Assign combo") {
                            keyToAssignActionId = 1007
                            showingKeyComboPicker = true
                        }
                    }
                    if let combo = assignedCombo(forKey: "accept") {
                        ComboBadgeView(combo: combo)
                            .padding(.leading, 6)
                    }
                }
            }
            ScrollView {
                InlineTextFieldWithPrediction(
                    text: $text,
                    prediction: predictionService.inlinePrediction,
                    onAcceptPrediction: acceptInlinePrediction
                )
            }
        }
        .padding(.top, 20)
        .onChange(of: text) { newValue in
            onTextChanged(newValue)
        }
    }
    
    private var sentencePredictionsView: some View {
        VStack(spacing: 0) {
            if !predictionService.sentencePredictions.isEmpty {
                HStack {
                    Image(systemName: predictionService.isModelAvailable ? "wand.and.stars" : "lightbulb")
                        .foregroundColor(predictionService.isModelAvailable ? .accentColor : .orange)
                    Text(predictionService.isModelAvailable ? "Smart Completions:" : "Text Completions:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if !predictionService.inlinePrediction.isEmpty {
                            Text("• Inline suggestion available")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        if !predictionService.debugInfo.isEmpty {
                            Text(predictionService.debugInfo)
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.bottom, 8)
                SentencePredictionRowView(
                    predictions: predictionService.sentencePredictions,
                    onTap: applySentencePrediction,
                    highlightedIndex: scanGroup == .sentencePredictions ? scanIndex : nil,
                    comboForIndex: { assignedComboForPrediction(index: $0) },
                    onAssignComboIndex: { idx in
                        keyToAssign = "prediction:\(idx)"
                        showingKeyComboPicker = true
                    }
                )
            } else {
                let wordCount = countWords(in: text)
                let minWords = 1
                let remaining = max(minWords - wordCount, 0)
                VStack {
                    HStack {
                        Image(systemName: predictionService.isModelAvailable ? "wand.and.stars" : "lightbulb")
                            .foregroundColor(.secondary)
                        Text(predictionService.isModelAvailable ? "Smart Completions:" : "Text Completions:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    if !predictionService.inlinePrediction.isEmpty {
                        Text("Double-tap the text field or tap 'Accept' to use the inline suggestion")
                            .font(.system(size: 12))
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if wordCount > 0 && wordCount < minWords {
                        Text("Type \(remaining) more word\(remaining == 1 ? "" : "s") for suggestions")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if !predictionService.isModelAvailable && wordCount == 0 {
                        Text("Apple Intelligence unavailable - using basic predictions")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !predictionService.debugInfo.isEmpty {
                        Text(predictionService.debugInfo)
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.bottom, 8)
                Rectangle().fill(Color.clear).frame(height: 70)
            }
        }
    }
    
    private var suggestionsView: some View {
        VStack(spacing: 0) {
            if !suggestions.isEmpty {
                Text("Word Suggestions:")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                SuggestionRowView(
                    suggestions: suggestions,
                    onTap: applySuggestion,
                    highlightedIndex: scanGroup == .suggestions ? scanIndex : nil,
                    comboForIndex: { assignedComboForSuggestion(index: $0) },
                    onAssignComboIndex: { idx in
                        keyToAssign = "suggestion:\(idx)"
                        showingKeyComboPicker = true
                    }
                )
            } else {
                Rectangle().fill(Color.clear).frame(height: 70)
            }
        }
    }

    private var keyboardLayoutView: some View {
    VStack(spacing: 20) {
        Spacer()
        
        KeyboardRowView(
            keys: displayedTopRowKeys,
            onKeyTap: appendText,
            highlightedIndex: scanGroup == .top ? scanIndex : nil,
            comboForKey: { assignedCombo(forKey: $0) },
            onAssignCombo: { key in
                keyToAssign = key
                showingKeyComboPicker = true
            }
        )
        
        HStack(spacing: 12) {
            Spacer().frame(width: 30)
            KeyboardRowView(
                keys: displayedMiddleRowKeys,
                onKeyTap: appendText,
                highlightedIndex: scanGroup == .middle ? scanIndex : nil,
                comboForKey: { assignedCombo(forKey: $0) },
                onAssignCombo: { key in
                    keyToAssign = key
                    showingKeyComboPicker = true
                }
            )
            Spacer().frame(width: 30)
        }
        
        HStack(spacing: 12) {
            CapsLockKeyView(
                isOn: $isCapsLockOn,
                assignedCombo: assignedCombo(forKey: "capslock"),
                onAssignCombo: {
                    keyToAssign = "capslock"
                    showingKeyComboPicker = true
                }
            )
            ShiftKeyView(
                isOn: $isShiftOn,
                assignedCombo: assignedCombo(forKey: "shift"),
                onAssignCombo: {
                    keyToAssign = "shift"
                    showingKeyComboPicker = true
                }
            )
            KeyboardRowView(
                keys: displayedBottomRowKeys,
                onKeyTap: appendText,
                highlightedIndex: scanGroup == .bottom ? scanIndex : nil,
                comboForKey: { assignedCombo(forKey: $0) },
                onAssignCombo: { key in
                    keyToAssign = key
                    showingKeyComboPicker = true
                }
            )
            DeleteKeyView(
                onDelete: {
                    if !text.isEmpty { text.removeLast() }
                },
                assignedCombo: assignedCombo(forKey: "delete"),
                onAssignCombo: {
                    keyToAssign = "delete"
                    showingKeyComboPicker = true
                }
            )
        }
        
        HStack(spacing: 12) {
            NumbersKeyView(
                assignedCombo: assignedCombo(forKey: "123"),
                onAssignCombo: {
                    keyToAssign = "123"
                    showingKeyComboPicker = true
                }
            )
            SpaceKeyView(
                onTap: { appendText(" ") },
                assignedCombo: assignedCombo(forKey: "space"),
                onAssignCombo: {
                    keyToAssign = "space"
                    showingKeyComboPicker = true
                }
            )
            ReturnKeyView(
                onTap: { appendText("\n") },
                assignedCombo: assignedCombo(forKey: "return"),
                onAssignCombo: {
                    keyToAssign = "return"
                    showingKeyComboPicker = true
                }
            )
        }
        
        Spacer()
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 20)
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    )
    .padding(.bottom, 20)
}
    
    private func onTextChanged(_ newValue: String) {
        checkForShortcuts(in: newValue)
        updateSuggestions(for: newValue)
        predictionTask?.cancel()
        predictionTask = Task {
            if predictionService.isModelAvailable {
                await predictionService.generateSentencePredictions(for: newValue)
            } else {
                await predictionService.generateFallbackPredictions(for: newValue)
            }
        }
    }
    
    private func acceptInlinePrediction() {
        guard !predictionService.inlinePrediction.isEmpty else { return }
        
        let predictionToAdd = predictionService.inlinePrediction
        isAcceptingPrediction = true
        
        Task {
            await MainActor.run {
                predictionService.inlinePrediction = ""
                predictionService.sentencePredictions = []
            }
        }
        
        text += predictionToAdd
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAcceptingPrediction = false
        }
    }
    
    private func countWords(in text: String) -> Int {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return 0 }
        
        let words = trimmedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return words.count
    }
    
    private func appendText(_ string: String) {
        text += string
        if isShiftOn && !isCapsLockOn {
            isShiftOn = false
        }
    }
    
    private func applySentencePrediction(_ prediction: String) {
        isAcceptingPrediction = true
        
        Task {
            await MainActor.run {
                predictionService.sentencePredictions = []
                predictionService.inlinePrediction = ""
            }
        }
        
        if text.hasSuffix(" ") {
            text += prediction
        } else {
            text += " " + prediction
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAcceptingPrediction = false
        }
    }
    
    private func applySuggestion(_ suggestion: String) {
        guard let lastWordRange = findLastWordRange() else { return }
        
        let nsRange = NSRange(lastWordRange, in: text)
        let nsString = text as NSString
        text = nsString.replacingCharacters(in: nsRange, with: suggestion)
        
        suggestions = []
    }
    
    private func findLastWordRange() -> Range<String.Index>? {
        if text.isEmpty {
            return nil
        }
        
        let lastWordStartIndex = text.lastIndex(where: { $0 == " " || $0 == "\n" })
        
        if lastWordStartIndex == nil {
            return text.startIndex..<text.endIndex
        }
        
        let startIndex = text.index(after: lastWordStartIndex!)
        
        return startIndex..<text.endIndex
    }
    
    private func updateSuggestions(for text: String) {
        guard !self.text.isEmpty else {
            suggestions = []
            return
        }
        
        guard let lastWordRange = findLastWordRange() else {
            suggestions = []
            return
        }
        
        let lastWord = String(self.text[lastWordRange])
        
        guard lastWord.count >= 2 else {
            suggestions = []
            return
        }
        
        let nsRange = NSRange(location: 0, length: lastWord.utf16.count)
        let completions = textChecker.completions(forPartialWordRange: nsRange,
                                                 in: lastWord,
                                                 language: "en_US") ?? []
        
        suggestions = Array(completions.prefix(5))
    }
    
    private func loadShortcuts() {
        shortcuts = [
            "omw": "On my way!",
            "brb": "Be right back",
            "ttyl": "Talk to you later",
            "ty": "Thank you",
            "np": "No problem"
        ]
    }
    
    private func checkForShortcuts(in newText: String) {
        guard let lastWordRange = findLastWordRange() else { return }
        let lastWord = String(text[lastWordRange])
        
        if let replacement = shortcuts[lastWord], lastWord != replacement {
            if text.hasSuffix(" \(lastWord)") || text == lastWord {
                let nsRange = NSRange(lastWordRange, in: text)
                let nsString = text as NSString
                text = nsString.replacingCharacters(in: nsRange, with: replacement)
            }
        }
    }

    private func advanceScan() {
        let count = groupCount(for: scanGroup)
        if count == 0 {
            moveToNextAvailableGroup()
            return
        }
        let next = scanIndex + 1
        if next >= count {
            scanIndex = 0
            scanGroup = nextGroup(after: scanGroup)
            if groupCount(for: scanGroup) == 0 {
                moveToNextAvailableGroup()
            }
        } else {
            scanIndex = next
        }
    }

    private func groupCount(for group: ScanGroup) -> Int {
        switch group {
        case .sentencePredictions: return predictionService.sentencePredictions.count
        case .suggestions: return suggestions.count
        case .top: return topRowKeys.count
        case .middle: return middleRowKeys.count
        case .bottom: return bottomRowKeys.count
        case .function: return 3
        }
    }

    private func nextGroup(after group: ScanGroup) -> ScanGroup {
        switch group {
        case .sentencePredictions: return .suggestions
        case .suggestions: return .top
        case .top: return .middle
        case .middle: return .bottom
        case .bottom: return .function
        case .function: return .sentencePredictions
        }
    }

    private func moveToNextAvailableGroup() {
        var candidate = nextGroup(after: scanGroup)
        var tries = 0
        while groupCount(for: candidate) == 0 && tries < ScanGroup.allCases.count {
            candidate = nextGroup(after: candidate)
            tries += 1
        }
        scanGroup = candidate
        scanIndex = 0
    }
    
    // Interpret two-gesture combos for keyboard control
    private func handleComboControl(first: GestureType, second: GestureType) {
        let pair = (first, second)
        print("[KeyboardView] combo:", pair, "state before -> group:", scanGroup, "index:", scanIndex)
        switch pair {
        case (.lookRight, .lookRight):
            let count = groupCount(for: scanGroup)
            print("[KeyboardView] action: next item, count =", count)
            guard count > 0 else { return }
            scanIndex = min(scanIndex + 1, count - 1)
            
        case (.lookLeft, .lookLeft):
            let count = groupCount(for: scanGroup)
            print("[KeyboardView] action: previous item, count =", count)
            guard count > 0 else { return }
            scanIndex = max(scanIndex - 1, 0)
            
        case (.lookDown, .lookDown):
            print("[KeyboardView] action: next group (", scanGroup, "->", nextGroup(after: scanGroup), ")")
            scanGroup = nextGroup(after: scanGroup)
            scanIndex = 0
            
        case (.lookUp, .lookUp):
            print("[KeyboardView] action: previous group (", scanGroup, "->", prevGroup(before: scanGroup), ")")
            scanGroup = prevGroup(before: scanGroup)
            scanIndex = 0
            
        case (.smile, .smile):
            print("[KeyboardView] action: activate current selection")
            activateCurrentSelection()
            
        case (.raiseEyebrows, .smile):
            print("[KeyboardView] action: accept inline prediction")
            acceptInlinePrediction()
            
        default:
            print("[KeyboardView] action: no-op for pair")
            break
        }
        print("[KeyboardView] state: group =", scanGroup, "index =", scanIndex)
    }
    
    private func activateCurrentSelection() {
        switch scanGroup {
        case .top:
            guard displayedTopRowKeys.indices.contains(scanIndex) else { return }
            appendText(displayedTopRowKeys[scanIndex])
        case .middle:
            guard displayedMiddleRowKeys.indices.contains(scanIndex) else { return }
            appendText(displayedMiddleRowKeys[scanIndex])
        case .bottom:
            guard displayedBottomRowKeys.indices.contains(scanIndex) else { return }
            appendText(displayedBottomRowKeys[scanIndex])
        case .suggestions:
            guard suggestions.indices.contains(scanIndex) else { return }
            applySuggestion(suggestions[scanIndex])
        case .sentencePredictions:
            guard predictionService.sentencePredictions.indices.contains(scanIndex) else { return }
            applySentencePrediction(predictionService.sentencePredictions[scanIndex])
        case .function:
            switch scanIndex {
            case 0: // "123" (numbers) — no-op for now
                break
            case 1: // space
                appendText(" ")
            case 2: // return
                appendText("\n")
            default:
                break
            }
        }
    }
    
    // Find assigned combo for a specific key
    private func assignedCombo(forKey key: String) -> ActionCombo? {
        let id = keyboardActionId(forKey: key)
        return keyboardCombosByActionId[id]
    }

    // Helper: map suggestion index to actionId
    private func suggestionActionId(forIndex index: Int) -> Int { 400 + index }

    // Helper: map prediction index to actionId
    private func predictionActionId(forIndex index: Int) -> Int { 500 + index }

    // Find assigned combo for a prediction index
    private func assignedComboForPrediction(index: Int) -> ActionCombo? {
        return keyboardCombosByActionId[predictionActionId(forIndex: index)]
    }
    
    // Find assigned combo for a suggestion index
    private func assignedComboForSuggestion(index: Int) -> ActionCombo? {
        return keyboardCombosByActionId[suggestionActionId(forIndex: index)]
    }

    // Refresh menu combos from AACViewModel
    private func refreshKeyboardMenuCombos() {
        let map = aacVM.getCombosForMenu(.keyboard) // [ActionCombo: Int]
        var inverted: [Int: ActionCombo] = [:]
        for (combo, actionId) in map {
            inverted[actionId] = combo
        }
        keyboardCombosByActionId = inverted
    }
    
    // Auto-generate and assign combos for keyboard menu (preserves existing, fills missing)
    private func generateDefaultKeyboardCombos() {
        // Existing menu-specific assignments
        let existingMap = aacVM.getCombosForMenu(.keyboard) // [ActionCombo: Int]
        var assignedActionIds = Set(existingMap.values)

        // Source combos from data layer
        let allCombos = aacVM.fetchAllActionCombos()

        // Reserved combos should not be used for keyboard keys
        func isReservedCombo(_ combo: ActionCombo) -> Bool {
            if let prev = aacVM.settings.navPrevCombo,
               combo.firstGesture == prev.0 && combo.secondGesture == prev.1 { return true }
            if let next = aacVM.settings.navNextCombo,
               combo.firstGesture == next.0 && combo.secondGesture == next.1 { return true }
            if let settings = aacVM.settings.settingsCombo,
               combo.firstGesture == settings.0 && combo.secondGesture == settings.1 { return true }
            return false
        }

        // Keep only enabled, non-reserved, and not already assigned (by combo identity)
        let alreadyAssignedCombos = Set(existingMap.keys.map { $0.id })
        var candidates = allCombos.filter {
            $0.isEnabled && !isReservedCombo($0) && !alreadyAssignedCombos.contains($0.id)
        }

        // Assign combos to visible QWERTY keys (stable actionId mapping)
        let keyOrder = displayedTopRowKeys + displayedMiddleRowKeys + displayedBottomRowKeys
        for key in keyOrder {
            let actionId = keyboardActionId(forKey: key)
            guard !assignedActionIds.contains(actionId), let next = candidates.first else { continue }
            aacVM.assignComboToMenu(next, menu: .keyboard, actionId: actionId)
            assignedActionIds.insert(actionId)
            candidates.removeFirst()
            if candidates.isEmpty { break }
        }

        // Assign to function keys if still available
        let functionKeys: [Int] = [1001, 1002, 1003, 1004, 1005, 1006, 1007] // space, return, delete, caps, shift, numbers, accept inline
        for fid in functionKeys {
            guard !assignedActionIds.contains(fid), let next = candidates.first else { continue }
            aacVM.assignComboToMenu(next, menu: .keyboard, actionId: fid)
            assignedActionIds.insert(fid)
            candidates.removeFirst()
            if candidates.isEmpty { break }
        }

        // Ensure both predictions and suggestions receive combos:
        // Interleave the first few slots between suggestions and predictions
        let maxPredictionSlots = 10
        let maxSuggestionSlots = 10
        let interleaveCount = 5
        var interleavedAids: [Int] = []
        for idx in 0..<interleaveCount {
            interleavedAids.append(suggestionActionId(forIndex: idx))
            interleavedAids.append(predictionActionId(forIndex: idx))
        }
        for aid in interleavedAids {
            guard !assignedActionIds.contains(aid), let next = candidates.first else { continue }
            aacVM.assignComboToMenu(next, menu: .keyboard, actionId: aid)
            assignedActionIds.insert(aid)
            candidates.removeFirst()
            if candidates.isEmpty { break }
        }

        // Assign remaining prediction slots
        for idx in interleaveCount..<maxPredictionSlots {
            let aid = predictionActionId(forIndex: idx)
            guard !assignedActionIds.contains(aid), let next = candidates.first else { continue }
            aacVM.assignComboToMenu(next, menu: .keyboard, actionId: aid)
            assignedActionIds.insert(aid)
            candidates.removeFirst()
            if candidates.isEmpty { break }
        }

        // Assign remaining suggestion slots
        for idx in interleaveCount..<maxSuggestionSlots {
            let aid = suggestionActionId(forIndex: idx)
            guard !assignedActionIds.contains(aid), let next = candidates.first else { continue }
            aacVM.assignComboToMenu(next, menu: .keyboard, actionId: aid)
            assignedActionIds.insert(aid)
            candidates.removeFirst()
            if candidates.isEmpty { break }
        }
    }

    // ActionId mapping for keys (stable IDs across runs)
    private func keyboardActionId(forKey key: String) -> Int {
        // Letters: deterministic indices within all letter arrays
        if let idx = displayedTopRowKeys.firstIndex(of: key) {
            return 100 + idx
        }
        if let idx = displayedMiddleRowKeys.firstIndex(of: key) {
            return 200 + idx
        }
        if let idx = displayedBottomRowKeys.firstIndex(of: key) {
            return 300 + idx
        }
        // Function keys
        switch key.lowercased() {
        case "space": return 1001
        case "return": return 1002
        case "delete": return 1003
        case "capslock": return 1004
        case "shift": return 1005
        case "123": return 1006
        case "accept": return 1007
        default: break
        }
        
        // Dynamic slots: suggestion/prediction positions
        if key.lowercased().hasPrefix("suggestion:") {
            if let idxString = key.split(separator: ":").last,
               let idx = Int(idxString) {
                return suggestionActionId(forIndex: idx)
            }
        }
        if key.lowercased().hasPrefix("prediction:") {
            if let idxString = key.split(separator: ":").last,
               let idx = Int(idxString) {
                return predictionActionId(forIndex: idx)
            }
        }
        
        return 1999 // unknown key
    }

    // Keyboard combo actions mapped by actionId → key
    private func handleKeyboardCombo(actionId: Int) {
        switch actionId {
        // Backward compatibility for legacy IDs
        case 1:
            appendText(" ")    // Space
        case 2:
            if !text.isEmpty { text.removeLast() } // Backspace (optional future use)
        case 3:
            appendText("\n")   // Return (optional future use)
            
        // New function keys
        case 1001:
            appendText(" ")
        case 1002:
            appendText("\n")
        case 1003:
            if !text.isEmpty { text.removeLast() }
        case 1004:
            isCapsLockOn.toggle()
        case 1005:
            isShiftOn.toggle()
        case 1006:
            // Numbers toggle — currently no-op UI
            // Hook up to a numbers keyboard when available
            break
        case 1007:
            // Accept inline suggestion if available
            if !predictionService.inlinePrediction.isEmpty {
                acceptInlinePrediction()
            }
            
        default:
            // Suggestions: 400...499 → apply suggestion at position
            if (400...499).contains(actionId) {
                let idx = actionId - 400
                if suggestions.indices.contains(idx) {
                    applySuggestion(suggestions[idx])
                }
                return
            }
            // Predictions: 500...599 → apply smart completion at position
            if (500...599).contains(actionId) {
                let idx = actionId - 500
                if predictionService.sentencePredictions.indices.contains(idx) {
                    applySentencePrediction(predictionService.sentencePredictions[idx])
                }
                return
            }
            // Letter keys
            if (100...199).contains(actionId) {
                let idx = actionId - 100
                if displayedTopRowKeys.indices.contains(idx) {
                    appendText(displayedTopRowKeys[idx])
                }
            } else if (200...299).contains(actionId) {
                let idx = actionId - 200
                if displayedMiddleRowKeys.indices.contains(idx) {
                    appendText(displayedMiddleRowKeys[idx])
                }
            } else if (300...399).contains(actionId) {
                let idx = actionId - 300
                if displayedBottomRowKeys.indices.contains(idx) {
                    appendText(displayedBottomRowKeys[idx])
                }
            }
        }
    }
    
    private func prevGroup(before group: ScanGroup) -> ScanGroup {
        switch group {
        case .sentencePredictions: return .function
        case .suggestions: return .sentencePredictions
        case .top: return .suggestions
        case .middle: return .top
        case .bottom: return .middle
        case .function: return .bottom
        }
    }
}

#Preview {
    KeyboardView()
    // ... existing code ...
}
