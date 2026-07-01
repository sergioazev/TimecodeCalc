import SwiftUI
import AppKit
import TimecodeCore

struct CalculatorView: View {
    @State private var tc1    = Timecode(frameRate: .fps25)
    @State private var tc2    = Timecode(frameRate: .fps25)
    @State private var frameRate: FrameRate = .fps25
    @State private var isAdd  = true

    // Tape-mode accumulator (chained sum of results)
    @State private var accumFrames = 0
    @State private var accumCount  = 0

    private var accumulator: Timecode {
        Timecode(totalFrames: accumFrames, frameRate: frameRate)
    }

    private var computed: Timecode {
        let a = Timecode(hours: tc1.hours, minutes: tc1.minutes,
                         seconds: tc1.seconds, frames: tc1.frames, frameRate: frameRate)
        let b = Timecode(hours: tc2.hours, minutes: tc2.minutes,
                         seconds: tc2.seconds, frames: tc2.frames, frameRate: frameRate)
        return isAdd ? a + b : a - b
    }

    private var wrapped24h: Bool {
        isAdd && tc1.totalFrames + tc2.totalFrames >= frameRate.framesPerDay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // TC1
            row(label: "TC 1") {
                TimecodeField(timecode: $tc1)
                Spacer()
                fpsPicker
            }

            // Operator
            HStack {
                Text("Op").frame(width: 40, alignment: .trailing)
                    .foregroundStyle(.secondary)
                Picker("", selection: $isAdd) {
                    Text("+").tag(true)
                    Text("−").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                Spacer()
            }

            // TC2
            row(label: "TC 2") {
                TimecodeField(timecode: $tc2)
                Spacer()
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
                if wrapped24h {
                    Text("+24h")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.argoGold)
                        .help("Sum passed midnight — wrapped at 24h")
                }
                Spacer()
                Text(computed.frameCountString)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button {
                    copyResult()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy result (⇧⌘C)")
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            .padding(.vertical, 4)

            // Tape accumulator
            HStack(spacing: 12) {
                Text("Σ")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.argoGold)
                Text(accumulator.description)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(accumCount > 0 ? .primary : .secondary)
                Text("(\(accumCount))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(accumulator.frameCountString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button { copyAccumulator() } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.borderless)
                    .help("Copy tape total")
                    .disabled(accumCount == 0)
            }

            // Buttons
            HStack(spacing: 12) {
                Spacer()
                Button("MC") { clearTape() }
                    .help("Clear tape")
                    .disabled(accumCount == 0)
                Button("M+") { addToTape() }
                    .help("Add result to tape (⌘↵)")
                    .keyboardShortcut(.return, modifiers: .command)
                Button("Clear") {
                    clear()
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }
        .padding()
        .onChange(of: frameRate) { _, newRate in
            tc1.frameRate = newRate
            tc2.frameRate = newRate
            clearTape()  // frame counts are rate-specific; start the tape over
        }
    }

    // MARK: - Actions

    private func clear() {
        tc1 = Timecode(frameRate: frameRate)
        tc2 = Timecode(frameRate: frameRate)
    }

    private func addToTape() {
        accumFrames += computed.totalFrames
        accumCount  += 1
    }

    private func clearTape() {
        accumFrames = 0
        accumCount  = 0
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(computed.description, forType: .string)
    }

    private func copyAccumulator() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(accumulator.description, forType: .string)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func row<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: 40, alignment: .trailing)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private var fpsPicker: some View {
        Picker("", selection: $frameRate) {
            ForEach(FrameRate.allCases) { fps in
                Text(fps.rawValue).tag(fps)
            }
        }
        .frame(width: 120)
        .help("Frame rate")
    }
}
