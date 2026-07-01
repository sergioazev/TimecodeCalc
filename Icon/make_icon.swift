#!/usr/bin/env swift
// Renders the ARGO app icon (1024×1024 PNG) — dark squircle, gold wordmark,
// matching the app's header. Run: swift Icon/make_icon.swift
import AppKit

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let gold = NSColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1)

// Squircle background with a dark vertical gradient
let inset: CGFloat = 88
let rect = NSRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
let radius: CGFloat = (S - 2 * inset) * 0.235
let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
let bg = NSGradient(colors: [NSColor(white: 0.13, alpha: 1), NSColor(white: 0.05, alpha: 1)])!
bg.draw(in: squircle, angle: -90)

// Thin gold hairline just inside the edge
gold.withAlphaComponent(0.55).setStroke()
let hair = NSBezierPath(roundedRect: rect.insetBy(dx: 10, dy: 10),
                        xRadius: radius - 8, yRadius: radius - 8)
hair.lineWidth = 3
hair.stroke()

// "ARGO" wordmark — bold monospaced, kerned, scaled to fit
let text = "ARGO"
let baseFont = NSFont.monospacedSystemFont(ofSize: 300, weight: .bold)
var attrs: [NSAttributedString.Key: Any] = [
    .font: baseFont,
    .foregroundColor: gold,
    .kern: 24.0,
]
var size = (text as NSString).size(withAttributes: attrs)
let targetWidth = (S - 2 * inset) * 0.66
let scale = targetWidth / size.width
let font = NSFont.monospacedSystemFont(ofSize: 300 * scale, weight: .bold)
attrs[.font] = font
attrs[.kern] = 24.0 * scale
size = (text as NSString).size(withAttributes: attrs)
let origin = NSPoint(x: (S - size.width) / 2, y: (S - size.height) / 2)
(text as NSString).draw(at: origin, withAttributes: attrs)

NSGraphicsContext.restoreGraphicsState()

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Icon/AppIcon.png"
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
