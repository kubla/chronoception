import CoreGraphics
import Foundation
import ImageIO

func fail(_ message: String) -> Never {
    print("FAIL: \(message)")
    exit(1)
}

let imageURL = URL(fileURLWithPath: CommandLine.arguments[1])
let geometryURL = URL(fileURLWithPath: CommandLine.arguments[2])
let geometry = try JSONDecoder().decode([String: Double].self, from: Data(contentsOf: geometryURL))
let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil)!
let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let bounds = CGRect(
    x: geometry["x"]! * Double(image.width), y: geometry["y"]! * Double(image.height),
    width: geometry["width"]! * Double(image.width), height: geometry["height"]! * Double(image.height)
)
.integral
let title = image.cropping(to: bounds)!
let context = CGContext(
    data: nil, width: title.width, height: title.height, bitsPerComponent: 8,
    bytesPerRow: title.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.draw(title, in: CGRect(x: 0, y: 0, width: title.width, height: title.height))
let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
func linear(_ byte: UInt8) -> Double {
    let value = Double(byte) / 255
    return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
}
var luminances: [Double] = []
for offset in stride(from: 0, to: title.width * title.height * 4, by: 4) {
    luminances.append(
        0.2126 * linear(pixels[offset]) + 0.7152 * linear(pixels[offset + 1])
            + 0.0722 * linear(pixels[offset + 2]))
}
luminances.sort()
let background = luminances[luminances.count / 10]
let ink = luminances[luminances.count * 99 / 100]
let ratio = (ink + 0.05) / (background + 0.05)
print(String(format: "Rendered navigation-title contrast: %.2f:1", ratio))
if ratio < 4.5 { fail("The rendered title must have at least 4.5:1 contrast in its captured bounds.") }
