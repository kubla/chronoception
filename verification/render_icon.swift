import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let context = CGContext(
    data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 4096,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let ink = CGColor(red: 0.12, green: 0.39, blue: 0.35, alpha: 1)
context.setFillColor(CGColor(red: 0.97, green: 0.96, blue: 0.92, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
context.setStrokeColor(ink)
context.setLineCap(.round)
context.setLineWidth(38)
context.addArc(
    center: CGPoint(x: 512, y: 512), radius: 290,
    startAngle: 55 * .pi / 180, endAngle: 395 * .pi / 180, clockwise: false)
context.strokePath()
context.setLineWidth(32)
context.move(to: CGPoint(x: 512, y: 512))
context.addLine(to: CGPoint(x: 512, y: 698))
context.strokePath()
context.setFillColor(ink)
context.fillEllipse(in: CGRect(x: 489, y: 489, width: 46, height: 46))
let image = context.makeImage()!
for name in ["AppIcon", "AppIconWatch"] {
    let url = root.appending(path: "Application/Assets.xcassets/\(name).appiconset/AppIcon.png")
    let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    precondition(CGImageDestinationFinalize(destination))
}
