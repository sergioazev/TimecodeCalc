import SwiftUI

// HH:MM:SS[:;]FF input.
// Each component is a plain SwiftUI TextField. FocusState lives here so it
// applies directly to the TextFields — no intermediate wrapper, no dual-scope
// focus issues.
//
// UX:  click a field → it clears for fresh 2-digit entry
//      type 2 digits → auto-advance to next field
//      Tab / Shift+Tab → move between fields (SwiftUI native)
//      ↑ / ↓ → increment / decrement with wrap
//      blur without completing → commits whatever was typed
struct TimecodeField: View {
    @Binding var timecode: Timecode

    private enum F: Hashable { case hh, mm, ss, ff }
    @FocusState private var focused: F?

    // Per-field display text (separate from the Timecode values so we can
    // show a blank field while the user is mid-entry)
    @State private var hhTxt = "00"
    @State private var mmTxt = "00"
    @State private var ssTxt = "00"
    @State private var ffTxt = "00"

    // Which field the user is currently typing into (nil = not typing)
    @State private var typing: F? = nil

    var body: some View {
        HStack(spacing: 2) {
            tcField(.hh, txt: $hhTxt, val: $timecode.hours,   max: 23)
            sep(":")
            tcField(.mm, txt: $mmTxt, val: $timecode.minutes, max: 59)
            sep(":")
            tcField(.ss, txt: $ssTxt, val: $timecode.seconds, max: 59)
            sep(timecode.frameRate.separator)
            tcField(.ff, txt: $ffTxt, val: $timecode.frames,  max: timecode.frameRate.nominalFps - 1)
        }
        // Sync display texts when values change externally (e.g. Clear button)
        .onChange(of: timecode) { _, tc in
            // Snap invalid drop-frame entries (e.g. 00:01:00;00) to the
            // next valid TC — this write re-triggers onChange for the sync.
            if !tc.isValidDropFrame {
                timecode.frames = tc.frameRate.dropCount
                return
            }
            if typing == nil {
                syncAll()
            } else if typing != .ff {
                // A snap may have changed frames while another field is
                // being typed — keep the FF display honest.
                ffTxt = fmt(tc.frames)
            }
        }
        // Clamp frames when fps changes
        .onChange(of: timecode.frameRate) { _, rate in
            let cap = rate.nominalFps - 1
            if timecode.frames > cap { timecode.frames = cap }
        }
        .onAppear { syncAll() }
    }

    // MARK: - Per-field TextField builder

    @ViewBuilder
    private func tcField(_ f: F,
                         txt: Binding<String>,
                         val: Binding<Int>,
                         max: Int) -> some View {
        TextField("00", text: txt)
            .frame(width: 32)
            .multilineTextAlignment(.center)
            .font(.system(size: 14, design: .monospaced))
            .textFieldStyle(.roundedBorder)
            .focused($focused, equals: f)

            // ── Focus gained: clear for fresh digits ─────────────────
            .onChange(of: focused) { old, new in
                if new == f {
                    txt.wrappedValue = ""
                    typing = f
                } else if old == f {
                    // Focus left: commit whatever was typed, or restore
                    let digits = txt.wrappedValue.filter(\.isNumber)
                    if typing == f, !digits.isEmpty {
                        val.wrappedValue = min(Int(digits) ?? 0, max)
                    }
                    txt.wrappedValue = fmt(val.wrappedValue)
                    if typing == f { typing = nil }
                }
            }

            // ── Text change: auto-advance after 2 digits ─────────────
            .onChange(of: txt.wrappedValue) { _, new in
                guard typing == f else { return }
                let digits = new.filter(\.isNumber)
                guard digits.count >= 2 else { return }
                let num = min(Int(String(digits.suffix(2))) ?? 0, max)
                val.wrappedValue = num
                txt.wrappedValue = fmt(num)
                typing = nil
                advance(from: f)
            }

            // ── Arrow keys: increment / decrement ────────────────────
            .onKeyPress(.upArrow) {
                val.wrappedValue = val.wrappedValue < max ? val.wrappedValue + 1 : 0
                txt.wrappedValue = fmt(val.wrappedValue)
                typing = nil
                return .handled
            }
            .onKeyPress(.downArrow) {
                val.wrappedValue = val.wrappedValue > 0 ? val.wrappedValue - 1 : max
                txt.wrappedValue = fmt(val.wrappedValue)
                typing = nil
                return .handled
            }
    }

    // MARK: - Helpers

    private func advance(from f: F) {
        switch f {
        case .hh: focused = .mm
        case .mm: focused = .ss
        case .ss: focused = .ff
        case .ff: focused = nil
        }
    }

    private func sep(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 10)
    }

    private func fmt(_ v: Int) -> String { String(format: "%02d", v) }

    private func syncAll() {
        hhTxt = fmt(timecode.hours);   mmTxt = fmt(timecode.minutes)
        ssTxt = fmt(timecode.seconds); ffTxt = fmt(timecode.frames)
    }
}
