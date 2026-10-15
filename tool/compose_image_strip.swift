import AppKit
import Foundation

guard CommandLine.arguments.count >= 4 else {
  fatalError("Usage: compose_image_strip.swift <output.png> <input.png>...")
}

let inputs = try CommandLine.arguments.dropFirst(2).map { path -> NSImage in
  guard let image = NSImage(contentsOfFile: path) else {
    throw NSError(domain: "ImageStrip", code: 1)
  }
  return image
}
let height = Int(inputs.map(\.size.height).max()!)
let width = Int(inputs.map(\.size.width).reduce(0, +))
let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: width,
  pixelsHigh: height,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
var x = 0.0
for image in inputs {
  image.draw(at: NSPoint(x: x, y: 0), from: .zero, operation: .sourceOver, fraction: 1)
  x += image.size.width
}
context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
