#!/usr/bin/env swift

import Cocoa
import Vision

let lastScreenshotPath = "/tmp/ohseeare_last.png"

func getDimensions(_ imagePath: String) -> (width: Int, height: Int)? {
    guard let img = CIImage(contentsOf: URL(fileURLWithPath: imagePath)) else {
        return nil
    }
    let imgRep = NSCIImageRep(ciImage: img)
    return (imgRep.pixelsWide, imgRep.pixelsHigh)
}

func captureScreenshot() -> String? {
    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = ["-i", lastScreenshotPath]
    task.launch()

    var attempts = 0
    while attempts < 300 {
        Thread.sleep(forTimeInterval: 0.1)
        if FileManager.default.fileExists(atPath: lastScreenshotPath) {
            Thread.sleep(forTimeInterval: 0.2)
            let attrs = try? FileManager.default.attributesOfItem(atPath: lastScreenshotPath)
            if let size = attrs?[.size] as? UInt64, size > 0 {
                break
            }
        }
        attempts += 1
    }
    task.waitUntilExit()

    return FileManager.default.fileExists(atPath: lastScreenshotPath) ? lastScreenshotPath : nil
}

func saveToDownloads(_ imagePath: String) -> String? {
    let downloadsPath = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
    let timestamp = DateFormatter().string(from: Date())
    let filename = "screenshot_\(timestamp).png"
    let savePath = downloadsPath.appendingPathComponent(filename)

    do {
        try FileManager.default.copyItem(atPath: imagePath, toPath: savePath.path)
        return filename
    } catch {
        return nil
    }
}

func performOCR(_ imagePath: String) -> String? {
    guard let img = CIImage(contentsOf: URL(fileURLWithPath: imagePath)) else {
        return nil
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(ciImage: img, options: [:])
    do {
        try handler.perform([request])
        guard let results = request.results, !results.isEmpty else {
            return nil
        }

        var lines: [String] = []
        for result in results {
            if let candidate = result.topCandidates(1).first {
                lines.append(candidate.string)
            }
        }
        return lines.joined(separator: "\n")
    } catch {
        return nil
    }
}

func copyImageToClipboard(_ imagePath: String) {
    guard let img = NSImage(contentsOfFile: imagePath),
          let tiffRep = img.tiffRepresentation,
          let pngData = NSBitmapImageRep(data: tiffRep)?.representation(using: .png, properties: [:]) else {
        return
    }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setData(pngData, forType: .string)
}

func copyTextToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

// Main
let args = CommandLine.arguments

if args.contains("--ocr") || args.contains("-o") {
    // OCR mode
    if FileManager.default.fileExists(atPath: lastScreenshotPath),
       let text = performOCR(lastScreenshotPath),
       !text.isEmpty {
        copyTextToClipboard(text)
        print("✓ Text copied to clipboard (\(text.count) chars)")
    } else {
        print("✗ No screenshot or text found")
    }
} else {
    // Screenshot mode
    if let imagePath = captureScreenshot() {
        if let dims = getDimensions(imagePath) {
            print("✓ \(dims.width) × \(dims.height) px")
        }

        copyImageToClipboard(imagePath)

        if let filename = saveToDownloads(imagePath) {
            print("✓ Saved to Downloads: \(filename)")
        }
    } else {
        print("✗ Screenshot cancelled")
    }
}
