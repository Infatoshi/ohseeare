# ohseeare

> Minimalist screenshot OCR for macOS. Just text. No fluff.

## Features

- ⚡ **Fast**: ~13.7ms on M4 Max (Apple Vision)
- 🎯 **Simple**: Select region → Copy image to clipboard
- 🔤 **OCR**: Press Cmd+O → Copy text to clipboard
- 💾 **Saves**: Screenshots saved to `~/Downloads/`

## Usage

### Screenshot Mode
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

### Cmd+Shift+X: Screenshot
1. Open Shortcuts app
2. Create new shortcut
3. Add "Run Shell Script"
4. Path: `/Users/infatoshi/ScreenOCR/ohseeare`

### Cmd+O: OCR
1. Create new shortcut
2. Add "Run Shell Script"
3. Path: `/Users/infatoshi/ScreenOCR/ohseeare --ocr`

## Requirements

- macOS 13.0+
- Apple Silicon or Intel

## Building

```bash
swiftc -o ohseeare ohseeare.swift
```

## License

MIT
