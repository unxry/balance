import AppKit
import CoreGraphics

struct Pixel {
  var r: Double
  var g: Double
  var b: Double
  var a: Double
}

func loadRGBA(_ path: String) throws -> (Int, Int, [UInt8]) {
  let data = try Data(contentsOf: URL(fileURLWithPath: path))
  guard let source = CGImageSourceCreateWithData(data as CFData, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    throw NSError(domain: "ActivitySprites", code: 1)
  }
  let width = image.width
  let height = image.height
  var bytes = [UInt8](repeating: 0, count: width * height * 4)
  let space = CGColorSpaceCreateDeviceRGB()
  let info = CGBitmapInfo.byteOrder32Big.union(
    CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
  )
  guard let context = CGContext(
    data: &bytes,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: space,
    bitmapInfo: info.rawValue
  ) else { throw NSError(domain: "ActivitySprites", code: 2) }
  context.translateBy(x: 0, y: CGFloat(height))
  context.scaleBy(x: 1, y: -1)
  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  return (width, height, bytes)
}

func averagePatch(
  _ bytes: [UInt8],
  imageWidth: Int,
  originX: Int,
  originY: Int,
  size: Int
) -> Pixel {
  var r = 0.0, g = 0.0, b = 0.0
  for y in originY..<(originY + size) {
    for x in originX..<(originX + size) {
      let offset = (y * imageWidth + x) * 4
      r += Double(bytes[offset])
      g += Double(bytes[offset + 1])
      b += Double(bytes[offset + 2])
    }
  }
  let count = Double(size * size)
  return Pixel(r: r / count, g: g / count, b: b / count, a: 255)
}

func mix(_ a: Pixel, _ b: Pixel, _ t: Double) -> Pixel {
  Pixel(
    r: a.r + (b.r - a.r) * t,
    g: a.g + (b.g - a.g) * t,
    b: a.b + (b.b - a.b) * t,
    a: a.a + (b.a - a.a) * t
  )
}

func smoothstep(_ value: Double) -> Double {
  let t = min(1, max(0, value))
  return t * t * (3 - 2 * t)
}

func unpremultiply(_ bytes: inout [UInt8]) {
  for offset in stride(from: 0, to: bytes.count, by: 4) {
    let alpha = Int(bytes[offset + 3])
    if alpha <= 3 {
      bytes[offset] = 0
      bytes[offset + 1] = 0
      bytes[offset + 2] = 0
      bytes[offset + 3] = 0
    } else if alpha < 255 {
      bytes[offset] = UInt8(min(255, Int(bytes[offset]) * 255 / alpha))
      bytes[offset + 1] = UInt8(min(255, Int(bytes[offset + 1]) * 255 / alpha))
      bytes[offset + 2] = UInt8(min(255, Int(bytes[offset + 2]) * 255 / alpha))
    }
  }
}

func decontaminateEdges(_ bytes: inout [UInt8], width: Int, height: Int) {
  let source = bytes
  for y in 0..<height {
    for x in 0..<width {
      let offset = (y * width + x) * 4
      let alpha = source[offset + 3]
      if alpha == 0 || alpha >= 250 { continue }
      var bestDistance = Int.max
      var bestOffset: Int?
      for dy in -5...5 {
        let candidateY = y + dy
        if candidateY < 0 || candidateY >= height { continue }
        for dx in -5...5 {
          let candidateX = x + dx
          if candidateX < 0 || candidateX >= width { continue }
          let distance = dx * dx + dy * dy
          if distance >= bestDistance { continue }
          let candidate = (candidateY * width + candidateX) * 4
          if source[candidate + 3] >= 250 {
            bestDistance = distance
            bestOffset = candidate
          }
        }
      }
      if let bestOffset {
        bytes[offset] = source[bestOffset]
        bytes[offset + 1] = source[bestOffset + 1]
        bytes[offset + 2] = source[bestOffset + 2]
      } else {
        bytes[offset] = 0
        bytes[offset + 1] = 0
        bytes[offset + 2] = 0
        bytes[offset + 3] = 0
      }
    }
  }
}

func removeResidualBlackMatte(_ bytes: inout [UInt8]) {
  for offset in stride(from: 0, to: bytes.count, by: 4) {
    let alpha = bytes[offset + 3]
    if alpha > 0 && alpha < 250 {
      bytes[offset] = max(32, bytes[offset])
      bytes[offset + 1] = max(32, bytes[offset + 1])
      bytes[offset + 2] = max(32, bytes[offset + 2])
    }
  }
}

func matchOliveTone(_ bytes: inout [UInt8], references: [[UInt8]]) {
  func mean(_ source: [UInt8]) -> (Double, Double, Double) {
    var red = 0.0
    var green = 0.0
    var blue = 0.0
    var count = 0.0
    for offset in stride(from: 0, to: source.count, by: 4) {
      let r = Double(source[offset])
      let g = Double(source[offset + 1])
      let b = Double(source[offset + 2])
      guard source[offset + 3] > 180, g > b * 1.18, g > r * 1.05 else { continue }
      red += r
      green += g
      blue += b
      count += 1
    }
    return (red / count, green / count, blue / count)
  }
  let sourceMean = mean(bytes)
  let targetMeans = references.map(mean)
  let target = (
    targetMeans.map(\.0).reduce(0, +) / Double(targetMeans.count),
    targetMeans.map(\.1).reduce(0, +) / Double(targetMeans.count),
    targetMeans.map(\.2).reduce(0, +) / Double(targetMeans.count)
  )
  let scales = (
    target.0 / sourceMean.0,
    target.1 / sourceMean.1,
    target.2 / sourceMean.2
  )
  for offset in stride(from: 0, to: bytes.count, by: 4) {
    let r = Double(bytes[offset])
    let g = Double(bytes[offset + 1])
    let b = Double(bytes[offset + 2])
    guard bytes[offset + 3] > 0, g > b * 1.18, g > r * 1.05 else { continue }
    bytes[offset] = UInt8(clamping: Int((r * scales.0).rounded()))
    bytes[offset + 1] = UInt8(clamping: Int((g * scales.1).rounded()))
    bytes[offset + 2] = UInt8(clamping: Int((b * scales.2).rounded()))
  }
}

func extractCell(
  bytes: [UInt8],
  imageWidth: Int,
  imageHeight: Int,
  column: Int,
  row: Int,
  columns: Int,
  rows: Int
) -> (Int, Int, [UInt8]) {
  let cellWidth = imageWidth / columns
  let cellHeight = imageHeight / rows
  let startX = column * cellWidth
  let startY = row * cellHeight
  let patch = max(6, min(cellWidth, cellHeight) / 36)
  let inset = max(5, patch)
  let topLeft = averagePatch(bytes, imageWidth: imageWidth, originX: startX + inset, originY: startY + inset, size: patch)
  let topRight = averagePatch(bytes, imageWidth: imageWidth, originX: startX + cellWidth - inset - patch, originY: startY + inset, size: patch)
  let bottomLeft = averagePatch(bytes, imageWidth: imageWidth, originX: startX + inset, originY: startY + cellHeight - inset - patch, size: patch)
  let bottomRight = averagePatch(bytes, imageWidth: imageWidth, originX: startX + cellWidth - inset - patch, originY: startY + cellHeight - inset - patch, size: patch)

  var foreground = [Pixel](repeating: Pixel(r: 0, g: 0, b: 0, a: 0), count: cellWidth * cellHeight)
  var interior = [Bool](repeating: false, count: cellWidth * cellHeight)
  for y in 0..<cellHeight {
    let v = Double(y) / Double(max(1, cellHeight - 1))
    let left = mix(topLeft, bottomLeft, v)
    let right = mix(topRight, bottomRight, v)
    for x in 0..<cellWidth {
      if x < 3 || y < 3 || x >= cellWidth - 3 || y >= cellHeight - 3 {
        continue
      }
      let u = Double(x) / Double(max(1, cellWidth - 1))
      let background = mix(left, right, u)
      let source = ((startY + y) * imageWidth + startX + x) * 4
      let r = Double(bytes[source])
      let g = Double(bytes[source + 1])
      let b = Double(bytes[source + 2])
      let delta = sqrt(
        (r - background.r) * (r - background.r) +
        (g - background.g) * (g - background.g) +
        (b - background.b) * (b - background.b)
      )
      let alpha = smoothstep((delta - 3.5) / 20.0)
      let index = y * cellWidth + x
      if alpha > 0.015 {
        foreground[index] = Pixel(r: r, g: g, b: b, a: alpha * 255)
      }
      interior[index] = alpha >= 0.96
    }
  }

  let radius = 7
  var output = [UInt8](repeating: 0, count: cellWidth * cellHeight * 4)
  for y in 0..<cellHeight {
    for x in 0..<cellWidth {
      let index = y * cellWidth + x
      let alpha = foreground[index].a
      guard alpha > 1 else { continue }
      var color = foreground[index]
      if !interior[index] {
        var bestDistance = Int.max
        var sumR = 0.0, sumG = 0.0, sumB = 0.0, count = 0.0
        for dy in -radius...radius {
          let candidateY = y + dy
          if candidateY < 0 || candidateY >= cellHeight { continue }
          for dx in -radius...radius {
            let candidateX = x + dx
            if candidateX < 0 || candidateX >= cellWidth { continue }
            let distance = dx * dx + dy * dy
            if distance > radius * radius { continue }
            let candidate = candidateY * cellWidth + candidateX
            if !interior[candidate] { continue }
            if distance < bestDistance {
              bestDistance = distance
              sumR = 0; sumG = 0; sumB = 0; count = 0
            }
            if distance <= bestDistance + 2 {
              sumR += foreground[candidate].r
              sumG += foreground[candidate].g
              sumB += foreground[candidate].b
              count += 1
            }
          }
        }
        if count > 0 {
          color.r = sumR / count
          color.g = sumG / count
          color.b = sumB / count
        } else {
          color.a = 0
        }
      }
      let target = index * 4
      output[target] = UInt8(min(255, max(0, color.r.rounded())))
      output[target + 1] = UInt8(min(255, max(0, color.g.rounded())))
      output[target + 2] = UInt8(min(255, max(0, color.b.rounded())))
      output[target + 3] = UInt8(min(255, max(0, color.a.rounded())))
    }
  }
  return (cellWidth, cellHeight, output)
}

func writePNG(width: Int, height: Int, bytes: [UInt8], path: String) throws {
  let data = Data(bytes)
  guard let provider = CGDataProvider(data: data as CFData) else { return }
  let info = CGBitmapInfo.byteOrder32Big.union(
    CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
  )
  guard let image = CGImage(
    width: width,
    height: height,
    bitsPerComponent: 8,
    bitsPerPixel: 32,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: info,
    provider: provider,
    decode: nil,
    shouldInterpolate: true,
    intent: .defaultIntent
  ) else { return }
  let destination = URL(fileURLWithPath: path) as CFURL
  guard let writer = CGImageDestinationCreateWithURL(destination, "public.png" as CFString, 1, nil) else { return }
  CGImageDestinationAddImage(writer, image, nil)
  guard CGImageDestinationFinalize(writer) else { throw NSError(domain: "ActivitySprites", code: 3) }
}

func resize(_ input: (Int, Int, [UInt8]), width: Int, height: Int) -> [UInt8] {
  let sourceData = Data(input.2)
  guard let provider = CGDataProvider(data: sourceData as CFData),
        let source = CGImage(
          width: input.0,
          height: input.1,
          bitsPerComponent: 8,
          bitsPerPixel: 32,
          bytesPerRow: input.0 * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)),
          provider: provider,
          decode: nil,
          shouldInterpolate: true,
          intent: .defaultIntent
        ) else { return [] }
  var result = [UInt8](repeating: 0, count: width * height * 4)
  guard let context = CGContext(
    data: &result,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)).rawValue
  ) else { return [] }
  context.interpolationQuality = .high
  context.translateBy(x: 0, y: CGFloat(height))
  context.scaleBy(x: 1, y: -1)
  context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
  let border = 2
  for y in 0..<height {
    for x in 0..<width where x < border || y < border || x >= width - border || y >= height - border {
      let offset = (y * width + x) * 4
      result[offset] = 0
      result[offset + 1] = 0
      result[offset + 2] = 0
      result[offset + 3] = 0
    }
  }
  unpremultiply(&result)
  decontaminateEdges(&result, width: width, height: height)
  return result
}

func fitResize(_ input: (Int, Int, [UInt8]), width: Int, height: Int) -> [UInt8] {
  let sourceData = Data(input.2)
  guard let provider = CGDataProvider(data: sourceData as CFData),
        let source = CGImage(
          width: input.0,
          height: input.1,
          bitsPerComponent: 8,
          bitsPerPixel: 32,
          bytesPerRow: input.0 * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)),
          provider: provider,
          decode: nil,
          shouldInterpolate: true,
          intent: .defaultIntent
        ) else { return [] }
  var result = [UInt8](repeating: 0, count: width * height * 4)
  guard let context = CGContext(
    data: &result,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)).rawValue
  ) else { return [] }
  let scale = min(Double(width) / Double(input.0), Double(height) / Double(input.1))
  let drawWidth = Double(input.0) * scale
  let drawHeight = Double(input.1) * scale
  context.interpolationQuality = .high
  context.translateBy(x: 0, y: CGFloat(height))
  context.scaleBy(x: 1, y: -1)
  context.draw(
    source,
    in: CGRect(
      x: (Double(width) - drawWidth) / 2,
      y: (Double(height) - drawHeight) / 2,
      width: drawWidth,
      height: drawHeight
    )
  )
  unpremultiply(&result)
  decontaminateEdges(&result, width: width, height: height)
  return result
}

func alphaBounds(_ bytes: [UInt8], width: Int, height: Int) -> CGRect {
  var minX = width, minY = height, maxX = 0, maxY = 0
  for y in 0..<height {
    for x in 0..<width where bytes[(y * width + x) * 4 + 3] > 16 {
      minX = min(minX, x)
      minY = min(minY, y)
      maxX = max(maxX, x)
      maxY = max(maxY, y)
    }
  }
  return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

func gaitAnchor(_ bytes: [UInt8], width: Int, height: Int) -> (Double, Int) {
  let bounds = alphaBounds(bytes, width: width, height: height)
  let headBottom = min(height, Int(bounds.minY) + Int(Double(height) * 0.24))
  var sumX = 0.0
  var count = 0.0
  for y in Int(bounds.minY)..<headBottom {
    for x in 0..<width where bytes[(y * width + x) * 4 + 3] >= 240 {
      sumX += Double(x)
      count += 1
    }
  }
  return (sumX / max(1, count), Int(bounds.maxY))
}

func headCentroid(_ bytes: [UInt8], width: Int, height: Int) -> (Double, Double) {
  let bounds = alphaBounds(bytes, width: width, height: height)
  let top = Int(bounds.minY)
  let bottom = min(height - 1, top + Int(Double(height) * 0.17))
  var sumX = 0.0, sumY = 0.0, count = 0.0
  for y in top...bottom {
    for x in 0..<width where bytes[(y * width + x) * 4 + 3] >= 240 {
      sumX += Double(x)
      sumY += Double(y)
      count += 1
    }
  }
  return (sumX / max(1, count), sumY / max(1, count))
}

func stabilizeHeadAnchor(
  _ input: [UInt8],
  width: Int,
  height: Int,
  target: (Double, Double)
) -> [UInt8] {
  let anchor = headCentroid(input, width: width, height: height)
  let shiftX = Int((target.0 - anchor.0).rounded())
  let shiftY = Int((target.1 - anchor.1).rounded())
  var result = [UInt8](repeating: 0, count: input.count)
  for sourceY in 0..<height {
    let targetY = sourceY + shiftY
    guard targetY >= 0, targetY < height else { continue }
    for sourceX in 0..<width {
      let targetX = sourceX + shiftX
      guard targetX >= 0, targetX < width else { continue }
      let source = (sourceY * width + sourceX) * 4
      let destination = (targetY * width + targetX) * 4
      result[destination..<(destination + 4)] = input[source..<(source + 4)]
    }
  }
  return result
}

func stabilizeGaitAnchor(
  _ input: [UInt8],
  width: Int,
  height: Int,
  targetHeadX: Double,
  targetGround: Int
) -> [UInt8] {
  let anchor = gaitAnchor(input, width: width, height: height)
  let shiftX = Int((targetHeadX - anchor.0).rounded())
  let shiftY = targetGround - anchor.1
  var result = [UInt8](repeating: 0, count: input.count)
  for sourceY in 0..<height {
    let targetY = sourceY + shiftY
    guard targetY >= 0, targetY < height else { continue }
    for sourceX in 0..<width {
      let targetX = sourceX + shiftX
      guard targetX >= 0, targetX < width else { continue }
      let source = (sourceY * width + sourceX) * 4
      let target = (targetY * width + targetX) * 4
      result[target..<(target + 4)] = input[source..<(source + 4)]
    }
  }
  return result
}

/// Places one accepted idle drawing on the same fixed canvas/visual scale as
/// the gait sheets. This is one group-level transform, never per-pose fitting.
func placeIdleOnMasterCanvas(
  _ input: [UInt8],
  width: Int,
  height: Int,
  targetBodyHeight: Double,
  targetGround: Double
) -> [UInt8] {
  let bounds = alphaBounds(input, width: width, height: height)
  let scale = targetBodyHeight / bounds.height
  let drawX = Double(width) / 2 - bounds.midX * scale
  let drawY = targetGround - bounds.maxY * scale
  let sourceData = Data(input)
  guard let provider = CGDataProvider(data: sourceData as CFData),
        let source = CGImage(
          width: width,
          height: height,
          bitsPerComponent: 8,
          bitsPerPixel: 32,
          bytesPerRow: width * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)),
          provider: provider,
          decode: nil,
          shouldInterpolate: true,
          intent: .defaultIntent
        ) else { return [] }
  var result = [UInt8](repeating: 0, count: width * height * 4)
  guard let context = CGContext(
    data: &result,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)).rawValue
  ) else { return [] }
  context.interpolationQuality = .high
  context.translateBy(x: 0, y: CGFloat(height))
  context.scaleBy(x: 1, y: -1)
  context.draw(
    source,
    in: CGRect(
      x: drawX,
      y: drawY,
      width: Double(width) * scale,
      height: Double(height) * scale
    )
  )
  unpremultiply(&result)
  decontaminateEdges(&result, width: width, height: height)
  return result
}

func placeOnMasterCanvas(
  _ input: (Int, Int, [UInt8]),
  width: Int,
  height: Int,
  targetBodyHeight: Double,
  targetHeadX: Double,
  targetGround: Double
) -> [UInt8] {
  let bounds = alphaBounds(input.2, width: input.0, height: input.1)
  let sourceAnchor = gaitAnchor(input.2, width: input.0, height: input.1)
  let scale = targetBodyHeight / bounds.height
  let drawX = targetHeadX - sourceAnchor.0 * scale
  let drawY = targetGround - bounds.maxY * scale
  let sourceData = Data(input.2)
  guard let provider = CGDataProvider(data: sourceData as CFData),
        let source = CGImage(
          width: input.0,
          height: input.1,
          bitsPerComponent: 8,
          bitsPerPixel: 32,
          bytesPerRow: input.0 * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)),
          provider: provider,
          decode: nil,
          shouldInterpolate: true,
          intent: .defaultIntent
        ) else { return [] }
  var result = [UInt8](repeating: 0, count: width * height * 4)
  guard let context = CGContext(
    data: &result,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)).rawValue
  ) else { return [] }
  context.interpolationQuality = .high
  context.translateBy(x: 0, y: CGFloat(height))
  context.scaleBy(x: 1, y: -1)
  context.draw(
    source,
    in: CGRect(
      x: drawX,
      y: drawY,
      width: Double(input.0) * scale,
      height: Double(input.1) * scale
    )
  )
  unpremultiply(&result)
  decontaminateEdges(&result, width: width, height: height)
  return result
}

func flipVerticalAndShift(
  _ input: [UInt8],
  width: Int,
  height: Int,
  shiftY: Int
) -> [UInt8] {
  var result = [UInt8](repeating: 0, count: input.count)
  for sourceY in 0..<height {
    let targetY = height - 1 - sourceY + shiftY
    guard targetY >= 0, targetY < height else { continue }
    for x in 0..<width {
      let source = (sourceY * width + x) * 4
      let target = (targetY * width + x) * 4
      result[target..<(target + 4)] = input[source..<(source + 4)]
    }
  }
  return result
}

func exportSheet(
  source: String,
  output: String,
  prefix: String,
  width: Int,
  height: Int,
  cleanBlackMatte: Bool = false,
  indices: Range<Int> = 0..<8
) throws {
  let image = try loadRGBA(source)
  try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
  for index in indices {
    let cell = extractCell(
      bytes: image.2,
      imageWidth: image.0,
      imageHeight: image.1,
      column: index % 4,
      row: 1 - index / 4,
      columns: 4,
      rows: 2
    )
    var scaled = resize(cell, width: width, height: height)
    if cleanBlackMatte { removeResidualBlackMatte(&scaled) }
    try writePNG(width: width, height: height, bytes: scaled, path: "\(output)/\(prefix)_\(String(format: "%02d", index)).png")
  }
}

func exportRunInterleavedSheets(
  leftKeys: String,
  rightKeys: String,
  inbetweens: [String],
  anchorOverrides: [String?],
  lockedCanvas: Bool = false,
  output: String,
  prefix: String,
  width: Int,
  height: Int
) throws {
  let nativeDirectory = "\(FileManager.default.currentDirectoryPath)/test/evidence/run_motion_v7/bilateral_fix"
  if FileManager.default.fileExists(atPath: "\(nativeDirectory)/native_export.json") {
    let nativePrefix = prefix == "dashboard_run" ? "dashboard_frame" : "frame"
    try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
    for index in 0..<16 {
      let suffix = String(format: "%02d", index)
      let path = "\(nativeDirectory)/\(nativePrefix)_\(suffix).png"
      let image = try loadRGBA(path)
      precondition(image.0 == width && image.1 == height, "Native RUN canvas changed")
      try Data(contentsOf: URL(fileURLWithPath: path)).write(
        to: URL(fileURLWithPath: "\(output)/\(prefix)_\(suffix).png"), options: .atomic
      )
    }
    return
  }
  let keySheets = [try loadRGBA(leftKeys), try loadRGBA(rightKeys)]
  let midpointImages = try inbetweens.map(loadRGBA)
  func sourceAnchor(_ index: Int) -> [UInt8] {
    let sheet = keySheets[index < 4 ? 0 : 1]
    let cell = extractCell(
      bytes: sheet.2,
      imageWidth: sheet.0,
      imageHeight: sheet.1,
      column: index % 4,
      row: 1 - index / 4,
      columns: 4,
      rows: 2
    )
    return resize(cell, width: width, height: height)
  }
  let lockedReference = sourceAnchor(0)
  let lockedTarget = headCentroid(lockedReference, width: width, height: height)
  var anchorFrames = [[UInt8]]()
  for index in 0..<8 {
    let reference = sourceAnchor(index)
    guard index < anchorOverrides.count, let path = anchorOverrides[index] else {
      anchorFrames.append(reference)
      continue
    }
    let image = try loadRGBA(path)
    if lockedCanvas {
      var replacement = resize(image, width: width, height: height)
      replacement = stabilizeHeadAnchor(
        replacement,
        width: width,
        height: height,
        target: lockedTarget
      )
      matchOliveTone(&replacement, references: [sourceAnchor(0)])
      anchorFrames.append(replacement)
      continue
    }
    let bounds = alphaBounds(reference, width: width, height: height)
    let anchor = gaitAnchor(reference, width: width, height: height)
    var replacement = placeOnMasterCanvas(
      image,
      width: width,
      height: height,
      targetBodyHeight: bounds.height,
      targetHeadX: anchor.0,
      targetGround: Double(anchor.1)
    )
    replacement = stabilizeGaitAnchor(
      replacement,
      width: width,
      height: height,
      targetHeadX: anchor.0,
      targetGround: anchor.1
    )
    matchOliveTone(&replacement, references: [reference])
    anchorFrames.append(replacement)
  }
  try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
  for keyIndex in 0..<8 {
    for phase in 0..<2 {
      var scaled: [UInt8]
      if phase == 0 {
        scaled = anchorFrames[keyIndex]
      } else {
        let image = midpointImages[keyIndex]
        if lockedCanvas {
          scaled = resize(image, width: width, height: height)
          scaled = stabilizeHeadAnchor(
            scaled,
            width: width,
            height: height,
            target: lockedTarget
          )
          matchOliveTone(&scaled, references: [sourceAnchor(0)])
          removeResidualBlackMatte(&scaled)
          let frame = keyIndex * 2 + phase
          try writePNG(
            width: width,
            height: height,
            bytes: scaled,
            path: "\(output)/\(prefix)_\(String(format: "%02d", frame)).png"
          )
          continue
        }
        let cell = extractCell(
          bytes: image.2,
          imageWidth: image.0,
          imageHeight: image.1,
          column: 0,
          row: 0,
          columns: 1,
          rows: 1
        )
        let a = anchorFrames[keyIndex]
        let b = anchorFrames[(keyIndex + 1) % 8]
        let aAnchor = gaitAnchor(a, width: width, height: height)
        let bAnchor = gaitAnchor(b, width: width, height: height)
        let aBounds = alphaBounds(a, width: width, height: height)
        let bBounds = alphaBounds(b, width: width, height: height)
        let targetHeadX = (aAnchor.0 + bAnchor.0) / 2
        let targetGround = (aAnchor.1 + bAnchor.1) / 2
        let targetBodyHeight = (aBounds.height + bBounds.height) / 2
        scaled = placeOnMasterCanvas(
          cell,
          width: width,
          height: height,
          targetBodyHeight: targetBodyHeight,
          targetHeadX: targetHeadX,
          targetGround: Double(targetGround)
        )
        scaled = stabilizeGaitAnchor(
          scaled,
          width: width,
          height: height,
          targetHeadX: targetHeadX,
          targetGround: targetGround
        )
        matchOliveTone(&scaled, references: [a, b])
      }
      removeResidualBlackMatte(&scaled)
      let frame = keyIndex * 2 + phase
      try writePNG(
        width: width,
        height: height,
        bytes: scaled,
        path: "\(output)/\(prefix)_\(String(format: "%02d", frame)).png"
      )
    }
  }
}

func exportInterleavedSheets(
  keys: String,
  inbetweens: String,
  output: String,
  prefix: String,
  width: Int,
  height: Int
) throws {
  let approved = "\(root)/test/evidence/walk_motion_repair"
  if FileManager.default.fileExists(atPath: "\(approved)/native_export.json") {
    for frame in 0..<16 {
      let index = String(format: "%02d", frame)
      let source = "\(approved)/\(prefix == "walk" ? "frame" : "dashboard_frame")_\(index).png"
      let target = "\(output)/\(prefix)_\(index).png"
      try Data(contentsOf: URL(fileURLWithPath: source)).write(to: URL(fileURLWithPath: target))
    }
    return
  }
  let sheets = [try loadRGBA(keys), try loadRGBA(inbetweens)]
  try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
  let firstCell = extractCell(
    bytes: sheets[0].2,
    imageWidth: sheets[0].0,
    imageHeight: sheets[0].1,
    column: 0,
    row: 1,
    columns: 4,
    rows: 2
  )
  let target = gaitAnchor(resize(firstCell, width: width, height: height), width: width, height: height)
  for keyIndex in 0..<8 {
    for sheetIndex in 0..<2 {
      let image = sheets[sheetIndex]
      let cell = extractCell(
        bytes: image.2,
        imageWidth: image.0,
        imageHeight: image.1,
        column: keyIndex % 4,
        row: 1 - keyIndex / 4,
        columns: 4,
        rows: 2
      )
      var scaled = stabilizeGaitAnchor(
        resize(cell, width: width, height: height),
        width: width,
        height: height,
        targetHeadX: target.0,
        targetGround: target.1
      )
      removeResidualBlackMatte(&scaled)
      let frame = keyIndex * 2 + sheetIndex
      try writePNG(
        width: width,
        height: height,
        bytes: scaled,
        path: "\(output)/\(prefix)_\(String(format: "%02d", frame)).png"
      )
    }
  }
}

func exportTransitionSheet(
  source: String,
  count: Int,
  output: String,
  prefix: String,
  width: Int,
  height: Int,
  startReference: String,
  endReference: String
) throws {
  let approved = "\(root)/test/evidence/walk_motion_repair"
  if prefix.hasSuffix("transition_idle_walk") && FileManager.default.fileExists(atPath: "\(approved)/native_export.json") {
    for frame in 0..<count {
      let index = String(format: "%02d", frame)
      let source = "\(approved)/\(prefix.hasPrefix("dashboard_") ? "dashboard_transition" : "transition")_\(index).png"
      try Data(contentsOf: URL(fileURLWithPath: source)).write(to: URL(fileURLWithPath: "\(output)/\(prefix)_\(index).png"))
    }
    return
  }
  let sheet = try loadRGBA(source)
  let start = try loadRGBA(startReference)
  let end = try loadRGBA(endReference)
  let startAnchor = gaitAnchor(start.2, width: start.0, height: start.1)
  let endAnchor = gaitAnchor(end.2, width: end.0, height: end.1)
  let startBounds = alphaBounds(start.2, width: start.0, height: start.1)
  let endBounds = alphaBounds(end.2, width: end.0, height: end.1)
  for index in 0..<count {
    let progress = Double(index) / Double(count - 1)
    let targetHeadX = startAnchor.0 + (endAnchor.0 - startAnchor.0) * progress
    let targetGround = Double(startAnchor.1) + Double(endAnchor.1 - startAnchor.1) * progress
    let targetBodyHeight = startBounds.height + (endBounds.height - startBounds.height) * progress
    let cell = extractCell(
      bytes: sheet.2,
      imageWidth: sheet.0,
      imageHeight: sheet.1,
      column: index,
      row: 0,
      columns: count,
      rows: 1
    )
    let placed = placeOnMasterCanvas(
      cell,
      width: width,
      height: height,
      targetBodyHeight: targetBodyHeight,
      targetHeadX: targetHeadX,
      targetGround: targetGround
    )
    let aligned = stabilizeGaitAnchor(
      placed,
      width: width,
      height: height,
      targetHeadX: targetHeadX,
      targetGround: Int(targetGround.rounded())
    )
    try writePNG(
      width: width,
      height: height,
      bytes: aligned,
      path: "\(output)/\(prefix)_\(String(format: "%02d", index)).png"
    )
  }
}

let root = FileManager.default.currentDirectoryPath
let output = "\(root)/assets/character"
let runOnly = ProcessInfo.processInfo.environment["RUN_ONLY"] == "1"
if !runOnly {
  try exportInterleavedSheets(
  keys: "\(root)/test/goldens/activity_character_walk_cycle_bilateral_v3.png",
  inbetweens: "\(root)/test/goldens/activity_character_walk_inbetweens_bilateral_v3.png",
  output: output,
  prefix: "walk",
  width: 256,
  height: 342
  )
}
try exportRunInterleavedSheets(
  leftKeys: "\(root)/test/goldens/activity_character_run_cycle_tone_v8.png",
  rightKeys: "\(root)/test/goldens/activity_character_run_cycle_tone_v8.png",
  inbetweens: (1...8).map { "\(root)/test/goldens/run_motion_v7/midpoints/r\($0)_5.png" },
  anchorOverrides: (1...8).map { "\(root)/test/goldens/run_motion_v7/anchors/r\($0).png" },
  lockedCanvas: true,
  output: output,
  prefix: "run",
  width: 256,
  height: 342
)

if !runOnly {
  try exportInterleavedSheets(
  keys: "\(root)/test/goldens/activity_character_walk_cycle_bilateral_v3.png",
  inbetweens: "\(root)/test/goldens/activity_character_walk_inbetweens_bilateral_v3.png",
  output: output,
  prefix: "dashboard_walk",
  width: 128,
  height: 171
  )
}
try exportRunInterleavedSheets(
  leftKeys: "\(root)/test/goldens/activity_character_run_cycle_tone_v8.png",
  rightKeys: "\(root)/test/goldens/activity_character_run_cycle_tone_v8.png",
  inbetweens: (1...8).map { "\(root)/test/goldens/run_motion_v7/midpoints/r\($0)_5.png" },
  anchorOverrides: (1...8).map { "\(root)/test/goldens/run_motion_v7/anchors/r\($0).png" },
  lockedCanvas: true,
  output: output,
  prefix: "dashboard_run",
  width: 128,
  height: 171
)

if !runOnly {
try exportTransitionSheet(
  source: "\(root)/test/goldens/activity_character_idle_walk_transition_v1.png",
  count: 4,
  output: output,
  prefix: "transition_idle_walk",
  width: 256,
  height: 342,
  startReference: "\(output)/idle.png",
  endReference: "\(output)/walk_00.png"
)
try exportTransitionSheet(
  source: "\(root)/test/goldens/activity_character_walk_run_transition_v1.png",
  count: 5,
  output: output,
  prefix: "transition_walk_run",
  width: 256,
  height: 342,
  startReference: "\(output)/walk_00.png",
  endReference: "\(output)/run_00.png"
)
try exportTransitionSheet(
  source: "\(root)/test/goldens/activity_character_idle_walk_transition_v1.png",
  count: 4,
  output: output,
  prefix: "dashboard_transition_idle_walk",
  width: 128,
  height: 171,
  startReference: "\(output)/dashboard_idle.png",
  endReference: "\(output)/dashboard_walk_00.png"
)
try exportTransitionSheet(
  source: "\(root)/test/goldens/activity_character_walk_run_transition_v1.png",
  count: 5,
  output: output,
  prefix: "dashboard_transition_walk_run",
  width: 128,
  height: 171,
  startReference: "\(output)/dashboard_walk_00.png",
  endReference: "\(output)/dashboard_run_00.png"
)

let canonical = try loadRGBA("\(root)/test/goldens/activity_character_canonical_static_v2.png")
let idle = extractCell(
  bytes: canonical.2,
  imageWidth: canonical.0,
  imageHeight: canonical.1,
  column: 0,
  row: 2,
  columns: 3,
  rows: 3
)
let fullIdle = flipVerticalAndShift(
  placeIdleOnMasterCanvas(
    fitResize(idle, width: 256, height: 342),
    width: 256,
    height: 342,
    targetBodyHeight: 291,
    targetGround: 353
  ),
  width: 256,
  height: 342,
  shiftY: 22
)
try writePNG(
  width: 256,
  height: 342,
  bytes: fullIdle,
  path: "\(output)/idle.png"
)
let compactIdle = flipVerticalAndShift(
  placeIdleOnMasterCanvas(
    fitResize(idle, width: 128, height: 171),
    width: 128,
    height: 171,
    targetBodyHeight: 140,
    targetGround: 173
  ),
  width: 128,
  height: 171,
  shiftY: 9
)
try writePNG(
  width: 128,
  height: 171,
  bytes: compactIdle,
  path: "\(output)/dashboard_idle.png"
)
}
