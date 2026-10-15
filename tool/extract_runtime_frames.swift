import AVFoundation
import AppKit
import Foundation

guard CommandLine.arguments.count >= 4 else {
  fatalError("Usage: extract_runtime_frames.swift <video> <output-dir> <seconds>...")
}

let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

for value in CommandLine.arguments.dropFirst(3) {
  let seconds = Double(value)!
  let image = try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600)).image
  let bitmap = NSBitmapImageRep(cgImage: image)
  let data = bitmap.representation(using: .png, properties: [:])!
  try data.write(to: output.appendingPathComponent("frame_\(value.replacingOccurrences(of: ".", with: "_"))s.png"))
}
