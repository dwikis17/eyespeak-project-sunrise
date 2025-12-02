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
        
        static func scaleFactor(for size: CGSize) -> CGFloat {
            guard size.width > 0 && size.height > 0 else { return 1 }
            let widthScale = size.width / containerWidth
            let heightScale = size.height / containerHeight
            return min(min(widthScale, heightScale), 1)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = Layout.scaleFactor(for: proxy.size)
            let scaledWidth = Layout.containerWidth * scale
            let scaledHeight = Layout.containerHeight * scale
            ZStack(alignment: .bottom) {
                Color(red: 0.95, green: 0.95, blue: 0.95)
                    .ignoresSafeArea()
                HStack(alignment: .bottom, spacing: Layout.interItemSpacing) {
                    InformationView()
                        .frame(width: Layout.infoPanelWidth, alignment: .top)
                        .frame(maxHeight: .infinity, alignment: .top)

                    KeyboardUIView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
                .frame(
                    width: Layout.containerWidth,
                    height: Layout.containerHeight,
                    alignment: .bottom
                )
                .scaleEffect(scale, anchor: .bottom)
                .frame(
                    width: scaledWidth,
                    height: scaledHeight,
                    alignment: .bottom
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
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
