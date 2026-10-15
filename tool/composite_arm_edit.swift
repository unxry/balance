import AppKit
import Foundation

guard CommandLine.arguments.count == 4 else {
  fatalError("Usage: composite_arm_edit.swift <original.png> <arm-edit.png> <output.png>")
}

guard
  let original = NSImage(contentsOfFile: CommandLine.arguments[1]),
  let edit = NSImage(contentsOfFile: CommandLine.arguments[2]),
  let originalRep = NSBitmapImageRep(
    data: try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
  )
else {
  fatalError("Could not load input images")
}

let width = originalRep.pixelsWide
let height = originalRep.pixelsHigh
let size = NSSize(width: width, height: height)

func render(_ image: NSImage) -> NSBitmapImageRep {
  let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: width * 4,
    bitsPerPixel: 32
  )!
  let context = NSGraphicsContext(bitmapImageRep: rep)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  NSColor.clear.setFill()
  NSRect(origin: .zero, size: size).fill()
  image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
  context.flushGraphics()
  NSGraphicsContext.restoreGraphicsState()
  return rep
}

func point(_ x: CGFloat, _ yFromTop: CGFloat) -> NSPoint {
  NSPoint(x: x, y: size.height - yFromTop)
}

func polygon(_ points: [(CGFloat, CGFloat)]) -> NSBezierPath {
  let path = NSBezierPath()
  path.move(to: point(points[0].0, points[0].1))
  for p in points.dropFirst() { path.line(to: point(p.0, p.1)) }
  path.close()
  return path
}

let maskRep = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: width,
  pixelsHigh: height,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: width * 4,
  bitsPerPixel: 32
)!
let maskContext = NSGraphicsContext(bitmapImageRep: maskRep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = maskContext
NSColor.black.setFill()
NSRect(origin: .zero, size: size).fill()
NSColor.white.setFill()
polygon([
  (140, 390), (510, 360), (590, 440), (560, 620),
  (480, 790), (190, 790), (110, 620),
]).fill()
polygon([
  (480, 380), (720, 360), (1_060, 450), (1_075, 740),
  (760, 810), (490, 710), (430, 500),
]).fill()
maskContext.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

let originalPixels = render(original)
let editPixels = render(edit)
let output = render(original)
let originalBytes = originalPixels.bitmapData!
let editBytes = editPixels.bitmapData!
let outputBytes = output.bitmapData!
let maskBytes = maskRep.bitmapData!

var mask = [Int](repeating: 0, count: width * height)
for y in 0..<height {
  for x in 0..<width {
    mask[y * width + x] = Int(maskBytes[y * maskRep.bytesPerRow + x * 4])
  }
}

let radius = 10
var horizontal = [Int](repeating: 0, count: mask.count)
for y in 0..<height {
  var sum = 0
  for x in -radius...radius where x >= 0 && x < width {
    sum += mask[y * width + x]
  }
  for x in 0..<width {
    horizontal[y * width + x] = sum / (radius * 2 + 1)
    let remove = x - radius
    let add = x + radius + 1
    if remove >= 0 { sum -= mask[y * width + remove] }
    if add < width { sum += mask[y * width + add] }
  }
}
for x in 0..<width {
  var sum = 0
  for y in -radius...radius where y >= 0 && y < height {
    sum += horizontal[y * width + x]
  }
  for y in 0..<height {
    var weight = sum / (radius * 2 + 1)
    let yFromTop = height - 1 - y
    if x >= 450 && x < 950 && yFromTop < 470 { weight = 0 }
    let offset = y * output.bytesPerRow + x * 4
    for channel in 0..<4 {
      outputBytes[offset + channel] = UInt8(
        (Int(originalBytes[offset + channel]) * (255 - weight) +
          Int(editBytes[offset + channel]) * weight) / 255
      )
    }
    let remove = y - radius
    let add = y + radius + 1
    if remove >= 0 { sum -= horizontal[remove * width + x] }
    if add < height { sum += horizontal[add * width + x] }
  }
}

let data = output.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
