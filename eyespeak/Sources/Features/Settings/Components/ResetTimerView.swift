//
//  ResetTimerView.swift
//  eyespeak
//
//  Created by Dwiki on 10/11/25.
//

import SwiftUI

struct ResetTimerView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Reset Time")
                    .font(Typography.boldHeader)
                Text("Time between action before resetting")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
                HStack {
                    NavigationCard(title: "+")
                        .frame(width: 68.5)
                }
            }
            
            
            Spacer()
        }
    }
}

#Preview {
    ResetTimerView()
}
