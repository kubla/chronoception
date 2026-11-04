import CoreGraphics
import Foundation
import ImageIO

func fail(_ message: String) -> Never {
    print("FAIL: \(message)")
    exit(1)
}

let root = URL(fileURLWithPath: CommandLine.arguments[1])
for name in ["AppIcon", "AppIconWatch"] {
    let url = root.appending(path: "Application/Assets.xcassets/\(name).appiconset/AppIcon.png")
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    guard image.width == 1024 && image.height == 1024 else {
        fail("\(name): expected a 1024 × 1024 icon")
    }
    guard [.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo) else {
        fail("\(name): the store icon must have no alpha channel")
    }
    let context = CGContext(
        data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 4096,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
    var low: [UInt8] = [255, 255, 255]
    var high: [UInt8] = [0, 0, 0]
    for offset in stride(from: 0, to: 1024 * 4096, by: 4) {
        for channel in 0..<3 {
            low[channel] = min(low[channel], pixels[offset + channel])
            high[channel] = max(high[channel], pixels[offset + channel])
        }
    }
    guard zip(high, low).contains(where: { Int($0.0) - Int($0.1) > 64 }) else {
        fail("\(name): blank or insufficiently contrasting icon")
    }
    print("PASS: \(name) is opaque, 1024 × 1024, and contains contrasting artwork.")
}
