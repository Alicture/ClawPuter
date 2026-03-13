# ClawPuter Technical Concerns and Technical Debt

This document catalogs known technical concerns, technical debt, and areas requiring attention in the ClawPuter codebase.

---

## 1. ESP32 Memory Constraints

### 1.1 Severe SRAM Limitation

The M5Cardputer (ESP32-S3 without PSRAM) has only ~328KB SRAM, with significant portions consumed by system components:

- **WiFi stack**: ~90KB (always resident after connection)
- **Canvas sprite buffer**: ~65KB (240x135 RGB565)
- **Voice recording buffer**: ~160KB (16kHz x 5s x 16-bit)
- **Available heap during voice recording**: ~13KB (dangerously low)

**Location**: `docs/esp32-voice-chat-lessons.md` documents extensive memory optimization work.

**Risk**: Any additional heap allocation during voice recording can cause OOM crashes.

### 1.2 Heap Fragmentation Vulnerability

The WiFi stack's internal allocations can fragment the heap, reducing the largest free block even when total free heap appears adequate:

```
[AI] Done, 47 chars, heap=186652, largest=94196
[VOICE] Buffer allocation failed! need=96000 heap=187192 largest=94196
```

**Risk**: Second voice recording attempt after AI chat may fail due to heap fragmentation from WiFi stack.

**Mitigation in place**: Voice buffer is allocated once at startup and never freed (contrary to typical memory management advice).

---

## 2. Known ESP32-Specific Bugs

### 2.1 WiFi Toggle Causes Massive Heap Loss

**Bug**: ESP32 WiFi off→on permanently loses ~170KB of heap.

**Location**: Documented in `docs/esp32-voice-chat-lessons.md:362` (P11 principle).

**Risk**: Any code that disconnects and reconnects WiFi will suffer severe memory issues.

### 2.2 Keyboard State Corruption After Blocking Calls

**Bug**: `M5Cardputer.Keyboard.isChange()` becomes unreliable after blocking HTTP calls (>100ms). The internal baseline becomes stale.

**Root cause**: No `M5Cardputer.update()` calls during blocking STT/AI network calls.

**Location**: `docs/esp32-voice-chat-lessons.md:76-108` documents the fix (use `keysState()` + manual edge detection).

**Risk**: User input may be silently ignored after network operations.

### 2.3 Mic/Speaker GPIO Conflict

**Bug**: Microphone and speaker share GPIO 43 on M5Cardputer. Must properly sequence `Speaker.end()` → `Mic.begin()`.

**Location**: Documented in `docs/esp32-voice-chat-lessons.md:384` (P12 principle).

**Risk**: Audio playback/recording will fail or produce garbage if sequence is wrong.

---

## 3. Security Concerns

### 3.1 Credentials Stored in Plaintext NVS

**Issue**: WiFi passwords and API tokens stored in ESP32 NVS (non-volatile storage) without encryption.

**Location**: `src/config.cpp`, `src/config.h`

**Risk**: Physical access to device allows credential extraction.

### 3.2 No Authentication on Command Server

**Issue**: TCP/UDP command server (`src/cmd_server.cpp`) accepts commands from any device on the local network without authentication.

**Location**: Documented in `docs/desktop-bidirectional-design.md:110`

**Risk**: Any local network device can inject text, trigger animations, or send notifications to the companion.

### 3.3 Tokens in Build Flags

**Issue**: API tokens embedded in `platformio.ini` via `-D` flags are visible in compiled binary.

**Location**: `platformio.ini:15`

**Risk**: Binary analysis can extract tokens.

---

## 4. Fragile Code Areas

### 4.1 Zero-Allocation Hot Paths

The ESP32 code relies heavily on stack-only buffers in 60fps rendering loops. Any deviation causes heap fragmentation and eventual failure.

**High-risk patterns** (must remain unchanged):
- `src/chat.cpp:296` - `fitBytes()` with stack `char buf[64]`
- `src/chat.cpp:333` - `snprintf(display, ...)` instead of String concatenation
- `src/ai_client.cpp:131-136` - Stack buffers for SSE parsing
- `src/voice_input.cpp:332` - Stack `char textBuf[256]`

**Risk**: Future developers may introduce `String::substring()` or `String::+=` in these hot paths, causing fragmentation.

### 4.2 Manual Chunked Transfer Decoding

**Location**: `src/ai_client.cpp:138-198`

The HTTP chunked transfer encoding is parsed with a byte-level state machine. This is complex but necessary to avoid bugs where chunk boundaries split SSE data lines.

**Risk**: Maintenance developer may attempt to "simplify" with `readStringUntil('\n')`, reintroducing the original bug.

### 4.3 UDP Protocol Stability

**Location**: `src/state_broadcast.cpp`

UDP is used for state synchronization at 5Hz. No delivery confirmation or retry logic.

**Risk**: State desynchronization between ESP32 and desktop if packets are lost. Desktop may show stale pet position/weather.

---

## 5. Missing Tests

### 5.1 No Automated Tests

**Issue**: No unit tests, integration tests, or CI/CD pipeline exists.

**Evidence**: No `test/` directory, no `tests/` folder, no `*_test.cpp` files.

**Risk**: No regression detection, refactoring is high-risk.

### 5.2 Manual Debugging Required

**Location**: `docs/troubleshooting.md`

Most debugging requires physical hardware and serial monitor connection.

**Risk**: Difficult to catch issues in CI, relies heavily on manual testing.

---

## 6. Scaling and Performance Limits

### 6.1 Conversation History Cap

**Location**: `src/ai_client.h:27`

```cpp
static constexpr int MAX_HISTORY = 10;
```

Only 10 message pairs are retained in conversation history.

**Risk**: Long conversations lose context.

### 6.2 Message Buffer Limits

**Location**: `src/chat.h:18`

```cpp
static constexpr int MAX_MESSAGES = 16;
```

Maximum 16 messages displayed in chat.

**Risk**: Users cannot scroll back far in long conversations.

### 6.3 AI Response Length Cap

**Location**: `src/ai_client.cpp:197,223`

```cpp
if (fullResponse.length() > (unsigned)(pixelArtMode ? 400 : 300)) break;
```

AI responses truncated at 300 characters (400 for pixel art).

**Risk**: Incomplete AI responses for longer queries.

### 6.4 Single-User Desktop Pet

The desktop pet follows a single mouse cursor. No support for multi-monitor setups or multiple pets.

**Location**: `desktop/CardputerDesktopPet/Sources/AppDelegate.swift:86-88`

---

## 7. Dependency and Infrastructure Concerns

### 7.1 External API Dependencies

The system depends on:
- **Groq Whisper API** (`api.groq.com`) - STT
- **Microsoft Edge TTS** - TTS
- **Open-Meteo API** (`api.open-meteo.com`) - Weather
- **OpenClaw Gateway** (user-provided) - AI

**Risk**: Any external API outage breaks functionality. No offline fallback except limited offline mode.

### 7.2 Python Proxy Required

**Location**: `tools/stt_proxy.py`

The STT/TTS proxy must run on a Mac (uses `edge-tts` and `ffmpeg`). This is not embedded in the ESP32.

**Risk**: Additional infrastructure requirement. If proxy is down, voice features fail.

### 7.3 Hardcoded Network Ports

**Location**: Multiple files
- UDP state broadcast: `19820`
- TCP commands: `19821`
- UDP commands: `19822`
- STT proxy default: `8090`

**Risk**: Port conflicts if other local services use these ports. No configuration UI for port changes.

---

## 8. Code Quality Debt

### 8.1 Mixed Language Comments

**Issue**: Code comments mix Chinese and English inconsistently.

**Examples**: `docs/esp32-voice-chat-lessons.md` is entirely Chinese, while `src/main.cpp` comments are English.

### 8.2 Magic Numbers

Multiple hardcoded values without named constants:

- `src/main.cpp:453`: `delay(16)` // ~60fps cap
- `src/main.cpp:679`: `attempts < 30` // 15 seconds
- `src/chat.cpp:89`: `inputBuffer.length() < 100`
- `src/ai_client.cpp:32`: `client.setTimeout(5)`

**Risk**: Maintenance difficulty, easy to misconfigure.

### 8.3 No Error Recovery for Network Failures

**Location**: `src/ai_client.cpp:43-48`

If WiFi connection fails, the system shows an error but may not gracefully recover:

```cpp
if (!client.connect(gwHost.c_str(), port)) {
    busy = false;
    if (onError) onError("Connection failed");
    return;
}
```

**Risk**: Single network failure may require manual intervention.

### 8.4 Serial Debug Dependency

The system relies heavily on serial debug output (`Serial.printf`) for troubleshooting.

**Location**: Throughout ESP32 code (e.g., `src/main.cpp:95`, `src/ai_client.cpp:66`)

**Risk**: No runtime logging accessible without hardware debug adapter.

---

## 9. Desktop Pet Concerns (Swift/macOS)

### 9.1 No Unit Tests

The Swift desktop pet application has no test suite.

**Location**: `desktop/CardputerDesktopPet/`

**Risk**: Swift code changes cannot be validated automatically.

### 9.2 Memory Management in Swift

While Swift uses ARC (Automatic Reference Counting), the sprite rendering and UDP parsing loops could benefit from performance profiling.

**Location**: `desktop/CardputerDesktopPet/Sources/PetView.swift`, `desktop/CardputerDesktopPet/Sources/UDPListener.swift`

### 9.3 Global Event Monitor Limitations

**Location**: `desktop/CardputerDesktopPet/Sources/AppDelegate.swift:86`

```swift
NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged])
```

Global event monitoring requires accessibility permissions and may be blocked by macOS security features.

---

## 10. Build and Deployment Issues

### 10.1 Hardcoded Device Paths

**Location**: `platformio.ini:23-24`

```ini
upload_port = /dev/cu.usbmodem3101
monitor_port = /dev/cu.usbmodem3101
```

USB device paths vary between machines.

### 10.2 Environment Variable Dependencies

**Location**: `platformio.ini:11-21`

Build requires multiple environment variables (`WIFI_SSID`, `WIFI_PASS`, `OPENCLAW_HOST`, etc.). No sensible defaults for local development.

---

## Summary Checklist

| Category | Severity | Item |
|----------|----------|------|
| Memory | Critical | ESP32 SRAM limitation (328KB total) |
| Memory | High | Heap fragmentation after network calls |
| Security | High | No authentication on local command server |
| Security | Medium | Credentials stored in plaintext NVS |
| Fragility | High | Zero-allocation hot paths must be preserved |
| Fragility | Medium | Manual chunked transfer decoding |
| Testing | High | No automated tests |
| Scaling | Low | 10 message history limit |
| Scaling | Low | 300 char AI response cap |
| Infrastructure | Medium | External API dependencies |
| Code Quality | Low | Mixed language comments |
| Code Quality | Low | Magic numbers throughout |
