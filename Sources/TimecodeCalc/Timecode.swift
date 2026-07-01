import Foundation

struct Timecode: Equatable, CustomStringConvertible {
    var hours:   Int
    var minutes: Int
    var seconds: Int
    var frames:  Int
    var frameRate: FrameRate

    init(hours: Int = 0, minutes: Int = 0, seconds: Int = 0, frames: Int = 0, frameRate: FrameRate = .fps25) {
        self.hours     = hours
        self.minutes   = minutes
        self.seconds   = seconds
        self.frames    = frames
        self.frameRate = frameRate
    }

    // MARK: - TC → total frame count

    var totalFrames: Int {
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

    init(totalFrames f: Int, frameRate: FrameRate) {
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

    static func + (lhs: Timecode, rhs: Timecode) -> Timecode {
        // Wrap past midnight, like a deck/NLE counter
        let sum = (lhs.totalFrames + rhs.totalFrames) % lhs.frameRate.framesPerDay
        return Timecode(totalFrames: sum, frameRate: lhs.frameRate)
    }

    static func - (lhs: Timecode, rhs: Timecode) -> Timecode {
        Timecode(totalFrames: max(0, lhs.totalFrames - rhs.totalFrames), frameRate: lhs.frameRate)
    }

    // MARK: - Frame-rate conversion

    func converted(to target: FrameRate) -> Timecode {
        let realSeconds = Double(totalFrames) / frameRate.exactFps
        let newFrames   = Int(realSeconds * target.exactFps + 0.5)
        return Timecode(totalFrames: newFrames, frameRate: target)
    }

    // MARK: - Display

    var description: String {
        let sep = frameRate.separator
        return String(format: "%02d:%02d:%02d\(sep)%02d", hours, minutes, seconds, frames)
    }

    var frameCountString: String {
        "\(totalFrames) fr"
    }

    // MARK: - Drop-frame validity

    // In DF, frames 0..<dropCount are skipped at the start of every minute
    // that is not a multiple of 10 (e.g. 00:01:00;00 and ;01 don't exist).
    var isValidDropFrame: Bool {
        guard frameRate.isDropFrame else { return true }
        return !(seconds == 0 && minutes % 10 != 0 && frames < frameRate.dropCount)
    }
}

// Zero timecode helper
extension Timecode {
    static func zero(at frameRate: FrameRate) -> Timecode {
        Timecode(frameRate: frameRate)
    }
}
