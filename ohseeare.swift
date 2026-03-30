#!/usr/bin/env swift

import Cocoa
import Vision

// Simple screenshot OCR that:
// 1. Takes screenshot (Cmd+Shift+4 mode)
// 2. Runs OCR
// 3. Copies to clipboard
// 4. Saves screenshot to Downloads
// Usage: ohseeare

func getDownloadsPath() -> URL {
    let fileManager = FileManager.default
    let downloadsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    return downloadsURL.appendingPathComponent("Downloads")
}

func captureScreenshot() -> (imagePath: String?, filename: String)? {
    let tempPath = "/tmp/screen_capture.png"
    let downloadsPath = getDownloadsPath()
    let timestamp = DateFormatter().string(from: Date())
    let filename = "screenshot_\(timestamp).png"
    let savePath = downloadsPath.appendingPathComponent(filename)

    // Run screencapture in interactive mode
    print("Select region to capture (Space to capture, Esc to cancel)...")

    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = ["-i", tempPath]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()

    // Wait for screenshot to complete (user pressed Space or Esc)
    var attempts = 0
    while attempts < 300 {
        Thread.sleep(forTimeInterval: 0.1)
        if FileManager.default.fileExists(atPath: tempPath) {
            Thread.sleep(forTimeInterval: 0.2)
            let attrs = try? FileManager.default.attributesOfItem(atPath: tempPath)
            if let size = attrs?[.size] as? UInt64, size > 0 {
                break
            }
        }
        attempts += 1
    }

    task.waitUntilExit()

    // Check if screenshot was captured
    guard FileManager.default.fileExists(atPath: tempPath) else {
        print("Screenshot cancelled")
        return nil
    }

    // Copy to Downloads
    do {
        try FileManager.default.copyItem(atPath: tempPath, toPath: savePath.path)
        print("✓ Saved to Downloads: \(filename)")
        return (savePath.path, filename)
    } catch {
        print("Failed to save to Downloads: \(error)")
        return (tempPath, filename)
    }
}

func performOCR(imagePath: String) -> String? {
    guard let img = CIImage(contentsOf: URL(fileURLWithPath: imagePath)) else {
        print("Failed to load image")
        return nil
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(ciImage: img, options: [:])
    do {
        try handler.perform([request])
        guard let results = request.results, !results.isEmpty else {
            print("No text detected")
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
        print("OCR error: \(error)")
        return nil
    }
}

// Main
if let capture = captureScreenshot(), let imagePath = capture.imagePath {
    if let text = performOCR(imagePath: imagePath) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        print("✓ Text copied to clipboard (\(text.count) chars)")
        print(text)
    } else {
        print("✗ No text found")
    }

    // Cleanup temp file
    if imagePath != capture.filename && imagePath.starts(with: "/tmp/") {
        try? FileManager.default.removeItem(atPath: imagePath)
    }
}
