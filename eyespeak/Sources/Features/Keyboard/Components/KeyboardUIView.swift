import SwiftData
import SwiftUI

private enum KeyboardActionID: Int, CaseIterable {
    case addWord = 1
    case suggestion0 = 10
    case suggestion1 = 11
    case suggestion2 = 12
    case acceptPrediction = 13
    
    case letterQ = 100
    case letterW = 101
    case letterE = 102
    case letterR = 103
    case letterT = 104
    case letterY = 105
    case letterU = 106
    case letterI = 107
    case letterO = 108
    case letterP = 109
    
    case letterA = 120
    case letterS = 121
    case letterD = 122
    case letterF = 123
    case letterG = 124
    case letterH = 125
    case letterJ = 126
    case letterK = 127
    case letterL = 128
    
    case letterZ = 140
    case letterX = 141
    case letterC = 142
    case letterV = 143
    case letterB = 144
    case letterN = 145
    case letterM = 146
    
    case delete = 200
    case speak = 201
    case shift = 202
    case space = 203
    case trash = 204
    
    static var allCases: [KeyboardActionID] {
        [
            .addWord,
            .suggestion0, .suggestion1, .suggestion2,
            .letterQ, .letterW, .letterE, .letterR, .letterT, .letterY, .letterU, .letterI, .letterO, .letterP,
            .letterA, .letterS, .letterD, .letterF, .letterG, .letterH, .letterJ, .letterK, .letterL,
            .letterZ, .letterX, .letterC, .letterV, .letterB, .letterN, .letterM,
            .delete, .speak, .shift, .space, .trash
        ]
    }
    
    var letter: String? {
        switch self {
        case .letterQ: return "q"
        case .letterW: return "w"
        case .letterE: return "e"
        case .letterR: return "r"
        case .letterT: return "t"
        case .letterY: return "y"
        case .letterU: return "u"
        case .letterI: return "i"
        case .letterO: return "o"
        case .letterP: return "p"
        case .letterA: return "a"
        case .letterS: return "s"
        case .letterD: return "d"
        case .letterF: return "f"
        case .letterG: return "g"
        case .letterH: return "h"
        case .letterJ: return "j"
        case .letterK: return "k"
        case .letterL: return "l"
        case .letterZ: return "z"
        case .letterX: return "x"
        case .letterC: return "c"
        case .letterV: return "v"
        case .letterB: return "b"
        case .letterN: return "n"
        case .letterM: return "m"
        default:
            return nil
        }
    }
    
    var suggestionIndex: Int? {
        switch self {
        case .suggestion0: return 0
        case .suggestion1: return 1
        case .suggestion2: return 2
        default:
            return nil
        }
    }
}

struct KeyboardUIView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    @StateObject private var inputViewModel = KeyboardInputViewModel()
    @State private var assignedCombos: [KeyboardActionID: ActionCombo] = [:]
    
    private let topRowLetters: [(String, KeyboardActionID)] = [
        ("q", .letterQ), ("w", .letterW), ("e", .letterE), ("r", .letterR), ("t", .letterT),
        ("y", .letterY), ("u", .letterU), ("i", .letterI), ("o", .letterO), ("p", .letterP)
    ]
    
    private let middleRowLetters: [(String, KeyboardActionID)] = [
        ("a", .letterA), ("s", .letterS), ("d", .letterD), ("f", .letterF), ("g", .letterG),
        ("h", .letterH), ("j", .letterJ), ("k", .letterK), ("l", .letterL)
    ]
    
    private let bottomRowLetters: [(String, KeyboardActionID)] = [
        ("z", .letterZ), ("x", .letterX), ("c", .letterC), ("v", .letterV),
        ("b", .letterB), ("n", .letterN), ("m", .letterM)
    ]
    
    private let suggestionActions: [KeyboardActionID] = [.suggestion0, .suggestion1, .suggestion2]
    private let predictionComboAction: KeyboardActionID = .acceptPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            addWordButton
            phraseSection
            keyboardSection
        }
        .padding(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            ensureKeyboardCombos()
        }
        .onChange(of: viewModel.menuActionTrigger) { _, trigger in
            guard let trigger,
                  trigger.menu == "keyboard",
                  let action = KeyboardActionID(rawValue: trigger.actionId) else { return }
            handleAction(action)
        }
    }
    
    private var addWordButton: some View {
        HStack(alignment: .top, spacing: 10) {
            Spacer()
            Button {
                handleAction(.addWord)
            } label: {
                if let combo = assignedCombos[.addWord] {
                    AddWordButtonView(
                        firstGesture: combo.firstGesture,
                        secondGesture: combo.secondGesture
                    )
                } else {
                    AddWordButtonView()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add word to board")
        }
        .padding(0)
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }
    
    private var phraseSection: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(alignment: .center) {
                HStack(alignment: .center, spacing: 10) {
                    let headerText: Text = {
                        if inputViewModel.primaryHeaderText.isEmpty {
                            return Text("Type Something")
                                .foregroundColor(.blueholder)
                        } else {
                            return Text(inputViewModel.primaryHeaderText)
                                .foregroundColor(.blueack)
                            + Text(inputViewModel.inlinePredictionDisplayText)
                                .foregroundColor(.blueholder)
                        }
                    }()
                    
                    headerText
                        .font(Font.custom("Montserrat", size: 64))
                    
                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            guard !inputViewModel.inlinePredictionText.isEmpty else { return }
                            handleAction(predictionComboAction)
                        } label: {
                            let combo = assignedCombos[predictionComboAction]
                            OutlineComboPill(
                                firstGesture: combo?.firstGesture ?? .lookUp,
                                secondGesture: combo?.secondGesture ?? .lookRight,
                                strokeColor: .mellowBlue,
                                background: .boneWhite,
                                iconColor: .mellowBlue
                            )
                            .opacity(inputViewModel.inlinePredictionText.isEmpty ? 0.35 : 1)
                        }
                        .buttonStyle(.plain)
                        .disabled(inputViewModel.inlinePredictionText.isEmpty)
                        .accessibilityLabel("Complete sentence")
                        .accessibilityHint("Applies the inline sentence prediction")
                    }
                    .frame(width: 60, alignment: .center)
                }
                .padding(0)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private var keyboardSection: some View {
        VStack(alignment: .trailing, spacing: 7.6044) {
            suggestionsRow
            topLetterRow
            middleLetterRow
            bottomLetterRow
            controlRow
        }
        .padding(0)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var suggestionsRow: some View {
        HStack(alignment: .center, spacing: 6.84396) {
            ForEach(Array(suggestionActions.enumerated()), id: \.element) { index, actionId in
                if index < inputViewModel.suggestions.count {
                    let word = inputViewModel.suggestions[index]
                    Button {
                        handleAction(actionId)
                    } label: {
                        if let combo = assignedCombos[actionId] {
                            CompletionKeyView(
                                title: word,
                                firstGesture: combo.firstGesture,
                                secondGesture: combo.secondGesture
                            )
                        } else {
                            CompletionKeyView(title: word)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Suggestion \(word)")
                }
            }
        }
        .padding(.horizontal, 7.6044)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var topLetterRow: some View {
        HStack(alignment: .center, spacing: 6.84396) {
            ForEach(topRowLetters, id: \.1) { descriptor in
                letterButton(for: descriptor)
            }
            
            Button {
                handleAction(.delete)
            } label: {
                if let combo = assignedCombos[.delete] {
                    DeleteKeyView(
                        firstGesture: combo.firstGesture,
                        secondGesture: combo.secondGesture
                    )
                } else {
                    DeleteKeyView()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete character")
        }
        .padding(.horizontal, 7.6044)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var middleLetterRow: some View {
        HStack(alignment: .center, spacing: 6.84396) {
            ForEach(middleRowLetters, id: \.1) { descriptor in
                letterButton(for: descriptor)
            }
            
            Button {
                handleAction(.speak)
            } label: {
                if let combo = assignedCombos[.speak] {
                    SpeakKeyView(
                        firstGesture: combo.firstGesture,
                        secondGesture: combo.secondGesture
                    )
                } else {
                    SpeakKeyView()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Speak phrase")
        }
        .padding(.horizontal, 7.6044)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    private var bottomLetterRow: some View {
        HStack(alignment: .center, spacing: 6.84396) {
            Button {
                handleAction(.shift)
            } label: {
                if let combo = assignedCombos[.shift] {
                    ShiftKeyView(
                        firstGesture: combo.firstGesture,
                        secondGesture: combo.secondGesture
                    )
                } else {
                    ShiftKeyView()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(inputViewModel.isShiftEnabled ? "Disable shift" : "Enable shift")
            
            ForEach(bottomRowLetters, id: \.1) { descriptor in
                letterButton(for: descriptor)
            }
        }
        .padding(.horizontal, 7.6044)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    private var controlRow: some View {
        HStack(alignment: .center, spacing: 6.84396) {
            Button {
                handleAction(.space)
            } label: {
                if let combo = assignedCombos[.space] {
                    SpaceKeyView(
                        firstGesture: combo.firstGesture,
                        secondGesture: combo.secondGesture
                    )
                } else {
                    SpaceKeyView()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Space")
            
            Button {
                handleAction(.trash)
            } label: {
                if let combo = assignedCombos[.trash] {
                    TrashKeyView(
                        firstGesture: combo.firstGesture,
                        secondGesture: combo.secondGesture
                    )
                } else {
                    TrashKeyView()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear message")
        }
        .padding(.horizontal, 7.6044)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    @ViewBuilder
    private func letterButton(for descriptor: (String, KeyboardActionID)) -> some View {
        let (letter, actionId) = descriptor
        Button {
            handleAction(actionId)
        } label: {
            if let combo = assignedCombos[actionId] {
                KeyView(
                    letter: inputViewModel.displayLetter(for: letter),
                    firstGesture: combo.firstGesture,
                    secondGesture: combo.secondGesture
                )
            } else {
                KeyView(letter: inputViewModel.displayLetter(for: letter))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Key \(letter.uppercased())")
        .accessibilityAddTraits(.isKeyboardKey)
    }
    
    private func handleAction(_ action: KeyboardActionID) {
        switch action {
        case .addWord:
            addCurrentPhraseToBoard()
        case .suggestion0, .suggestion1, .suggestion2:
            if let index = action.suggestionIndex {
                inputViewModel.insertSuggestion(at: index)
            }
        case .delete:
            inputViewModel.deleteLast()
        case .speak:
            inputViewModel.speakText()
        case .shift:
            inputViewModel.toggleShift()
        case .space:
            inputViewModel.addSpace()
        case .trash:
            inputViewModel.clearAll()
        case .acceptPrediction:
            inputViewModel.applySentencePrediction()
        default:
            if let letter = action.letter {
                inputViewModel.insertLetter(letter)
            }
        }
    }
    
    private func addCurrentPhraseToBoard() {
        let text = inputViewModel.primaryHeaderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let didAdd = viewModel.addCardFromKeyboard(text: text)
        if didAdd {
            inputViewModel.clearAll()
        }
    }
    
    private func ensureKeyboardCombos() {
        var existing = loadAssignedCombos()
        
        // Remove any existing assignments that conflict with global combos
        var conflictsToRemove: [KeyboardActionID] = []
        for (actionId, combo) in existing {
            if isReservedCombo(combo) {
                conflictsToRemove.append(actionId)
                // Remove the conflicting assignment from storage
                viewModel.settings.removeMenuComboAssignment(menuName: "keyboard", actionId: actionId.rawValue)
            }
        }
        for actionId in conflictsToRemove {
            existing.removeValue(forKey: actionId)
        }
        
        // Find missing actions (including those that were just removed due to conflicts)
        let missing = KeyboardActionID.allCases.filter { existing[$0] == nil }
        guard !missing.isEmpty else {
            assignedCombos = existing
            return
        }
        
        // Get available combos excluding already assigned ones and reserved global combos
        var pool = availableCombos(excluding: Set(existing.values.map(\.id)))
        for action in missing {
            guard !pool.isEmpty else { break }
            let combo = pool.removeFirst()
            viewModel.assignComboToMenu(combo, menu: .keyboard, actionId: action.rawValue)
            existing[action] = combo
        }
        assignedCombos = existing
    }
    
    private func availableCombos(excluding used: Set<UUID>) -> [ActionCombo] {
        viewModel.fetchAllActionCombos().filter { combo in
            guard !used.contains(combo.id) else { return false }
            return !isReservedCombo(combo)
        }
    }
    
    private func isReservedCombo(_ combo: ActionCombo) -> Bool {
        let settings = viewModel.settings
        // Check all global combos that work in ANY menu (from InformationView control panel)
        if let prev = settings.navPrevCombo,
           combo.firstGesture == prev.0 && combo.secondGesture == prev.1 {
            return true
        }
        if let next = settings.navNextCombo,
           combo.firstGesture == next.0 && combo.secondGesture == next.1 {
            return true
        }
        if let settingsCombo = settings.settingsCombo,
           combo.firstGesture == settingsCombo.0 && combo.secondGesture == settingsCombo.1 {
            return true
        }
        if let keyboardCombo = settings.keyboardCombo,
           combo.firstGesture == keyboardCombo.0 && combo.secondGesture == keyboardCombo.1 {
            return true
        }
        if let deleteCombo = settings.deleteCombo,
           combo.firstGesture == deleteCombo.0 && combo.secondGesture == deleteCombo.1 {
            return true
        }
        if let swapCombo = settings.swapCombo,
           combo.firstGesture == swapCombo.0 && combo.secondGesture == swapCombo.1 {
            return true
        }
        if let changeColorCombo = settings.changeColorCombo,
           combo.firstGesture == changeColorCombo.0 && combo.secondGesture == changeColorCombo.1 {
            return true
        }
        return false
    }
    
    private func loadAssignedCombos() -> [KeyboardActionID: ActionCombo] {
        var mapping: [KeyboardActionID: ActionCombo] = [:]
        let combos = viewModel.getCombosForMenu(.keyboard)
        for (combo, actionId) in combos {
            if let action = KeyboardActionID(rawValue: actionId) {
                mapping[action] = combo
            }
        }
        return mapping
    }
}

#Preview {
    let modelContainer = AACDIContainer.makePreviewContainer()
    let di = AACDIContainer.makePreviewDI(modelContainer: modelContainer)
    return KeyboardUIView()
        .environment(AppStateManager())
        .environmentObject(di.makeAACViewModel())
        .modelContainer(modelContainer)
}
