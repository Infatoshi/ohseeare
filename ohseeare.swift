#!/usr/bin/env swift

import Cocoa
import Vision

// Simple screenshot OCR that:
// 1. Takes screenshot (Cmd+Shift+4 mode)
// 2. Runs OCR
// 3. Copies to clipboard
// Usage: ocr.swift

func captureScreenshot() -> String? {
    let tempPath = "/tmp/screen_capture.png"

    // Run screencapture in interactive mode
    print("Select region to capture (Space to capture, Esc to cancel)...")

    let task = Process()
    task.launchPath = "/usr/sbin/screencapture"
    task.arguments = ["-i", tempPath]

    // We need to run this and wait for user input
    // The -i flag makes it interactive
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()

    // Wait for screenshot to complete (user pressed Space or Esc)
    // We'll check the file periodically
    var attempts = 0
    while attempts < 300 { // 30 seconds timeout
        Thread.sleep(forTimeInterval: 0.1)
        if FileManager.default.fileExists(atPath: tempPath) {
            // File exists, but wait a bit more to ensure it's complete
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

    return tempPath
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
if let imagePath = captureScreenshot() {
    if let text = performOCR(imagePath: imagePath) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        print("✓ Text copied to clipboard (\(text.count) chars)")
        print(text)
    } else {
        print("✗ No text found")
    }

    // Cleanup
    try? FileManager.default.removeItem(atPath: imagePath)
}
