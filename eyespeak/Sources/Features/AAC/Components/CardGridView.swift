//
//  CardGridView.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import SwiftUI
import SwiftData

struct CardGridView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("EyeSpeak")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    viewModel.setupManagers()
                }
        }
        .padding()
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            gestureInputSection
            gridSection
            bottomToolbar
        }
    }
    
    @ViewBuilder
    private var gestureInputSection: some View {
        if viewModel.isGestureMode {
            GestureInputPanel(gestureManager: viewModel.gestureInputManagerInstance)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private var gridSection: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: viewModel.columns),
                spacing: 12
            ) {
                ForEach(viewModel.positions) { position in
                    CardCell(
                        position: position,
                        dataManager: viewModel.dataManagerInstance,
                        columns: viewModel.columns,
                        isHighlighted: viewModel.selectedPosition?.id == position.id,
                        viewModel:viewModel
                    )
                }
            }
            .padding()
        }
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            gestureButton
            Spacer()
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
    
}

#Preview("Default") {
    let container = AACDIContainer.makePreviewContainer()
    return CardGridView()
        .environmentObject(AACDIContainer.shared.makeAACViewModel())
        .modelContainer(container)
}
