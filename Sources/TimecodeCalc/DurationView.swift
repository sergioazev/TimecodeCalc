import SwiftUI
import AppKit

struct DurationView: View {
    @State private var inTC  = Timecode(frameRate: .fps25)
    @State private var outTC = Timecode(frameRate: .fps25)
    @State private var frameRate: FrameRate = .fps25
    @State private var result: Timecode? = nil

    private var computed: Timecode {
        let inT  = Timecode(hours: inTC.hours, minutes: inTC.minutes,
                            seconds: inTC.seconds, frames: inTC.frames, frameRate: frameRate)
        let outT = Timecode(hours: outTC.hours, minutes: outTC.minutes,
                            seconds: outTC.seconds, frames: outTC.frames, frameRate: frameRate)
        return outT - inT  // clamped to zero on underflow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            row(label: "IN") {
                TimecodeField(timecode: $inTC)
                Spacer()
                fpsPicker
            }

            row(label: "OUT") {
                TimecodeField(timecode: $outTC)
                Spacer()
            }

            Divider()

            // Duration result
            HStack(spacing: 12) {
                Text("Dur")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.argoGold)
                Text((result ?? computed).description)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                Spacer()
                Text((result ?? computed).frameCountString)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button { copyResult() } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.borderless)
                    .help("Copy result (⌘C)")
                    .keyboardShortcut("c", modifiers: .command)
            }
            .padding(.vertical, 4)

            // Real-time seconds display
            let dur = result ?? computed
            let secs = Double(dur.totalFrames) / frameRate.exactFps
            Text(String(format: "%.3f seconds  ·  %d frames", secs, dur.totalFrames))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)

            HStack(spacing: 12) {
                Spacer()
                Button("Clear") { clear() }
                    .keyboardShortcut(.delete, modifiers: .command)
                Button("Calculate") { calculate() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.argoGold)
            }
        }
        .padding()
        .onChange(of: frameRate) { _, rate in
            inTC.frameRate  = rate
            outTC.frameRate = rate
            result = nil
        }
    }

    private func calculate()  { result = computed }
    private func clear()      { inTC = .zero(at: frameRate); outTC = .zero(at: frameRate); result = nil }
    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString((result ?? computed).description, forType: .string)
    }

    @ViewBuilder
    private func row<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).frame(width: 40, alignment: .trailing).foregroundStyle(.secondary)
            content()
        }
    }

    private var fpsPicker: some View {
        Picker("", selection: $frameRate) {
            ForEach(FrameRate.allCases) { fps in Text(fps.rawValue).tag(fps) }
        }
        .frame(width: 120)
    }
}
