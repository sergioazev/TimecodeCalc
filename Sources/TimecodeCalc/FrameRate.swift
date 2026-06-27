import Foundation

enum FrameRate: String, CaseIterable, Identifiable, Hashable {
    case fps23976  = "23.976"
    case fps24     = "24"
    case fps25     = "25"
    case fps2997   = "29.97 NDF"
    case fps2997df = "29.97 DF"
    case fps30     = "30"
    case fps50     = "50"
    case fps5994   = "59.94 NDF"
    case fps5994df = "59.94 DF"
    case fps60     = "60"

    var id: String { rawValue }

    var nominalFps: Int {
        switch self {
        case .fps23976:           return 24
        case .fps24:              return 24
        case .fps25:              return 25
        case .fps2997, .fps2997df: return 30
        case .fps30:              return 30
        case .fps50:              return 50
        case .fps5994, .fps5994df: return 60
        case .fps60:              return 60
        }
    }

    var exactFps: Double {
        switch self {
        case .fps23976:           return 24_000.0 / 1_001.0
        case .fps24:              return 24.0
        case .fps25:              return 25.0
        case .fps2997, .fps2997df: return 30_000.0 / 1_001.0
        case .fps30:              return 30.0
        case .fps50:              return 50.0
        case .fps5994, .fps5994df: return 60_000.0 / 1_001.0
        case .fps60:              return 60.0
        }
    }

    var isDropFrame: Bool {
        self == .fps2997df || self == .fps5994df
    }

    // Frames dropped per minute (0 for NDF, 2 for 29.97 DF, 4 for 59.94 DF)
    var dropCount: Int {
        switch self {
        case .fps2997df: return 2
        case .fps5994df: return 4
        default:         return 0
        }
    }

    // SMPTE separator: semicolon for DF, colon for NDF
    var separator: String { isDropFrame ? ";" : ":" }

    // Frames in a 10-minute block (used by DF math)
    var framesPer10Min: Int {
        nominalFps * 600 - 9 * dropCount
    }

    // Frames in a non-first drop minute
    var framesPerDropMin: Int {
        nominalFps * 60 - dropCount
    }
}
