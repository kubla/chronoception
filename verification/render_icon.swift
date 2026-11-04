import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let size = 1024
let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 3,
    hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(red: 0.97, green: 0.96, blue: 0.92, alpha: 1).setFill()
NSBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size)).fill()
NSColor(red: 0.12, green: 0.39, blue: 0.35, alpha: 1).setStroke()
let ring = NSBezierPath()
ring.appendArc(withCenter: CGPoint(x: 512, y: 512), radius: 290, startAngle: 55, endAngle: 395)
ring.lineWidth = 38
ring.lineCapStyle = .round
ring.stroke()
let mark = NSBezierPath()
mark.move(to: CGPoint(x: 512, y: 512))
mark.line(to: CGPoint(x: 512, y: 698))
mark.lineWidth = 32
mark.lineCapStyle = .round
mark.stroke()
NSColor(red: 0.12, green: 0.39, blue: 0.35, alpha: 1).setFill()
NSBezierPath(ovalIn: CGRect(x: 489, y: 489, width: 46, height: 46)).fill()
NSGraphicsContext.restoreGraphicsState()
let png = bitmap.representation(using: .png, properties: [:])!
for name in ["AppIcon", "AppIconWatch"] {
    try png.write(to: root.appending(path: "Application/Assets.xcassets/\(name).appiconset/AppIcon.png"))
}
