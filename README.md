# JsonSwag

A native macOS SwiftUI app for viewing large JSONL files with smooth scrolling and VSCode-style search.

## Features

- 📂 **Large File Support** - Lazy loading for smooth scrolling even with massive JSONL files
- 🔍 **VSCode-style Search** - Cmd+F opens search bar with regex, case-sensitive, and whole-word options
- 📑 **Multi-tab Support** - Open multiple files in tabs
- 📋 **Copy to Clipboard** - One-click copy for any JSON value
- ⬇️ **Deep Expand/Collapse** - Expand all nested fields to deepest level in one click

## Requirements

- macOS 14.0 or later
- Xcode 15+ (for building from source)

## Building from Source

```bash
# Clone the repository
git clone https://github.com/Poseima/JsonSwag.git
cd JsonSwag

# Build
xcodebuild -project JsonSwag.xcodeproj -scheme JsonSwag -configuration Debug build

# Run
open ~/Library/Developer/Xcode/DerivedData/JsonSwag-*/Build/Products/Debug/JsonSwag.app
```

## Usage

1. Open a `.jsonl` file by dragging it to the app or using File → Open
2. Scroll through records smoothly - only visible records are rendered
3. Press `Cmd+F` to open the search bar
4. Click the expand button (⌄) to expand all nested fields
5. Click the copy button to copy any value to clipboard

## License

MIT License
