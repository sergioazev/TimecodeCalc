import TimecodeCore
import Foundation

// Minimal assertion harness — no XCTest, so this runs under plain Command
// Line Tools with `swift run TimecodeCoreTests`. Exits non-zero on failure.

var failures = 0
func expect(_ cond: Bool, _ label: String) {
    if cond { print("  ok   \(label)") }
    else    { failures += 1; print("FAIL   \(label)") }
}
func expectEqual<T: Equatable>(_ a: T, _ b: T, _ label: String) {
    expect(a == b, "\(label)  (got \(a), want \(b))")
}

// MARK: Canonical drop-frame values
expectEqual(Timecode(minutes: 10, frameRate: .fps2997df).totalFrames, 17982, "00:10:00;00 @29.97DF == 17982 fr")
expectEqual(Timecode(minutes: 1, frames: 2, frameRate: .fps2997df).totalFrames, 1800, "00:01:00;02 @29.97DF == 1800 fr")
expectEqual(Timecode(hours: 1, frameRate: .fps2997df).totalFrames, 107892, "01:00:00;00 @29.97DF == 107892 fr")
expectEqual(Timecode(totalFrames: 17982, frameRate: .fps2997df).description, "00:10:00;00", "17982 fr → 00:10:00;00")
expectEqual(Timecode(totalFrames: 1800, frameRate: .fps2997df).description, "00:01:00;02", "1800 fr → 00:01:00;02")

// MARK: Roundtrip + validity across every rate, over a full 24h
for rate in FrameRate.allCases {
    var bad = 0, f = 0
    while f < rate.framesPerDay {
        let tc = Timecode(totalFrames: f, frameRate: rate)
        if tc.totalFrames != f || !tc.isValidDropFrame { bad += 1 }
        f += 9973
    }
    expect(bad == 0, "roundtrip + validity @\(rate.rawValue)")
}

// MARK: Drop-frame validity + snapping
expect(!Timecode(minutes: 1, frames: 0, frameRate: .fps2997df).isValidDropFrame, "00:01:00;00 @29.97DF invalid")
expect(!Timecode(minutes: 1, frames: 1, frameRate: .fps2997df).isValidDropFrame, "00:01:00;01 @29.97DF invalid")
expect( Timecode(minutes: 10, frames: 0, frameRate: .fps2997df).isValidDropFrame, "00:10:00;00 @29.97DF valid")
expect(!Timecode(minutes: 1, frames: 3, frameRate: .fps5994df).isValidDropFrame, "00:01:00;03 @59.94DF invalid")
expect( Timecode(minutes: 1, frames: 4, frameRate: .fps5994df).isValidDropFrame, "00:01:00;04 @59.94DF valid")
expect( Timecode(minutes: 1, frames: 0, frameRate: .fps2997).isValidDropFrame, "NDF always valid")
expectEqual(Timecode(minutes: 1, frames: 0, frameRate: .fps2997df).snappedToValidDropFrame.description, "00:01:00;02", "snap 00:01:00;00 → ;02")

// MARK: Addition wraps at 24h, subtraction clamps at zero
expectEqual((Timecode(hours: 23, frameRate: .fps25) + Timecode(hours: 2, frameRate: .fps25)).description, "01:00:00:00", "23:00 + 02:00 @25 wraps")
let dfEnd = Timecode(hours: 23, minutes: 59, seconds: 59, frames: 29, frameRate: .fps2997df)
expectEqual((dfEnd + Timecode(totalFrames: 1, frameRate: .fps2997df)).description, "00:00:00;00", "DF midnight rollover")
expectEqual((Timecode(hours: 2, frameRate: .fps25) - Timecode(hours: 23, frameRate: .fps25)).totalFrames, 0, "02:00 − 23:00 clamps to zero")

// MARK: Conversion — realtime vs conform
expectEqual(Timecode(hours: 1, frameRate: .fps25).converted(to: .fps2997df).description, "01:00:00;00", "1h @25 → 29.97DF realtime")
expectEqual(Timecode(totalFrames: 1000, frameRate: .fps24).reinterpreted(at: .fps25).totalFrames, 1000, "reinterpret keeps frame index")
let a2397 = Timecode(hours: 1, minutes: 2, seconds: 3, frames: 4, frameRate: .fps23976)
expectEqual(a2397.reinterpreted(at: .fps24).description, a2397.description, "23.976 ↔ 24 conform is identity")

// MARK: Parsing (paste)
expectEqual(Timecode(parsing: "01:02:03:04", frameRate: .fps25)?.description, "01:02:03:04", "parse HH:MM:SS:FF")
expectEqual(Timecode(parsing: "01;02;03;04", frameRate: .fps2997df)?.description, "01:02:03;04", "parse semicolons (DF displays ;)")
expectEqual(Timecode(parsing: "01020304", frameRate: .fps25)?.description, "01:02:03:04", "parse 8 digits")
expectEqual(Timecode(parsing: "05:00", frameRate: .fps24)?.description, "00:00:05:00", "parse partial right-aligned")
expectEqual(Timecode(parsing: "00:00:00:99", frameRate: .fps25)?.frames, 24, "parse clamps frames")
expectEqual(Timecode(parsing: "00:01:00:00", frameRate: .fps2997df)?.description, "00:01:00;02", "parse snaps illegal DF")
expect(Timecode(parsing: "", frameRate: .fps24) == nil, "parse rejects empty")
expect(Timecode(parsing: "abc", frameRate: .fps24) == nil, "parse rejects garbage")
expect(Timecode(parsing: "1:2:3:4:5", frameRate: .fps24) == nil, "parse rejects >4 parts")
expect(Timecode(parsing: "1234567", frameRate: .fps24) == nil, "parse rejects 7 digits")

print(failures == 0 ? "\n✓ ALL PASS" : "\n✗ \(failures) FAILURE(S)")
exit(failures == 0 ? 0 : 1)
