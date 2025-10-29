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
    @StateObject private var viewModel: AACViewModel
    
    init(container: AACDIContainer = AACDIContainer.shared) {
        _viewModel = StateObject(wrappedValue: container.makeAACViewModel())
    }

    var body: some View {
        GeometryReader { geo in
            HStack {
                InformationView()
                    .frame(width: geo.size.width * 0.2)
                Spacer()
                CardGridView()
                    .frame( width: geo.size.width * 0.7)

            }
            .padding(.horizontal)
        }
        // 👇 inject into environment so child views can use @EnvironmentObject
        .environmentObject(viewModel)
    }
}


#Preview {
    let container = AACDIContainer.makePreviewContainer()
    return AACView(container: AACDIContainer.shared)
        .modelContainer(container)
}
