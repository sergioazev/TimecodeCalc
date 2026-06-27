import SwiftUI

enum AppTab: Int, CaseIterable {
    case calculator = 0
    case converter  = 1
    case frames     = 2
    case duration   = 3

    var label: String {
        switch self {
        case .calculator: return "Calculator"
        case .converter:  return "Convert"
        case .frames:     return "Frames"
        case .duration:   return "Duration"
        }
    }

    var icon: String {
        switch self {
        case .calculator: return "plus.slash.minus"
        case .converter:  return "arrow.left.arrow.right"
        case .frames:     return "film"
        case .duration:   return "timer"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .calculator

    var body: some View {
        VStack(spacing: 0) {
            // ── Argo header bar ─────────────────────────────────────
            HStack(spacing: 0) {
                Text("ARGO")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .kerning(3)
                    .foregroundStyle(Color.argoGold)
                    .padding(.leading, 16)
                Text(" TIMECODE")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(height: 32)
            .background(.bar)

            Divider()

            // ── Tab bar ─────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .frame(height: 38)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // ── Content ─────────────────────────────────────────────
            Group {
                switch selectedTab {
                case .calculator: CalculatorView()
                case .converter:  ConverterView()
                case .frames:     FramesView()
                case .duration:   DurationView()
                }
            }
            .frame(minWidth: 480, minHeight: 240)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 11))
                Text(tab.label)
                    .font(.system(size: 12))
            }
            .foregroundStyle(isSelected ? Color.argoGold : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(Color.argoGold)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        // ⌘1 … ⌘4
        .keyboardShortcut(KeyEquivalent(Character(String(tab.rawValue + 1))), modifiers: .command)
    }
}
