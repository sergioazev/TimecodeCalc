import SwiftUI
import AppKit

@main
struct TimecodeCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
