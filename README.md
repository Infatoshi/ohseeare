# ohseeare

> Minimalist screenshot OCR for macOS. Just text. No fluff.

## Features

- ⚡ **Fast**: ~13.7ms on M4 Max (Apple Vision)
- 🎯 **Simple**: Select region → OCR → Copy to clipboard
- 💾 **Lightweight**: No background process, no GPU memory
- 🔓 **Open Source**: MIT License

## Usage

### Global Hotkey (Cmd+Shift+X)

1. Double-click `ohseeare.shortcut` to install
2. Open System Settings > Keyboard > Keyboard Shortcuts
3. Find "ohseeare" and add keyboard shortcut

### Command Line

```bash
./ohseeare
```

## Requirements

- macOS 13.0+ (for Vision framework)
- Apple Silicon or Intel Mac

## Building from Source

```bash
swiftc -o ohseeare ohseeare.swift
```

## Comparison

| Tool | Accuracy | Speed | Memory | Hotkey |
|-------|----------|-------|--------|--------|
| ohseeare | Apple Vision | 13.7ms | Minimal | ✓ |
| Flameshot | Tesseract | ~100ms | 80MB | ✓ |
| Shottr | ? | Paid | ? | ✓ |
| macOS Live Text | Apple Vision | Built-in | - | - |

## License

MIT
