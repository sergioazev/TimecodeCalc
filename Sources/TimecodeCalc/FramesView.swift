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
    @State private var result: String = "—"

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
                    .help("Copy result (⌘C)")
                    .keyboardShortcut("c", modifiers: .command)
            }
            .padding(.vertical, 4)

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
            tcInput.frameRate = rate
            result = "—"
        }
        .onChange(of: direction) { _, _ in result = "—" }
    }

    private func calculate() {
        switch direction {
        case .framesToTC:
            guard let f = Int(frameInput.trimmingCharacters(in: .whitespaces)) else {
                result = "Invalid"; return
            }
            let tc = Timecode(totalFrames: f, frameRate: frameRate)
            result = tc.description

        case .tcToFrames:
            let tc = Timecode(hours: tcInput.hours, minutes: tcInput.minutes,
                              seconds: tcInput.seconds, frames: tcInput.frames,
                              frameRate: frameRate)
            result = "\(tc.totalFrames)"
        }
    }

    private func clear() {
        frameInput = ""
        tcInput    = Timecode(frameRate: frameRate)
        result     = "—"
    }

    private func copyResult() {
        guard result != "—" else { return }
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
