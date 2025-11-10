//
//  KeyboardView.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import SwiftUI
import SwiftData

struct KeyboardView: View {
    private enum Layout {
        static let containerWidth: CGFloat = 1366
        static let containerHeight: CGFloat = 1024
        static let horizontalPadding: CGFloat = 30
        static let verticalPadding: CGFloat = 45
        static let interItemSpacing: CGFloat = 10
        static let infoPanelWidth: CGFloat = 330
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Layout.interItemSpacing) {
            InformationView()
                .frame(width: Layout.infoPanelWidth, alignment: .top)
                .frame(maxHeight: .infinity, alignment: .top)

            RealKeyboardView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .frame(
            width: Layout.containerWidth,
            height: Layout.containerHeight,
            alignment: .bottom
        )
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
    }
}

#Preview {
    let modelContainer = AACDIContainer.makePreviewContainer()
    let di = AACDIContainer.makePreviewDI(modelContainer: modelContainer)
    return KeyboardView()
        .environmentObject(di.makeAACViewModel())
        .environment(AppStateManager())
        .modelContainer(modelContainer)
}
