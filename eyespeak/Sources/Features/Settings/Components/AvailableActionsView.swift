//
//  AvailableActionsView.swift
//  eyespeak
//
//  Created by Dwiki on 07/11/25.
//

import SwiftUI

struct AvailableActionsView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    
    var body: some View {
        HStack {
            VStack(alignment:.leading, spacing: 15) {
                Text("Available Actions")
                    .font(Typography.boldHeader)
                Text("Select which movements you can do comfortably")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
               
                VStack {
                    NavigationCard(
                        title: "Edit Actions",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        firstCombo: getEditActionsCombo().0,
                        secondCombo: getEditActionsCombo().1
                    ) {
                        viewModel.isEditActionsMode = true
                    }
                }
                .frame(width: 200)
                
            }
            Spacer()
        }
    }
    
    private func getEditActionsCombo() -> (GestureType?, GestureType?) {
        let combos = viewModel.getCombosForMenu(.settings)
        for (combo, id) in combos where id == 0 {
            return (combo.firstGesture, combo.secondGesture)
        }
        return (nil, nil)
    }
}

#Preview {
    AvailableActionsView()
}

