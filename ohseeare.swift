import Cocoa
import Darwin
import Vision

// MARK: - Shared paths & helpers

private let lastScreenshotPath = "/tmp/ohseeare_last.png"

private func getDimensions(_ imagePath: String) -> (width: Int, height: Int)? {
    guard let img = CIImage(contentsOf: URL(fileURLWithPath: imagePath)) else {
        return nil
    }
    let imgRep = NSCIImageRep(ciImage: img)
    return (imgRep.pixelsWide, imgRep.pixelsHigh)
}

private func captureScreenshot() -> String? {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    task.arguments = ["-i", lastScreenshotPath]
    try? task.run()

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

private func saveToDownloads(_ imagePath: String) -> String? {
    let downloadsPath = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let filename = "screenshot_\(df.string(from: Date())).png"
    let savePath = downloadsPath.appendingPathComponent(filename)

    do {
        try FileManager.default.copyItem(atPath: imagePath, toPath: savePath.path)
        return filename
    } catch {
        return nil
    }
}

private func performOCR(_ imagePath: String) -> String? {
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

private func copyImageToClipboard(_ imagePath: String) {
    guard let img = NSImage(contentsOfFile: imagePath),
          let tiffRep = img.tiffRepresentation,
          let pngData = NSBitmapImageRep(data: tiffRep)?.representation(using: .png, properties: [:]) else {
        return
    }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setData(pngData, forType: .png)
}

private func copyTextToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

// MARK: - CLI

private func runCLIOCR() {
    if FileManager.default.fileExists(atPath: lastScreenshotPath),
       let text = performOCR(lastScreenshotPath),
       !text.isEmpty {
        copyTextToClipboard(text)
        print("✓ Text copied to clipboard (\(text.count) chars)")
    } else {
        print("✗ No screenshot or text found")
    }
}

private func runCLICapture() {
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

// MARK: - Floating palette

private final class FloatingPaletteController: NSWindowController, NSWindowDelegate {
    private var statusItem: NSStatusItem?

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 168, height: 48),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        super.init(window: panel)

        let root = NSVisualEffectView()
        root.material = .hudWindow
        root.blendingMode = .behindWindow
        root.state = .active
        root.wantsLayer = true
        root.layer?.cornerRadius = 12
        root.layer?.cornerCurve = .continuous
        root.layer?.masksToBounds = true

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        stack.distribution = .fillEqually

        func makeIconButton(symbol: String, tip: String, action: Selector) -> NSButton {
            let btn = NSButton()
            btn.toolTip = tip
            btn.bezelStyle = .toolbar
            btn.isBordered = false
            btn.target = self
            btn.action = action
            if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: tip) {
                let cfg = NSImage.SymbolConfiguration(pointSize: 17, weight: .medium)
                btn.image = img.withSymbolConfiguration(cfg)
                btn.imagePosition = .imageOnly
            }
            btn.contentTintColor = .labelColor
            btn.setContentHuggingPriority(.required, for: .horizontal)
            btn.setContentCompressionResistancePriority(.required, for: .horizontal)
            return btn
        }

        stack.addArrangedSubview(
            makeIconButton(symbol: "camera.viewfinder", tip: "Capture region — saves to Downloads, copies image", action: #selector(didTapScreenshot))
        )
        stack.addArrangedSubview(
            makeIconButton(symbol: "text.viewfinder", tip: "OCR last capture — copies text", action: #selector(didTapOCR))
        )
        stack.addArrangedSubview(
            makeIconButton(symbol: "xmark.circle.fill", tip: "Hide palette (use menu bar icon to show)", action: #selector(didTapHide))
        )

        root.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        panel.contentView = root
        panel.delegate = self
        installStatusItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "viewfinder", accessibilityDescription: "Ohseeare")
        item.button?.toolTip = "Ohseeare — menu for Show / Quit"
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Palette", action: #selector(showPalette), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit ohseeare", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc func showPalette() {
        guard let w = window else { return }
        if !w.isVisible {
            w.center()
        }
        w.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func didTapScreenshot() {
        window?.orderOut(nil)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let path = captureScreenshot()
            if let imagePath = path {
                copyImageToClipboard(imagePath)
                _ = saveToDownloads(imagePath)
            }
            DispatchQueue.main.async {
                self?.flashStatus(ok: path != nil, message: path != nil ? "Copied & saved" : "Cancelled")
                self?.window?.orderFrontRegardless()
            }
        }
    }

    @objc private func didTapOCR() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let ok: Bool
            if FileManager.default.fileExists(atPath: lastScreenshotPath),
               let text = performOCR(lastScreenshotPath),
               !text.isEmpty {
                copyTextToClipboard(text)
                ok = true
            } else {
                ok = false
            }
            DispatchQueue.main.async {
                self?.flashStatus(ok: ok, message: ok ? "Text copied" : "No text / no capture")
            }
        }
    }

    @objc private func didTapHide() {
        window?.orderOut(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func flashStatus(ok: Bool, message: String) {
        guard let btn = statusItem?.button else { return }
        if ok {
            NSSound.beep()
        }
        let prevTip = btn.toolTip
        btn.toolTip = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak btn] in
            btn?.toolTip = prevTip ?? "Ohseeare — menu for Show / Quit"
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var palette: FloatingPaletteController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let palette = FloatingPaletteController()
        self.palette = palette
        palette.showPalette()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}

// MARK: - Entry

@main
enum OhseeareMain {
    static func main() {
        let args = CommandLine.arguments
        if args.contains("--ocr") || args.contains("-o") {
            runCLIOCR()
            exit(0)
        }
        if args.contains("--capture") || args.contains("-c") {
            runCLICapture()
            exit(0)
        }
        if isatty(STDIN_FILENO) != 0 {
            runCLICapture()
            exit(0)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
