import SwiftUI
import AppKit

enum FramesDirection: String, CaseIterable {
    case framesToTC = "Frames → TC"
    case tcToFrames = "TC → Frames"
}

struct FramesView: View {
    @State private var frameRate: FrameRate = .fps24
    @State private var direction: FramesDirection = .framesToTC
    @State private var frameInput: String = ""
    @State private var tcInput    = Timecode(frameRate: .fps24)

    private var result: String {
        switch direction {
        case .framesToTC:
            let trimmed = frameInput.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return "—" }
            guard let f = Int(trimmed) else { return "Invalid" }
            return Timecode(totalFrames: f, frameRate: frameRate).description

        case .tcToFrames:
            let tc = Timecode(hours: tcInput.hours, minutes: tcInput.minutes,
                              seconds: tcInput.seconds, frames: tcInput.frames,
                              frameRate: frameRate)
            return "\(tc.totalFrames)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Direction toggle
            HStack {
                Picker("", selection: $direction) {
                    ForEach(FramesDirection.allCases, id: \.self) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
                Spacer()
                fpsPicker
            }

            Divider()

            // Input
            if direction == .framesToTC {
                HStack(spacing: 8) {
                    Text("Frames").frame(width: 60, alignment: .trailing).foregroundStyle(.secondary)
                    TextField("86400", text: $frameInput)
                        .frame(width: 120)
                        .font(.system(size: 14, design: .monospaced))
                }
            } else {
                HStack(spacing: 8) {
                    Text("TC").frame(width: 60, alignment: .trailing).foregroundStyle(.secondary)
                    TimecodeField(timecode: $tcInput)
                }
            }

            Divider()

            // Result
            HStack(spacing: 12) {
                Text("=")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.argoGold)
                Text(result)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                Spacer()
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
        .onChange(of: frameRate) { _, rate in
            tcInput.frameRate = rate
        }
    }

    private func clear() {
        frameInput = ""
        tcInput    = Timecode(frameRate: frameRate)
    }

    private func copyResult() {
        guard result != "—", result != "Invalid" else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
    }

    private var fpsPicker: some View {
        Picker("", selection: $frameRate) {
            ForEach(FrameRate.allCases) { fps in Text(fps.rawValue).tag(fps) }
        }
        .frame(width: 120)
    }
}
