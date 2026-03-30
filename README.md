# ohseeare

> Minimalist screenshot OCR for macOS. Just text. No fluff.

## Features

- ⚡ **Fast**: ~13.7ms on M4 Max (Apple Vision)
- 🎯 **Simple**: Select region → Copy image to clipboard
- 🔤 **OCR**: Press Cmd+O → Copy text to clipboard
- 💾 **Saves**: Screenshots saved to `~/Downloads`

## Download

### DMG (Recommended)
Download [ohseeare-1.1.0.dmg](https://github.com/Infatoshi/ohseeare/releases/latest)

### Build from Source
```bash
swiftc -o ohseeare ohseeare.swift
```

## Usage

### Screenshot Mode
Double-click the app or run:
```bash
./ohseeare
```
Shows dimensions, copies image to clipboard, saves to Downloads.

### OCR Mode
```bash
./ohseeare --ocr
# or
./ohseeare -o
```
OCRs the last screenshot, copies text to clipboard.

## Global Hotkeys

After installing the DMG, set hotkeys in System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts:

| Action | Hotkey |
|--------|--------|
| Screenshot | Cmd+Shift+X |
| OCR | Cmd+O |

## Requirements

- macOS 13.0+
- Apple Silicon or Intel

## License

MIT
