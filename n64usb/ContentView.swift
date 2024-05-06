//
//  ContentView.swift
//  n64usb
//
//  Created by jcm on 5/5/24.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var controller = Controller()
    
    @State var isInitialized = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Button {
                Task { controller.isCapturing.toggle() }
            } label: {
                Text(controller.isCapturing ? "Stop keyboard capture" : "Start keyboard capture")
            }
            .controlSize(.extraLarge)
            .focusable()
        }
        .padding()
        .onAppear {
            Task {
                do {
                    try await controller.start()
                } catch {
                    isInitialized = false
                }
            }
        }
    }
    
}

#Preview {
    ContentView()
}
