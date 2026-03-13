# Testing Patterns Analysis

This document outlines the testing approaches used in the ClawPuter codebase.

## Testing Overview

**No formal test suite exists** in this project. The codebase does not contain:
- Unit test files
- Test directories
- Testing frameworks (Google Test, Catch2, XCTest)
- Automated CI/CD tests

Testing is performed manually through hardware verification.

---

## Manual Testing Approach

### Hardware Testing

From `CONTRIBUTING.md`:
> **Test on hardware**: If you have a Cardputer, test your changes on real hardware. If not, `pio run` (compile-only) still catches most issues.

The project relies on:
1. **Compile-time verification** via PlatformIO
2. **Manual hardware testing** on physical M5Stack Cardputer device

### Compile Verification

```bash
# PlatformIO compile check (no hardware required)
pio run
```

This catches:
- Syntax errors
- Type errors
- Linker errors
- Missing dependencies

---

## Firmware Testing (C++)

### Debug Output

The C++ code uses serial debugging extensively:

```cpp
Serial.printf("[AI] Connecting to %s:%d...\n", gwHost.c_str(), port);
Serial.printf("[AI] Sent, heap=%u\n", ESP.getFreeHeap());
Serial.printf("[AI] Done, %d chars, heap=%u, largest=%u, min_ever=%u\n",
    fullResponse.length(), ESP.getFreeHeap(),
    heap_caps_get_largest_free_block(MALLOC_CAP_8BIT),
    ESP.getMinFreeHeap());
```

Debug prefixes include:
- `[AI]` - AI client operations
- `[BOOT]` - Boot sequence
- `[UDP]` - UDP listener events
- `[TCP]` - TCP sender events

### Memory Monitoring

ESP32-specific memory tracking:
```cpp
ESP.getFreeHeap()
heap_caps_get_largest_free_block(MALLOC_CAP_8BIT)
ESP.getMinFreeHeap()
```

### PlatformIO Testing

The `platformio.ini` configuration includes:
```ini
[env:m5stack-cardputer]
platform = espressif32
board = m5stack-stamps3
framework = arduino
monitor_speed = 115200
```

`pio device monitor` can be used to view serial output for debugging.

---

## Desktop App Testing (Swift)

### Manual Testing

The desktop app (`CardputerDesktopPet`) is tested manually:
- Run the app via `run.sh`
- Verify pet behavior follows cursor
- Check UDP state synchronization
- Test menu bar controls

### Debug Output

Swift code uses `print()` for debugging:
```swift
print("[UDP] Pixel art received: \(size)x\(size)")
print("[UDP] Chat: \(role): \(text)")
print("[TCP] No ESP32 address known")
```

### Log Streaming

The `run.sh` script can stream logs:
```bash
log stream --predicate 'process == "CardputerDesktopPet"' --level info --style compact
```

---

## Hardware Integration Testing

### UDP State Sync Testing

Test UDP broadcast reception:
1. Start desktop app
2. Power on Cardputer with new firmware
3. Verify pet state syncs between devices
4. Check connection indicator in menu bar

### AI Client Testing

Test AI streaming responses:
1. Connect Cardputer to WiFi
2. Send message via keyboard or voice
3. Verify SSE streaming works
4. Check TTS playback

### Pixel Art Testing

Test `/draw` command:
1. Send `/draw cat` or `/draw16 dog`
2. Verify desktop app displays pixel art popover
3. Check color palette rendering

---

## CI/CD

**No CI/CD workflows configured** for automated testing.

The `.github/` directory contains only issue templates:
- `bug_report.md`
- `feature_request.md`

---

## Recommendations for Testing

If formal testing were to be added, consider:

### C++ (Firmware)
- **GoogleTest** or **Catch2** for unit tests
- **PlatformIO unit testing** framework
- Mock Arduino/ESP32 hardware interfaces for host-based testing

### Swift (Desktop)
- **XCTest** for unit tests
- **Quick/Nimble** for behavior-driven tests
- Mock network classes for UDP/TCP testing

### CI Integration
- GitHub Actions for automated builds
- `pio test` for firmware testing
- xcodebuild for Swift compilation verification

---

## Summary

The ClawPuter project currently relies entirely on manual testing:
- **No automated test suite**
- **No unit tests**
- **Compile-only verification** via PlatformIO
- **Manual hardware testing** for functional verification
- **Serial debug output** for troubleshooting

This is common for embedded/mobile projects where hardware integration testing is necessary, but adding a basic test suite would improve code quality and catch regressions.
