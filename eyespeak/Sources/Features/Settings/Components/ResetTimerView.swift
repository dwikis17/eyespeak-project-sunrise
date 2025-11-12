//
//  ResetTimerView.swift
//  eyespeak
//
//  Created by Dwiki on 10/11/25.
//

import SwiftUI

struct ResetTimerView: View {
    @Environment(AppStateManager.self) private var appState
    @EnvironmentObject private var viewModel: AACViewModel
    @AppStorage("timerSpeed") private var timerSpeed: Double = 4.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Reset Time")
                    .font(Typography.boldHeader)
                Text("Time between action before resetting")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
                
                HStack(spacing: 20) {
                    // Decrement button (-)
                    IncrementButtonView(
                        title: "-",
                        background: .mellowBlue,
                        firstCombo: viewModel.settings.decrementTimerCombo?.0,
                        secondCombo: viewModel.settings.decrementTimerCombo?.1
                    ) {
                        if timerSpeed > 0.5 {
                            timerSpeed = max(0.5, timerSpeed - 1.0)
                            syncSettings()
                            updateTimingWindow()
                        }
                    }
                    
                    // Slider
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(timerSpeed, specifier: "%.1f")s")
                            .font(Typography.regularTitle)
                            .foregroundStyle(.primary)
                        Slider(
                            value: $timerSpeed,
                            in: 0.5...5.0,
                            step: 1.0
                        )
                        .tint(.mellowBlue)
                        .onChange(of: timerSpeed) { oldValue, newValue in
                            syncSettings()
                            updateTimingWindow()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Increment button (+)
                    IncrementButtonView(
                        title: "+",
                        background: .mellowBlue,
                        firstCombo: viewModel.settings.incrementTimerCombo?.0,
                        secondCombo: viewModel.settings.incrementTimerCombo?.1
                    ) {
                        if timerSpeed < 5.0 {
                            timerSpeed = min(5.0, timerSpeed + 1.0)
                            syncSettings()
                            updateTimingWindow()
                        }
                    }
                }

                
            }
            .frame(maxWidth: 650)
            
            Spacer()
        }
    
        .onAppear {
            // Sync with settings on appear
            timerSpeed = appState.settings.timerSpeed
        }
    }
    
    private func syncSettings() {
        // Sync the @AppStorage value with the settings object
        appState.settings.timerSpeed = timerSpeed
    }
    
    private func updateTimingWindow() {
        // Update the gesture input manager with the new timing window
        viewModel.gestureInputManager.setTimingWindow(timerSpeed)
    }
}

#Preview {
    ResetTimerView()
        .environment(AppStateManager())
        .environmentObject(AACViewModel(modelContext: AACDIContainer.makePreviewContainer().mainContext))
}
