import AppKit

let root = FileManager.default.currentDirectoryPath
let output = "\(root)/test/evidence/run_motion_v7/left_leg_fix"
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

func frame(_ index: Int) -> NSImage {
  NSImage(contentsOfFile: "\(root)/assets/character/run_\(String(format: "%02d", index)).png")!
}

func save(_ image: NSImage, _ path: String) throws {
  let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
  try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let cell = NSSize(width: 128, height: 171)
let sheet = NSImage(size: NSSize(width: cell.width * 8, height: cell.height * 2))
sheet.lockFocus()
NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
NSRect(origin: .zero, size: sheet.size).fill()
for index in 0..<16 {
  let column = index % 8
  let row = 1 - index / 8
  frame(index).draw(
    in: NSRect(x: CGFloat(column) * cell.width, y: CGFloat(row) * cell.height, width: cell.width, height: cell.height),
    from: .zero,
    operation: .sourceOver,
    fraction: 1
  )
}
sheet.unlockFocus()
try save(sheet, "\(output)/run_sheet_16.png")

let comparison = NSImage(size: NSSize(width: 512, height: 342))
comparison.lockFocus()
NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
NSRect(origin: .zero, size: comparison.size).fill()
frame(6).draw(in: NSRect(x: 0, y: 0, width: 256, height: 342))
frame(12).draw(in: NSRect(x: 256, y: 0, width: 256, height: 342))
comparison.unlockFocus()
try save(comparison, "\(output)/right_left_forward.png")

func strip(_ indices: [Int], cell: NSSize = NSSize(width: 128, height: 171)) -> NSImage {
  let image = NSImage(size: NSSize(width: cell.width * CGFloat(indices.count), height: cell.height))
  image.lockFocus()
  NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
  NSRect(origin: .zero, size: image.size).fill()
  for (column, index) in indices.enumerated() {
    frame(index).draw(
      in: NSRect(x: CGFloat(column) * cell.width, y: 0, width: cell.width, height: cell.height),
      from: .zero,
      operation: .sourceOver,
      fraction: 1
    )
  }
  image.unlockFocus()
  return image
}

try save(strip(Array(6...10)), "\(output)/adjacent_motion_strip.png")
try save(strip([14, 15, 0, 1, 2]), "\(output)/seam_strip.png")
try save(strip(Array(8...14)), "\(output)/left_lead_strip.png")
try save(strip(Array(0...6)), "\(output)/right_lead_strip.png")

func labeledStrip(_ indices: [Int], labels: [String]) -> NSImage {
  let image = NSImage(size: NSSize(width: 256 * indices.count, height: 372))
  image.lockFocus()
  NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
  NSRect(origin: .zero, size: image.size).fill()
  let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .medium),
    .foregroundColor: NSColor.white,
  ]
  for (column, index) in indices.enumerated() {
    frame(index).draw(in: NSRect(x: column * 256, y: 0, width: 256, height: 342))
    (labels[column] as NSString).draw(at: NSPoint(x: column * 256 + 12, y: 346), withAttributes: attributes)
  }
  image.unlockFocus()
  return image
}
try save(labeledStrip(Array(6...14), labels: (6...14).map { "PHOTO \($0)" }), "\(output)/photo_06_to_14.png")
try save(labeledStrip(Array(9...12), labels: ["9 LEFT passing", "10 LEFT knee drive", "11 LEFT lead", "12 LEFT extension"]), "\(output)/left_four_poses.png")
try save(labeledStrip([6, 12], labels: ["RIGHT maximal lead", "LEFT maximal lead"]), "\(output)/right_left_maximal_lead.png")
