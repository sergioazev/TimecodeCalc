import SwiftUI
import AppKit

@main
struct TimecodeCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { setupArgoGoldColor() }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 300)
        .commands {
            // Remove File > New Window
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// Register the "ArgoGold" named color programmatically so SwiftUI Color.argoGold works
// without an asset catalog.
private func setupArgoGoldColor() {
    // This is a no-op — the actual color is defined in Color+Argo.swift below.
}
