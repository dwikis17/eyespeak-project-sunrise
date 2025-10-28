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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { viewModel.toggleGestureMode() }) {
                            Image(systemName: viewModel.isGestureMode ? "eye.fill" : "eye")
                        }
                        .accessibilityLabel("Toggle gesture mode")
                    }
                }
        }
        .padding()
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            gridSection
            bottomToolbar
        }
    }
    
    private var gridSection: some View {
        ZStack {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: viewModel.columns),
                spacing: 12
            ) {
                ForEach(viewModel.currentPagePositions) { position in
                    CardCell(
                        position: position,
                        dataManager: viewModel.dataManagerInstance,
                        columns: viewModel.columns,
                        isHighlighted: viewModel.selectedPosition?.id == position.id,
                        viewModel:viewModel
                    )
                }
            }
            
            // Overlay arrows
            HStack {
                Button(action: { viewModel.goToPreviousPage() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.primary.opacity(viewModel.currentPage == 0 ? 0.2 : 0.9))
                }
                .disabled(viewModel.currentPage == 0)
                .padding(.leading, 4)
                
                Spacer()
                
                Button(action: { viewModel.goToNextPage() }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.primary.opacity(viewModel.currentPage + 1 >= viewModel.totalPages ? 0.2 : 0.9))
                }
                .disabled(viewModel.currentPage + 1 >= viewModel.totalPages)
                .padding(.trailing, 4)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            gestureButton
            Spacer()
            pagerControls
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
    
}

#Preview("Default") {
    let container = AACDIContainer.makePreviewContainer()
    return CardGridView()
        .environmentObject(AACDIContainer.shared.makeAACViewModel())
        .modelContainer(container)
}
