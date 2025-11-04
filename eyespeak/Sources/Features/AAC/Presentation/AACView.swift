//
//  AACView.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import SwiftData
import SwiftUI

struct AACView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateManager.self) private var appState
    @StateObject private var viewModel: AACViewModel
    
    init(container: AACDIContainer = AACDIContainer.shared) {
        _viewModel = StateObject(wrappedValue: container.makeAACViewModel())
    }

    var body: some View {
        GeometryReader { geo in
            HStack (alignment: .center) {
                InformationView()
                    .padding()
                    .frame(width: geo.size.width * 0.25, height: geo.size.height)
                Spacer()
                CardGridView()
                    .padding()
                    .frame( width: geo.size.width * 0.7, height: geo.size.height)

            }
            .padding()
        }
        // 👇 inject into environment so child views can use @EnvironmentObject
        .environmentObject(viewModel)
        .onAppear {
            // Wire up settings navigation callback
            viewModel.onNavigateToSettings = {
                appState.currentTab = .settings
            }
        }
    }
}


#Preview {
    let modelContainer = AACDIContainer.makePreviewContainer()
    let di = AACDIContainer.makePreviewDI(modelContainer: modelContainer)
    return AACView(container: di)
        .environment(AppStateManager())
        .modelContainer(modelContainer)
}
