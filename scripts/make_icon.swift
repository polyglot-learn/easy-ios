// Render a 1024x1024 app icon: a vertical gradient with a white SF Symbol.
// Usage: swift scripts/make_icon.swift <sf-symbol> <hex-color> <output.png>
import AppKit

let args = CommandLine.arguments
guard args.count == 4 else {
    FileHandle.standardError.write("usage: make_icon.swift <sf-symbol> <hex-color> <output.png>\n".data(using: .utf8)!)
    exit(2)
}
let (symbolName, hex, output) = (args[1], args[2], args[3])

func color(_ hex: String) -> NSColor {
    let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    return NSColor(
        srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
        green: CGFloat((value >> 8) & 0xFF) / 255,
        blue: CGFloat(value & 0xFF) / 255,
        alpha: 1
    )
}

let size = 1024
// No alpha channel: App Store icons must be opaque.
let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

let base = color(hex)
let rect = NSRect(x: 0, y: 0, width: size, height: size)
NSGradient(
    starting: base.blended(withFraction: 0.25, of: .white)!,
    ending: base.blended(withFraction: 0.2, of: .black)!
)!.draw(in: rect, angle: -90)

guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
    FileHandle.standardError.write("unknown SF Symbol: \(symbolName)\n".data(using: .utf8)!)
    exit(1)
}
let config = NSImage.SymbolConfiguration(pointSize: 480, weight: .semibold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
let image = symbol.withSymbolConfiguration(config)!
let s = image.size
image.draw(in: NSRect(x: (CGFloat(size) - s.width) / 2, y: (CGFloat(size) - s.height) / 2, width: s.width, height: s.height))

let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: output))
