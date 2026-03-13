# ClawPuter Codebase Structure

## Project Root

```
/Users/alexluo/ClawPuter/
├── .env.example           # Environment template
├── .github/               # GitHub workflows
├── assets/                # Static assets
├── desktop/               # macOS desktop pet app
├── docs/                 # Documentation
├── src/                   # ESP32 firmware
├── tools/                 # Utility scripts
├── platformio.ini         # Firmware build config
├── README.md             # Project overview
└── .planning/codebase/    # Architecture docs
```

---

## Firmware Source (`src/`)

### Core Entry Point

| File | Description |
|------|-------------|
| `main.cpp` | Entry point, mode dispatch, setup wizard, main loop |

### Mode Implementations

| File | Description |
|------|-------------|
| `companion.h` | Companion mode header - state machine, animations |
| `companion.cpp` | Companion mode implementation - character rendering, weather effects |
| `chat.h` | Chat mode header - message handling, pixel art |
| `chat.cpp` | Chat mode implementation - message UI, input handling |

### Client Modules

| File | Description |
|------|-------------|
| `ai_client.h` | AI client header - SSE streaming interface |
| `ai_client.cpp` | AI client implementation - HTTP to OpenClaw, token parsing |
| `voice_input.h` | Voice input header - recording interface |
| `voice_input.cpp` | Voice input implementation - microphone, STT proxy |
| `tts_playback.h` | TTS playback header |
| `tts_playback.cpp` | TTS implementation - HTTP streaming, DMA playback |
| `weather_client.h` | Weather client header |
| `weather_client.cpp` | Weather client - Open-Meteo API integration |

### Communication

| File | Description |
|------|-------------|
| `state_broadcast.h` | UDP broadcast header |
| `state_broadcast.cpp` | UDP state broadcast to Mac (5Hz + one-shot) |
| `cmd_server.h` | Command server header |
| `cmd_server.cpp` | TCP/UDP command server - receives commands from Mac |

### Configuration & Utilities

| File | Description |
|------|-------------|
| `config.h` | Configuration header - NVS keys |
| `config.cpp` | Configuration implementation - load/save |
| `sprites.h` | Pixel art sprite data (RGB565) |
| `utils.h` | Colors, constants, Timer class |

---

## Desktop Application (`desktop/CardputerDesktopPet/`)

### Build Configuration

| File | Description |
|------|-------------|
| `Package.swift` | Swift Package Manager config |
| `Info.plist` | macOS app metadata |
| `run.sh` | Build and launch script |

### Source Files

| File | Description |
|------|-------------|
| `Sources/main.swift` | App entry point |
| `Sources/AppDelegate.swift` | Menu bar, mode switching, command handling |
| `Sources/UDPListener.swift` | BSD socket UDP receiver |
| `Sources/TCPSender.swift` | UDP command sender |
| `Sources/PetBehavior.swift` | Pet movement logic, follow mode |
| `Sources/PetWindow.swift` | Transparent window for follow mode |
| `Sources/PetView.swift` | Sprite + weather rendering |
| `Sources/ChatViewerWindow.swift` | Chat history viewer |
| `Sources/PixelArtPopover.swift` | Pixel art display popover |
| `Sources/SpriteData.swift` | Sprite data structures |
| `Sources/SpriteRenderer.swift` | Sprite rendering logic |

---

## Tools & Scripts

| Path | Description |
|------|-------------|
| `tools/stt_proxy.py` | Python STT/TTS proxy server |

---

## Documentation

| Path | Description |
|------|-------------|
| `.planning/codebase/STACK.md` | Technology stack overview |
| `.planning/codebase/ARCHITECTURE.md` | Detailed architecture analysis |
| `.planning/codebase/STRUCTURE.md` | This file - codebase structure |
| `.planning/codebase/INTEGRATIONS.md` | Integration guides |

---

## File Statistics

### ESP32 Firmware

| Category | File Count | Lines (approx) |
|----------|------------|----------------|
| Mode implementations | 4 | ~70,000 |
| Client modules | 6 | ~45,000 |
| Communication | 4 | ~15,000 |
| Config/Utils | 4 | ~10,000 |
| **Total** | **18** | **~140,000** |

### Desktop App

| Category | File Count |
|----------|------------|
| Core app | 2 |
| Communication | 2 |
| UI components | 6 |
| **Total** | **10** |

---

## Key File Relationships

### Mode Flow

```
main.cpp (mode dispatch)
    │
    ├── SETUP ──> config.cpp (NVS)
    │
    ├── COMPANION ──> companion.cpp
    │                    │
    │                    ├── sprites.h
    │                    ├── weather_client.cpp
    │                    └── state_broadcast.cpp ──> UDPListener.swift
    │
    └── CHAT ──> chat.cpp
                   │
                   ├── ai_client.cpp
                   │        │
                   │        └──> (HTTP) ──> OpenClaw Gateway
                   │
                   ├── voice_input.cpp
                   │        │
                   │        └──> (HTTP) ──> stt_proxy.py ──> Groq
                   │
                   ├── tts_playback.cpp
                   │        │
                   │        └──> (HTTP) ──> stt_proxy.py ──> edge-tts
                   │
                   └── state_broadcast.cpp
```

### Command Flow

```
AppDelegate.swift (menu actions)
    │
    ├── TCPSender.swift
    │        │
    │        └──> (UDP:19822) ──> cmd_server.cpp
    │                                │
    │                                ├── Companion.trigger*()
    │                                ├── Chat.setInput()
    │                                └── Companion.showNotification()
    │
    └── UDPListener.swift
             │
             └──> (UDP:19820) ──< state_broadcast.cpp
```

---

## Development Notes

### ESP32 Build

```bash
# PlatformIO build
pio run

# Upload to device
pio run --target upload
```

### Desktop Build

```bash
# Via run.sh script
cd desktop/CardputerDesktopPet
./run.sh
```

### Common Development Patterns

1. **State changes broadcast**: Any state change in ESP32 triggers `stateBroadcastTick()`
2. **Desktop commands**: Use callbacks (`animateCb`, `textCb`, `notifyCb`)
3. **Memory efficiency**: Prefer stack allocation over heap on ESP32
4. **Timer-based animation**: Use `Timer` class for frame timing
5. **JSON protocol**: Compact JSON for network efficiency
