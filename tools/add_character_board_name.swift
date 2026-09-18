import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

enum NamePlateError: Error {
    case cannotReadImage
    case cannotCreateContext
    case cannotCreateOutput
}

guard CommandLine.arguments.count == 4 else {
    fputs("usage: swift tools/add_character_board_name.swift INPUT.png OUTPUT.png NAME\n", stderr)
    exit(64)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]
let characterName = CommandLine.arguments[3]

guard characterName.count == 3 else {
    fputs("character name must contain exactly three Chinese characters\n", stderr)
    exit(64)
}

let inputURL = URL(fileURLWithPath: inputPath) as CFURL
guard
    let source = CGImageSourceCreateWithURL(inputURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
    throw NamePlateError.cannotReadImage
}

let width = image.width
let height = image.height
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    throw NamePlateError.cannotCreateContext
}

context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

// Coordinates are defined from the visual top-left, then converted to Core Graphics.
let plateX: CGFloat = 48
let plateTop: CGFloat = 48
let plateWidth: CGFloat = 88
let plateHeight: CGFloat = 238
let plateRect = CGRect(
    x: plateX,
    y: CGFloat(height) - plateTop - plateHeight,
    width: plateWidth,
    height: plateHeight
)

context.saveGState()
context.setFillColor(CGColor(red: 0.46, green: 0.41, blue: 0.33, alpha: 0.30))
context.fill(plateRect)

let ink = CGColor(red: 0.08, green: 0.075, blue: 0.065, alpha: 0.92)
context.setStrokeColor(ink)
context.setLineWidth(2.2)
context.stroke(plateRect)
context.setLineWidth(0.9)
context.stroke(plateRect.insetBy(dx: 5.5, dy: 5.5))

let font = CTFontCreateWithName("STKaiti" as CFString, 48, nil)
let attributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key(kCTFontAttributeName as String): font,
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): ink
]

for (index, character) in characterName.enumerated() {
    let attributed = NSAttributedString(string: String(character), attributes: attributes)
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    let x = plateX + (plateWidth - bounds.width) / 2 - bounds.minX
    let glyphTop = plateTop + 25 + CGFloat(index) * 66
    let baselineY = CGFloat(height) - glyphTop - bounds.maxY
    context.textPosition = CGPoint(x: x, y: baselineY)
    CTLineDraw(line, context)
}
context.restoreGState()

guard let outputImage = context.makeImage() else {
    throw NamePlateError.cannotCreateOutput
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    throw NamePlateError.cannotCreateOutput
}

CGImageDestinationAddImage(destination, outputImage, nil)
guard CGImageDestinationFinalize(destination) else {
    throw NamePlateError.cannotCreateOutput
}
