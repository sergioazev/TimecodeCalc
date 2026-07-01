import SwiftUI
import AppKit
import TimecodeCore

enum ConvertMode: String, CaseIterable {
    case realtime = "Realtime"   // same wall-clock instant (speed change)
    case frame    = "Frame"      // same frame index (conform / relabel)
}

struct ConverterView: View {
    @State private var source      = Timecode(frameRate: .fps25)
    @State private var fromRate: FrameRate = .fps25
    @State private var toRate:   FrameRate = .fps2997df
    @State private var mode: ConvertMode = .realtime

    private var computed: Timecode {
        let tc = Timecode(hours: source.hours, minutes: source.minutes,
                          seconds: source.seconds, frames: source.frames,
                          frameRate: fromRate)
        switch mode {
        case .realtime: return tc.converted(to: toRate)
        case .frame:    return tc.reinterpreted(at: toRate)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Source
            HStack(spacing: 8) {
                Text("TC").frame(width: 40, alignment: .trailing).foregroundStyle(.secondary)
                TimecodeField(timecode: $source)
                Spacer()
                Text("from").foregroundStyle(.secondary)
                fpsPicker(selection: $fromRate)
            }

            // Target fps
            HStack(spacing: 8) {
                Spacer().frame(width: 40)
                Spacer()
                Text("to").foregroundStyle(.secondary)
                fpsPicker(selection: $toRate)
            }

            // Conversion mode
            HStack(spacing: 8) {
                Text("mode").frame(width: 40, alignment: .trailing).foregroundStyle(.secondary)
                Picker("", selection: $mode) {
                    ForEach(ConvertMode.allCases, id: \.self) { m in Text(m.rawValue).tag(m) }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                Spacer()
                Text(mode == .realtime ? "same instant" : "same frame #")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Result
            HStack(spacing: 12) {
                Text("=")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.argoGold)
                Text(computed.description)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                Spacer()
                deltaLabel
                Button { copyResult() } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.borderless)
                    .help("Copy result (⇧⌘C)")
                    .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            .padding(.vertical, 4)

            HStack(spacing: 12) {
                Spacer()
                Button("Clear") { clear() }
                    .keyboardShortcut(.delete, modifiers: .command)
            }
        }
        .padding()
        .onChange(of: fromRate) { _, newRate in
            source.frameRate = newRate
        }
    }

    private var deltaLabel: some View {
        let src   = Timecode(hours: source.hours, minutes: source.minutes,
                             seconds: source.seconds, frames: source.frames,
                             frameRate: fromRate)
        let delta = computed.totalFrames - src.totalFrames
        let sign  = delta >= 0 ? "+" : ""
        return Text("Δ \(sign)\(delta) fr")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(.secondary)
    }

    private func clear()       { source = Timecode(frameRate: fromRate) }
    private func copyResult()  {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(computed.description, forType: .string)
    }

    private func fpsPicker(selection: Binding<FrameRate>) -> some View {
        Picker("", selection: selection) {
            ForEach(FrameRate.allCases) { fps in Text(fps.rawValue).tag(fps) }
        }
        .frame(width: 120)
    }
}
