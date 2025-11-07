//
//  KeyboardUIView.swift
//  eyespeak
//
//  Recreated to mirror the handed-off Figma screen.
//

import SwiftUI

private enum Palette {
    static let megaphoneBlue = Color(red: 88/255, green: 108/255, blue: 157/255)
    static let chipSurface = Color(red: 0.91, green: 0.93, blue: 0.96)
    static let keyShadow = Color.black.opacity(0.08)
    static let accentPink = Color(red: 0.96, green: 0.47, blue: 0.78)
    static let background = Color(red: 0.95, green: 0.95, blue: 0.95)
}

struct KeyboardUIView: View {

    private let topRow: [KeyboardKey] = "qwertyuiop".map { KeyboardKey(label: String($0)) }
    private let middleRow: [KeyboardKey] = "asdfghjkl".map { KeyboardKey(label: String($0)) }
    private let bottomRow: [KeyboardKey] = "zxcvbnm".map { KeyboardKey(label: String($0)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerCTA

            VStack(spacing: 12) {
                displayArea
                suggestionsRow
            }

            keyboardPanel
        }
        .padding(24)
        .background(Palette.background)
    }
}

// MARK: - Header & Display

private extension KeyboardUIView {
    var headerCTA: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 12) {
                Capsule()
                    .fill(Palette.megaphoneBlue)
                    .frame(width: 74, height: 18)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    )

                Button(action: {}) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ADD WORD")
                        Text("TO BOARD")
                    }
                    .font(AppFont.Montserrat.semibold(14))
                    .foregroundColor(.white)
                    .frame(width: 150, height: 88, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Palette.megaphoneBlue)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    var displayArea: some View {
        VStack(spacing: 0) {
            diagonalAccent

            HStack {
                Text(displayLeadingText)
                    .font(AppFont.Montserrat.semibold(40))
                    .foregroundColor(.black)

                Text(displayTrailingText)
                    .font(AppFont.Montserrat.medium(40))
                    .foregroundColor(Color.black.opacity(0.25))

                Spacer()

                Image(systemName: "return.right")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.2))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)

            diagonalAccent
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: Palette.keyShadow.opacity(0.35), radius: 16, x: 0, y: 6)
        )
    }

    var displayLeadingText: String { "Can I " }
    var displayTrailingText: String { "eat a dozen of donuts" }

    var diagonalAccent: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Palette.accentPink.opacity(0.25), Palette.accentPink.opacity(0.65)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 8)
    }
}

// MARK: - Suggestions

private extension KeyboardUIView {
    var suggestionsRow: some View {
        HStack(spacing: 14) {
            SuggestionTile(title: "drink")
            SuggestionTile(title: "eat")
            SuggestionTile(title: "drive")
        }
    }
}

// MARK: - Keyboard

private extension KeyboardUIView {
    var keyboardPanel: some View {
        VStack(spacing: 12) {
            diagonalAccent

            VStack(spacing: 10) {
                keyboardRow(keys: topRow)
                keyboardRow(keys: middleRow, horizontalInset: 18)
                bottomRowView
                systemRow
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Palette.keyShadow.opacity(0.25), radius: 12, x: 0, y: 6)
        )
    }

    func keyboardRow(keys: [KeyboardKey], horizontalInset: CGFloat = 0) -> some View {
        HStack(spacing: 8) {
            ForEach(keys) { key in
                KeyButton(key: key)
            }
        }
        .padding(.horizontal, horizontalInset)
    }

    var bottomRowView: some View {
        HStack(spacing: 8) {
            SpecialKeyButton(key: KeyboardKey(label: "shift", icon: "shift.fill"))
            ForEach(bottomRow) { key in
                KeyButton(key: key)
            }
            SpecialKeyButton(key: KeyboardKey(label: "delete", icon: "delete.left.fill"))
        }
    }

    var systemRow: some View {
        HStack(spacing: 8) {
            SpecialKeyButton(key: KeyboardKey(label: "123"))
            SpecialKeyButton(key: KeyboardKey(label: "globe", icon: "globe"))
            SpaceKey()
            SpecialKeyButton(
                key: KeyboardKey(label: "speak", icon: "speaker.wave.2.fill"),
                background: Palette.megaphoneBlue,
                foreground: .white
            )
        }
    }
}

// MARK: - Reusable Views

private struct SuggestionTile: View {
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(Palette.megaphoneBlue.opacity(0.7))

            Text(title.uppercased())
                .font(AppFont.Montserrat.medium(14))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Palette.megaphoneBlue.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

private struct KeyButton: View {
    let key: KeyboardKey

    var body: some View {
        Text(key.label.uppercased())
            .font(AppFont.Montserrat.medium(18))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Palette.keyShadow, radius: 1, x: 0, y: 1)
            )
    }
}

private struct SpecialKeyButton: View {
    let key: KeyboardKey
    var background: Color = Color.white
    var foreground: Color = .primary

    var body: some View {
        HStack(spacing: 6) {
            if let icon = key.icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
            }

            if key.icon == nil || key.label != key.icon {
                Text(key.displayText.uppercased())
                    .font(AppFont.Montserrat.medium(16))
            }
        }
        .foregroundColor(foreground)
        .frame(minWidth: key.minWidth, maxHeight: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(background)
                .shadow(color: Palette.keyShadow, radius: 1, x: 0, y: 1)
        )
    }
}

private struct SpaceKey: View {
    var body: some View {
        Text("space")
            .font(AppFont.Montserrat.medium(16))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Palette.keyShadow, radius: 1, x: 0, y: 1)
            )
    }
}

private struct KeyboardKey: Identifiable {
    let id = UUID()
    let label: String
    var icon: String? = nil
    var minWidth: CGFloat {
        switch label.lowercased() {
        case "shift", "delete":
            return 64
        case "123", "globe":
            return 62
        case "speak":
            return 82
        default:
            return 0
        }
    }

    var displayText: String {
        switch label.lowercased() {
        case "globe":
            return ""
        case "speak":
            return ""
        default:
            return label
        }
    }
}

#Preview {
    KeyboardUIView()
        .padding()
        .background(Color.gray.opacity(0.1))
}
