# Code Conventions Analysis

This document outlines the coding conventions observed in the ClawPuter codebase.

## Project Overview

ClawPuter consists of two main components:
- **Firmware** (`/Users/alexluo/ClawPuter/src`): C++ (Arduino/ESP32 framework)
- **Desktop App** (`/Users/alexluo/ClawPuter/desktop/CardputerDesktopPet`): Swift (AppKit)

---

## C++ Coding Conventions (Firmware)

### File Organization

- **Header files** use `.h` extension
- **Implementation files** use `.cpp` extension
- **Header guards**: Uses `#pragma once` (not `#ifndef` guards)
- **Single-header utilities**: Some files like `utils.h` and `sprites.h` are header-only

Example structure:
```
src/
  ai_client.h      # Declarations
  ai_client.cpp    # Implementation
  utils.h          # Header-only utilities
  sprites.h        # Header-only data
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `AIClient`, `Companion`, `Chat` |
| Methods/Functions | camelCase | `begin()`, `sendMessage()`, `update()` |
| Member Variables | camelCase with trailing `_` | `lastResponse_`, `busy_`, `historyCount` |
| Constants | PascalCase (namespace) | `Color::BLACK`, `SCREEN_W` |
| Enum Values | PascalCase | `CompanionState::IDLE`, `AppMode::SETUP` |
| Typedefs | PascalCase | `TokenCallback`, `DoneCallback` |
| Files | snake_case | `ai_client.cpp`, `state_broadcast.cpp` |

### Code Organization in Headers

```cpp
#pragma once
#include <Arduino.h>
#include <functional>

class ClassName {
public:
    // Constructor / public API
    void begin();
    void update();
    bool isBusy() const { return busy_; }

private:
    // Member variables first
    String lastResponse_;
    bool busy = false;

    // Then private methods
    void buildRequestDoc(const String& msg, JsonDocument& doc);
};
```

### Style Guidelines

- **Indentation**: 4 spaces (no tabs)
- **Braces**: K&R style (opening brace on same line)
- **Access specifiers**: `public:`, `private:` indented at class level
- **Inline methods**: Keep simple getters inline in headers
- **Includes**: Standard library first, then framework headers, then local headers
- **Comments**: Use `//` for single-line comments, `// ──` for section separators

### Memory Optimization Patterns

The codebase shows careful attention to memory (ESP32 has limited RAM):

- **Stack allocation**: Use fixed-size char arrays instead of dynamic Strings in hot loops
- **Reserve strings**: Pre-reserve String capacity to avoid fragmentation
- **Zero-heap streaming**: SSE parsing uses stack buffers, not heap allocation
- **Constexpr**: Use `constexpr` for compile-time constants

Example from `ai_client.cpp`:
```cpp
// Stack-allocated buffers — no heap allocation in streaming loop
char sizeBuf[16];
int sizeLen = 0;
char lineBuf[512];
int lineLen = 0;
```

### Arduino-Specific Patterns

- **Global instance**: `M5Canvas canvas(&M5Cardputer.Display);`
- **Loop integration**: Update methods called in main `loop()`
- **Serial debug**: `Serial.printf("[AI] Message...\n");` for debugging
- **Timer struct**: Custom `Timer` utility in `utils.h` for non-blocking delays

---

## Swift Coding Conventions (Desktop App)

### File Organization

- **All Swift files** in `Sources/` directory
- **Single-file classes**: Each class in its own file
- **App entry point**: `main.swift` with `NSApplicationMain`

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes/Enums | PascalCase | `AppDelegate`, `PetBehavior`, `PetState` |
| Methods/Functions | camelCase | `applicationDidFinishLaunching`, `onMouseMoved` |
| Properties | camelCase | `petSize`, `followPadRight`, `facingLeft` |
| Private properties | camelCase with `private` | `private var displayMode` |
| Files | PascalCase | `PetBehavior.swift`, `PetView.swift` |

### Code Organization

```swift
import AppKit

enum PetState {
    case idle
    case walk
    case happy
}

/// Manages pet state machine, cursor following, and animation timing
class PetBehavior {
    // Properties
    var state: PetState = .idle
    private var targetX: CGFloat = 400

    // Computed properties
    private(set) var syncMode: Bool = false

    // Methods
    func onMouseMoved(to point: NSPoint) { }
    func update() -> Bool { }
}
```

### Style Guidelines

- **Indentation**: 4 spaces
- **Braces**: K&R style
- **Access control**: Explicit `private` for internal state
- **Comments**: `///` for documentation, `//` for regular comments
- **Section separators**: `// ── Follow mode window ──`
- **Weak self**: Use `[weak self]` in closures to prevent retain cycles
- **Type annotations**: Explicit types for properties, inferred for locals

### AppKit Patterns

- **Delegate pattern**: `NSApplicationDelegate`, `NSTableViewDataSource`
- **Timer**: `Timer.scheduledTimer(withTimeInterval:repeats:)`
- **RunLoop**: Add timer to `.common` mode for background updates
- **Menu bar**: `NSStatusBar`, `NSMenu`, `NSMenuItem`
- **Windows**: `PetWindow` (custom `NSWindow`), `NSPanel` for floating panels

Example:
```swift
updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
    self?.tick()
}
RunLoop.current.add(updateTimer!, forMode: .common)
```

### SwiftUI vs AppKit

The desktop app uses **pure AppKit** (no SwiftUI):
- `NSWindow`, `NSView`, `NSPanel`
- `NSMenu` for menu bar
- Custom drawing in `draw(_ dirtyRect: NSRect)`

---

## Build Configuration

### PlatformIO (Firmware)

Configuration in `platformio.ini`:
- Framework: Arduino
- Board: M5Stack Stamp S3 (ESP32)
- Dependencies: `M5Cardputer`, `ArduinoJson`

Build flags for WiFi credentials (from environment variables):
```ini
build_flags =
    -DWIFI_SSID=\"${sysenv.WIFI_SSID}\"
    -DWIFI_PASS=\"${sysenv.WIFI_PASS}\"
```

### Swift Package

Uses native Swift Package Manager:
- Package manifest: `Package.swift`
- Build script: `run.sh`

---

## Linting and Formatting

**No explicit linting/formatting configuration found** in the repository:
- No `.clang-format` for C++
- No `.swiftformat` for Swift
- No CI/CD workflows with lint checks

---

## Contributing Guidelines

From `CONTRIBUTING.md`:
- **Test on hardware**: Test changes on real Cardputer when possible
- **Compile check**: `pio run` catches most issues even without hardware
- **Environment setup**: Use `.env.example` for configuration

---

## Summary

The codebase follows consistent conventions within each language:
- **C++**: Arduino-style embedded C++ with memory-conscious patterns
- **Swift**: Standard AppKit conventions with explicit access control

Key observations:
1. No automated formatting/linting is enforced
2. Memory optimization is a primary concern in C++ code
3. Clear separation between header declarations and implementations
4. Swift code uses modern patterns with weak references in closures
