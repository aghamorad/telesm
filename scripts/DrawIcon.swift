// Draws the Telesm app icon: an aged brass amulet on ink.
// Usage: swift DrawIcon.swift <output.png>   (renders 1024x1024)

import AppKit
import CoreGraphics
import Foundation
import ImageIO

let S: CGFloat = 1024
let cx = S / 2
let cy = S / 2
let center = CGPoint(x: cx, y: cy)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

func grad(_ colors: [CGColor], _ locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
               colors: colors as CFArray,
               locations: locations)!
}

func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int) -> CGPath {
    let path = CGMutablePath()
    for i in 0..<(points * 2) {
        let radius = i % 2 == 0 ? outer : inner
        let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
}

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"

guard let ctx = CGContext(data: nil, width: Int(S), height: Int(S),
                          bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    FileHandle.standardError.write("could not create context\n".data(using: .utf8)!)
    exit(1)
}
ctx.interpolationQuality = .high
ctx.setAllowsAntialiasing(true)

let brass = grad([rgb(107, 78, 28), rgb(243, 220, 160), rgb(199, 154, 72), rgb(107, 78, 28)],
                 [0, 0.34, 0.62, 1])
let brassDark = grad([rgb(92, 68, 26), rgb(190, 150, 70), rgb(120, 88, 34), rgb(88, 64, 24)],
                     [0, 0.4, 0.7, 1])
let plaque = grad([rgb(138, 106, 42), rgb(246, 227, 176), rgb(168, 129, 58)],
                  [0, 0.45, 1])

// MARK: plate

let plate = CGRect(x: 14, y: 14, width: S - 28, height: S - 28)

ctx.saveGState()
ctx.addPath(CGPath(roundedRect: plate, cornerWidth: 232, cornerHeight: 232, transform: nil))
ctx.clip()

ctx.drawLinearGradient(grad([rgb(42, 50, 70), rgb(24, 29, 43), rgb(10, 12, 18)], [0, 0.55, 1]),
                       start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])

// sheen across the top
ctx.drawLinearGradient(grad([rgb(255, 255, 255, 0.10), rgb(255, 255, 255, 0)], [0, 1]),
                       start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: S * 0.45), options: [])

// vignette
ctx.drawRadialGradient(grad([rgb(0, 0, 0, 0), rgb(0, 0, 0, 0.55)], [0, 1]),
                       startCenter: center, startRadius: S * 0.28,
                       endCenter: center, endRadius: S * 0.74, options: [])

// MARK: beaded rim

let beadCount = 56
for i in 0..<beadCount {
    let angle = CGFloat(i) / CGFloat(beadCount) * 2 * .pi
    let beadCenter = CGPoint(x: cx + cos(angle) * 352, y: cy + sin(angle) * 352)
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: beadCenter.x - 10, y: beadCenter.y - 10, width: 20, height: 20))
    ctx.clip()
    ctx.drawLinearGradient(brassDark,
                           start: CGPoint(x: beadCenter.x - 10, y: beadCenter.y + 10),
                           end: CGPoint(x: beadCenter.x + 10, y: beadCenter.y - 10), options: [])
    ctx.restoreGState()
}

// MARK: amulet disc

ctx.saveGState()
ctx.addEllipse(in: CGRect(x: cx - 326, y: cy - 326, width: 652, height: 652))
ctx.clip()
ctx.drawLinearGradient(brass, start: CGPoint(x: cx - 326, y: cy + 326),
                       end: CGPoint(x: cx + 326, y: cy - 326), options: [])
ctx.restoreGState()

// inner field
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: cx - 298, y: cy - 298, width: 596, height: 596))
ctx.clip()
ctx.drawRadialGradient(grad([rgb(32, 40, 58), rgb(16, 20, 30), rgb(7, 9, 14)], [0, 0.6, 1]),
                       startCenter: CGPoint(x: cx - 60, y: cy + 90), startRadius: 20,
                       endCenter: center, endRadius: 320, options: [])
ctx.restoreGState()

// a hairline inside the ring, engraved
ctx.setStrokeColor(rgb(60, 44, 16, 0.85))
ctx.setLineWidth(3)
ctx.addEllipse(in: CGRect(x: cx - 285, y: cy - 285, width: 570, height: 570))
ctx.strokePath()

// MARK: eight point star

let star = starPath(center: center, outer: 248, inner: 106, points: 8)
ctx.saveGState()
ctx.addPath(star)
ctx.clip()
ctx.drawLinearGradient(plaque, start: CGPoint(x: cx - 248, y: cy + 248),
                       end: CGPoint(x: cx + 248, y: cy - 248), options: [])
ctx.restoreGState()
ctx.addPath(star)
ctx.setStrokeColor(rgb(74, 54, 20, 0.75))
ctx.setLineWidth(4)
ctx.strokePath()

// inset shadow so the star sits below the field
ctx.saveGState()
ctx.addPath(star)
ctx.clip()
ctx.setStrokeColor(rgb(0, 0, 0, 0.35))
ctx.setLineWidth(14)
ctx.addPath(starPath(center: center, outer: 248, inner: 106, points: 8))
ctx.strokePath()
ctx.restoreGState()

// MARK: compass needle

let tipTop = CGPoint(x: cx, y: cy + 168)
let tipBottom = CGPoint(x: cx, y: cy - 168)
let wingRight = CGPoint(x: cx + 40, y: cy)
let wingLeft = CGPoint(x: cx - 40, y: cy)

let north = CGMutablePath()
north.move(to: tipTop)
north.addLine(to: wingRight)
north.addLine(to: wingLeft)
north.closeSubpath()

let south = CGMutablePath()
south.move(to: tipBottom)
south.addLine(to: wingRight)
south.addLine(to: wingLeft)
south.closeSubpath()

ctx.saveGState()
ctx.addPath(south)
ctx.clip()
ctx.drawLinearGradient(grad([rgb(150, 118, 52), rgb(96, 72, 28)], [0, 1]),
                       start: CGPoint(x: cx, y: cy), end: CGPoint(x: cx, y: cy - 168), options: [])
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(north)
ctx.clip()
ctx.drawLinearGradient(grad([rgb(252, 244, 222), rgb(214, 188, 130)], [0, 1]),
                       start: CGPoint(x: cx, y: cy + 168), end: CGPoint(x: cx, y: cy), options: [])
ctx.restoreGState()

ctx.setStrokeColor(rgb(70, 50, 18, 0.9))
ctx.setLineWidth(3)
ctx.addPath(north); ctx.strokePath()
ctx.addPath(south); ctx.strokePath()

// hub
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: cx - 22, y: cy - 22, width: 44, height: 44))
ctx.clip()
ctx.drawLinearGradient(brass, start: CGPoint(x: cx - 22, y: cy + 22),
                       end: CGPoint(x: cx + 22, y: cy - 22), options: [])
ctx.restoreGState()
ctx.setStrokeColor(rgb(60, 42, 14))
ctx.setLineWidth(3)
ctx.addEllipse(in: CGRect(x: cx - 22, y: cy - 22, width: 44, height: 44))
ctx.strokePath()

// MARK: plate edge

ctx.setStrokeColor(rgb(0, 0, 0, 0.45))
ctx.setLineWidth(26)
ctx.addPath(CGPath(roundedRect: plate.insetBy(dx: 13, dy: 13), cornerWidth: 224, cornerHeight: 224, transform: nil))
ctx.strokePath()

ctx.restoreGState()

// MARK: write

guard let image = ctx.makeImage() else { exit(1) }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    FileHandle.standardError.write("could not create \(outPath)\n".data(using: .utf8)!)
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { exit(1) }
print("wrote \(outPath)")
