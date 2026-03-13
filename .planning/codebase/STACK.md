# ClawPuter Technology Stack

## Overview

ClawPuter is a pixel-art desktop companion running on M5Stack Cardputer (ESP32-S3) with a companion macOS desktop pet app. The project spans embedded firmware (C++/Arduino), desktop application (Swift), and utility scripts (Python).

---

## Firmware (ESP32)

### Language

- **C++** (Arduino framework)
- Compiled with PlatformIO using ESP32 Arduino core

### Build System

- **PlatformIO** (`platformio.ini`)
- Platform: `espressif32` / `m5stack-stamps3`
- Framework: Arduino

### Key Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| `M5Cardputer` | ^1.0.2 | M5Stack Cardputer hardware abstraction (display, keyboard, speaker) |
| `ArduinoJson` | ^7.0.0 | JSON parsing for API responses |

### Hardware Platform

- **M5Stack Cardputer** (ESP32-S3 based)
  - MCU: ESP32-S3 (Xtensa dual-core, 240MHz)
  - RAM: 320KB SRAM + 8MB PSRAM
  - Flash: 8MB
  - Display: 1.14" IPS, 240x135 pixels, ST7789V2
  - Keyboard: 56-key matrix keyboard
  - Audio: PDM microphone (SPM1423), speaker on GPIO 43
  - WiFi: 2.4GHz only (802.11 b/g/n)
  - Battery: 120mAh LiPo
  - USB: USB-C with CDC support

### Source Files

Located in `/Users/alexluo/ClawPuter/src/`:

- `main.cpp` - Entry point, mode dispatch, WiFi/NTP initialization
- `companion.h/cpp` - Companion mode: animations, state machine, clock, weather effects
- `chat.h/cpp` - Chat mode: messages, input bar, scrolling, pixel art rendering
- `ai_client.h/cpp` - AI client (OpenClaw), SSE streaming, `/draw` prompt routing
- `voice_input.h/cpp` - Push-to-talk recording, WAV encoding, STT proxy client
- `tts_playback.h/cpp` - TTS voice replies, PCM download and DMA playback
- `weather_client.h/cpp` - Open-Meteo weather API, geocoding, 15-min auto refresh
- `state_broadcast.h/cpp` - UDP state broadcast + one-shot pixel art / chat sync
- `cmd_server.h/cpp` - Command server (TCP 19821 + UDP 19822) for Mac control
- `sprites.h` - Pixel lobster sprites (RGB565)
- `config.h/cpp` - WiFi/API config, NVS persistence
- `utils.h` - Colors, screen constants, Timer

---

## Desktop Application (macOS)

### Language

- **Swift** (Swift 5.9+)
- Target: macOS 13+

### Build System

- **Swift Package Manager** (`Package.swift`)
- Built via `run.sh` script (wraps, signs, and launches)

### Dependencies

- Native frameworks only (AppKit, Foundation, Network)
- No external Swift Package dependencies

### Source Files

Located in `/Users/alexluo/ClawPuter/desktop/CardputerDesktopPet/Sources/`:

- `main.swift` - Entry point
- `AppDelegate.swift` - Menu bar, mode switching, control commands, perch logic
- `UDPListener.swift` - UDP receiver with source IP extraction
- `TCPSender.swift` - UDP command sender (Mac -> ESP32)
- `PetBehavior.swift` - Movement, follow mode, perch target
- `PetWindow.swift` - Transparent pet sprite window
- `SceneWindow.swift` - Weather scene panel
- `PixelArtPopover.swift` - Floating 256x256 pixel art display
- `ChatViewerWindow.swift` - Chat history viewer + remote send
- `SpriteData.swift` - Sprite data structures
- `SpriteRenderer.swift` - Sprite rendering logic
- `PetView.swift` - Pet view component

---

## Tools / Utilities

### Python STT/TTS Proxy

- **Python 3**
- Located in `/Users/alexluo/ClawPuter/tools/stt_proxy.py`

### Python Dependencies

```
edge-tts>=6.1.0
```

### System Dependencies (must be installed separately)

- `ffmpeg` - Audio format conversion (MP3 to PCM)
- `curl` - HTTP requests to Groq API

---

## Architecture Overview

```
+-------------------+      WiFi       +-------------------+      UDP       +-------------------+
|   M5Stack         | <-------------> |   OpenClaw        |               |   macOS           |
|   Cardputer       |                  |   Gateway         |               |   Desktop Pet    |
|   (ESP32-S3)      |                  |   (LAN)           |               |   (Swift)        |
+-------------------+                  +-------------------+               +-------------------+
        |                                       |
        | HTTP                                  | UDP 19820
        v                                       v
+-------------------+                  +-------------------+
|   STT/TTS Proxy   |                  |   UDP 19822       |
|   (Python)        |                  |   (Commands)     |
+-------------------+                  +-------------------+
        |
        v
+-------------------+
|   Groq Whisper    |
|   (Cloud API)     |
+-------------------+
```

---

## Configuration

### Build-Time Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WIFI_SSID` | Primary WiFi SSID | (empty) |
| `WIFI_PASS` | Primary WiFi password | (empty) |
| `OPENCLAW_HOST` | OpenClaw Gateway LAN IP | (empty) |
| `OPENCLAW_PORT` | OpenClaw Gateway port | (empty) |
| `OPENCLAW_TOKEN` | OpenClaw Gateway token | (empty) |
| `STT_PROXY_HOST` | STT proxy host IP | (empty) |
| `STT_PROXY_PORT` | STT proxy port | 8090 |
| `WIFI_SSID2` | Secondary WiFi (hotspot fallback) | (empty) |
| `WIFI_PASS2` | Secondary WiFi password | (empty) |
| `OPENCLAW_HOST2` | Secondary network gateway IP | (empty) |
| `DEFAULT_CITY` | Default city for weather | Beijing |

### Runtime Configuration

- Stored in ESP32 NVS (Non-Volatile Storage)
- Configured via on-device setup wizard (Fn+R)
- Persists across reboots
