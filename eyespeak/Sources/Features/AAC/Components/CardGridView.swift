//
//  CardGridView.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import SwiftData
import SwiftUI

struct CardGridView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    @AppStorage("fontScale") private var fontScaleRaw: String = "medium"

    var body: some View {
        gridSection
            .onAppear {
                viewModel.setupManagers()
            }

    }


    private var gridSection: some View {
        HStack(alignment: .center, spacing: 15) {
            VStack(spacing: 8) {
                comboBadge(for: viewModel.settings.navPrevCombo)
                Button(action: { viewModel.goToPreviousPage() }) {
                    Image("arrow")
                        .renderingMode(.template)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(
                            .primary.opacity(
                                viewModel.currentPage == 0 ? 0.2 : 0.9
                            )
                        )
                        .rotationEffect(.degrees(180))
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
                .disabled(viewModel.currentPage == 0)
            }
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 8),
                    count: viewModel.columns
                ),
                spacing: 8
            ) {
                ForEach(viewModel.currentPagePositions) { position in
                    CardCell(
                        position: position,
                        dataManager: viewModel.dataManagerInstance,
                        columns: viewModel.columns,
                        isHighlighted: viewModel.selectedPosition?.id
                            == position.id,
                        viewModel: viewModel
                    )
                }
            }
            .frame(maxWidth: .infinity)  // <- important: grid expands to take remaining width
            .layoutPriority(1)  // <- prefer grid over arrows when sizing

            VStack(spacing: 8) {
                comboBadge(for: viewModel.settings.navNextCombo)
                Button(action: { viewModel.goToNextPage() }) {
                    Image("arrow")
                        .renderingMode(.template)
                        .foregroundColor(
                            .primary.opacity(
                                viewModel.currentPage + 1
                                    >= viewModel.totalPages ? 0.2 : 0.9
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
                .disabled(viewModel.currentPage + 1 >= viewModel.totalPages)
            }
        }
        .padding(.horizontal)
    }

    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            gestureButton
            Spacer()
            pagerControls
            infoButton
            settingsButton
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    private var gestureButton: some View {
        Button {
            viewModel.toggleGestureMode()
        } label: {
            Image(systemName: viewModel.isGestureMode ? "eye.fill" : "eye")
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(viewModel.isGestureMode ? Color.green : Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }

    private var settingsButton: some View {
        Button {
            viewModel.showSettings()
        } label: {
            Image(systemName: "gear")
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .clipShape(Circle())
        }
    }

    private var pagerControls: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.goToPreviousPage() }) {
                Image(systemName: "chevron.left")
            }
            .disabled(viewModel.currentPage == 0)

            Text("\(viewModel.currentPage + 1)/\(viewModel.totalPages)")
                .font(.subheadline)
                .monospacedDigit()

            Button(action: { viewModel.goToNextPage() }) {
                Image(systemName: "chevron.right")
            }
            .disabled(viewModel.currentPage + 1 >= viewModel.totalPages)
        }
    }

    private var navigationCheatSheet: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                Text("Previous")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let prevCombo = viewModel.settings.navPrevCombo {
                Text("\(prevCombo.0.displayName) + \(prevCombo.1.displayName)")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }

            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                Text("Next")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let nextCombo = viewModel.settings.navNextCombo {
                Text("\(nextCombo.0.displayName) + \(nextCombo.1.displayName)")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color(uiColor: .systemBackground).opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 2)
    }

    // MARK: - Side combo badge
    private func comboBadge(for combo: (GestureType, GestureType)?) -> some View
    {
        Group {
            if let c = combo {
                HStack(spacing: 6) {
                    Image(systemName: c.0.iconName)
                        .font(.caption.weight(.semibold))
                    Text("+")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: c.1.iconName)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color(uiColor: .systemBackground))
                )
                // 🔹 Add border with 72.28 corner radius
                .overlay(
                    RoundedRectangle(cornerRadius: 72.28)
                        .stroke(Color.mellowBlue, lineWidth: 1)
                )
            }
        }
    }

    private var infoButton: some View {
        Button {
            viewModel.showComboInfo()
        } label: {
            Image(systemName: "info.circle")
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .clipShape(Circle())
        }
    }

}

#Preview("Default") {
    let container = AACDIContainer.makePreviewContainer()
    let vm = AACViewModel(
        modelContext: container.mainContext,
        dataManager: DataManager(modelContext: container.mainContext),
        gestureInputManager: GestureInputManager(),
        speechService: SpeechService.shared
    )
    return CardGridView()
        .environmentObject(vm)
        .modelContainer(container)
}
