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
        
      
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            gridSection
        }
    }
    
    private var gridSection: some View {
        ZStack {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: viewModel.columns),
                spacing: 8
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
            
            // Navigation cheat sheet overlay
            if viewModel.isGestureMode {
                VStack {
                    HStack {
                        Spacer()
                        navigationCheatSheet
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
        }
        .padding(8)
        .padding(.top, 10)
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
    return CardGridView()
        .environmentObject(AACDIContainer.shared.makeAACViewModel())
        .modelContainer(container)
}
