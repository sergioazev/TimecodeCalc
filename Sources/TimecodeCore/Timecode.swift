import Foundation

public struct Timecode: Equatable, CustomStringConvertible {
    public var hours:   Int
    public var minutes: Int
    public var seconds: Int
    public var frames:  Int
    public var frameRate: FrameRate

    public init(hours: Int = 0, minutes: Int = 0, seconds: Int = 0, frames: Int = 0, frameRate: FrameRate = .fps25) {
        self.hours     = hours
        self.minutes   = minutes
        self.seconds   = seconds
        self.frames    = frames
        self.frameRate = frameRate
    }

    // MARK: - TC → total frame count

    public var totalFrames: Int {
        let N = frameRate.nominalFps
        if !frameRate.isDropFrame {
            return (hours * 3600 + minutes * 60 + seconds) * N + frames
        } else {
            // SMPTE drop-frame formula
            let totalMins = hours * 60 + minutes
            return N * (3600 * hours + 60 * minutes + seconds) + frames
                   - frameRate.dropCount * (totalMins - totalMins / 10)
        }
    }

    // MARK: - Total frame count → TC

    public init(totalFrames f: Int, frameRate: FrameRate) {
        self.frameRate = frameRate
        let N  = frameRate.nominalFps
        var rem = max(0, f)

        if !frameRate.isDropFrame {
            frames  = rem % N; rem /= N
            seconds = rem % 60; rem /= 60
            minutes = rem % 60; rem /= 60
            hours   = rem
        } else {
            // Elmo Rietze / SMPTE reverse drop-frame algorithm
            let d   = frameRate.dropCount
            let d10 = frameRate.framesPer10Min  // frames in a 10-min block
            let d1  = frameRate.framesPerDropMin // frames in a drop minute
            let nonDropMin = N * 60             // frames in the first (non-drop) minute

            hours = rem / (6 * d10)
            rem  %= (6 * d10)

            let m10 = rem / d10
            rem    %= d10

            let m1: Int
            if rem < nonDropMin {
                // First (non-drop) minute of this 10-min block
                m1      = 0
                seconds = rem / N
                frames  = rem % N
            } else {
                rem -= nonDropMin
                m1       = 1 + rem / d1
                rem     %= d1
                // Within a drop minute, frame numbering starts at :d (e.g. :02 or :04)
                let disp = rem + d
                seconds  = disp / N
                frames   = disp % N
            }
            minutes = m10 * 10 + m1
        }
    }

    // MARK: - Arithmetic

    public static func + (lhs: Timecode, rhs: Timecode) -> Timecode {
        // Wrap past midnight, like a deck/NLE counter
        let sum = (lhs.totalFrames + rhs.totalFrames) % lhs.frameRate.framesPerDay
        return Timecode(totalFrames: sum, frameRate: lhs.frameRate)
    }

    public static func - (lhs: Timecode, rhs: Timecode) -> Timecode {
        Timecode(totalFrames: max(0, lhs.totalFrames - rhs.totalFrames), frameRate: lhs.frameRate)
    }

    // MARK: - Frame-rate conversion

    // Same wall-clock instant: preserve real time, recount frames.
    // Use for genuine speed changes (e.g. a 25p master viewed at 29.97).
    public func converted(to target: FrameRate) -> Timecode {
        let realSeconds = Double(totalFrames) / frameRate.exactFps
        let newFrames   = Int(realSeconds * target.exactFps + 0.5)
        return Timecode(totalFrames: newFrames, frameRate: target)
    }

    // Same frame index: preserve the frame count, relabel the TC.
    // Use for conform between cuts at different TC rates (e.g. teaser×feature).
    public func reinterpreted(at target: FrameRate) -> Timecode {
        Timecode(totalFrames: totalFrames, frameRate: target)
    }

    // MARK: - Display

    public var description: String {
        let sep = frameRate.separator
        return String(format: "%02d:%02d:%02d\(sep)%02d", hours, minutes, seconds, frames)
    }

    public var frameCountString: String {
        "\(totalFrames) fr"
    }

    // MARK: - Drop-frame validity

    // In DF, frames 0..<dropCount are skipped at the start of every minute
    // that is not a multiple of 10 (e.g. 00:01:00;00 and ;01 don't exist).
    public var isValidDropFrame: Bool {
        guard frameRate.isDropFrame else { return true }
        return !(seconds == 0 && minutes % 10 != 0 && frames < frameRate.dropCount)
    }

    // Nudge an illegal DF value up to the next real frame.
    public var snappedToValidDropFrame: Timecode {
        guard !isValidDropFrame else { return self }
        var tc = self
        tc.frames = frameRate.dropCount
        return tc
    }

    // MARK: - Parsing (paste)

    // Accepts "HH:MM:SS:FF", "HH:MM:SS;FF", partials like "MM:SS:FF" or "SS:FF"
    // (right-aligned), and 8 raw digits "HHMMSSFF". Components are clamped to
    // legal ranges; illegal DF values snap to the next valid frame.
    public init?(parsing raw: String, frameRate: FrameRate) {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        var nums: [Int]
        if s.contains(where: { $0 == ":" || $0 == ";" || $0 == "." }) {
            let parts = s.split(whereSeparator: { $0 == ":" || $0 == ";" || $0 == "." })
            let parsed = parts.map { Int($0) }
            guard !parsed.contains(nil), parsed.count <= 4 else { return nil }
            nums = parsed.compactMap { $0 }
        } else {
            let digits = Array(s)
            guard digits.count == 8, digits.allSatisfy(\.isNumber) else { return nil }
            nums = stride(from: 0, to: 8, by: 2).map { Int(String(digits[$0...$0 + 1]))! }
        }

        while nums.count < 4 { nums.insert(0, at: 0) }
        let capF = frameRate.nominalFps - 1
        let tc = Timecode(hours:   min(max(nums[0], 0), 99),
                          minutes: min(max(nums[1], 0), 59),
                          seconds: min(max(nums[2], 0), 59),
                          frames:  min(max(nums[3], 0), capF),
                          frameRate: frameRate).snappedToValidDropFrame
        self = tc
    }
}

// Zero timecode helper
extension Timecode {
    public static func zero(at frameRate: FrameRate) -> Timecode {
        Timecode(frameRate: frameRate)
    }
}
