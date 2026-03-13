# ClawPuter Architecture Analysis

## System Overview

ClawPuter is a distributed system consisting of three main components:
1. **ESP32 Firmware** (M5Stack Cardputer) - Embedded companion device
2. **macOS Desktop Pet** (Swift) - Desktop overlay application
3. **STT/TTS Proxy** (Python) - Speech processing middleware

The system uses bidirectional UDP/TCP communication to synchronize state between the ESP32 and Mac.

---

## ESP32 Firmware Architecture

### Mode State Machine

The firmware operates in three primary modes defined in `src/main.cpp`:

```cpp
enum class AppMode { SETUP, COMPANION, CHAT };
```

#### Mode Transitions

```
SETUP ──(valid config)──> COMPANION ──(Tab key)──> CHAT
  │                           │                         │
  └──(WiFi fail/Tab)─────────┴───(Tab key)─────────────┘
```

The mode switching is handled in the main loop at `src/main.cpp:162-433`:
- **SETUP**: Onboarding flow for WiFi credentials and API configuration
- **COMPANION**: Interactive pet display with clock, weather, character movement
- **CHAT**: AI conversation mode with voice input and TTS output

### Companion State Machine

The pet character has internal states defined in `src/companion.h:6-13`:

```cpp
enum class CompanionState {
    IDLE,      // Default resting state
    HAPPY,     // Triggered by key input or desktop command
    SLEEP,     // After 30 seconds of inactivity
    TALK,      // During AI response streaming
    STRETCH,   // Spontaneous action (8-15s intervals)
    LOOK       // Spontaneous action
};
```

State transitions are triggered by:
- **User input**: `handleKey()` in `src/companion.cpp:200+`
- **Idle timeout**: 30-second timer triggers SLEEP state
- **Spontaneous actions**: Random timer (8-15s) triggers STRETCH or LOOK
- **Desktop commands**: TCP/UDP commands received via `cmd_server.cpp`

### Setup State Machine

Configuration flow in `src/main.cpp:68`:

```cpp
enum class SetupStep {
    SSID, PASSWORD, GATEWAY_HOST, GATEWAY_PORT,
    GATEWAY_TOKEN, STT_HOST, CONNECTING
};
```

---

## Communication Architecture

### UDP State Broadcast (ESP32 → Mac)

**Port**: 19820 (bidirectional broadcast + unicast)

The ESP32 broadcasts its state 5 times per second via `src/state_broadcast.cpp`:

```cpp
// Periodic state sync (5Hz)
stateBroadcastTick(state, frame, mode, normX, normY, direction, weatherType, temperature);

// One-shot messages
stateBroadcastChatMsg(role, text);      // Chat messages
stateBroadcastPixelArt(size, rows[]);    // AI-generated pixel art
```

**JSON Protocol**:
```json
// State sync
{"s":0,"f":0,"m":"COMPANION","x":0.50,"y":0.50,"d":0,"w":1,"t":22.5}

// Chat message
{"type":"chat","role":"user","text":"Hello"}

{"type":"chat","role":"ai","text":"Hi there!"}

// Pixel art
{"type":"pixelart","size":8,"rows":["00330000",...]}
```

### Command Protocol (Mac → ESP32)

**Ports**: TCP 19821 + UDP 19822

The Mac sends commands to the ESP32 via `desktop/CardputerDesktopPet/Sources/TCPSender.swift`:

```json
// Animate command
{"cmd":"animate","state":"happy"}

// Text injection
{"cmd":"text","msg":"Hello"}
{"cmd":"say","msg":"Hello"}  // auto-send to AI

// Notification
{"cmd":"notify","app":"Messages","title":"Mom","body":"Dinner?"}

// History request
{"cmd":"history"}
```

Command processing in `src/cmd_server.cpp:81-165`:
1. Parse JSON to extract `cmd` field
2. Route to appropriate callback (animateCb, textCb, notifyCb)
3. Return JSON response

---

## Data Flow Patterns

### Chat Message Flow

```
User types/speaks
       │
       ▼
Chat.handleEnter() / voiceInput.stopRecording()
       │
       ▼
aiClient.sendMessage() ──HTTP SSE──> OpenClaw Gateway
       │
       ├─onToken()──> Chat.appendAIToken() ──> Display
       │
       ├─onDone()──> Chat.onAIResponseComplete()
       │                  │
       │                  ▼
       │            stateBroadcastChatMsg("ai", response)
       │                  │
       │                  ▼
       │            ttsPlayback.requestAndPlay() ──> Speaker
       │
       └─onError()──> Chat.appendAIToken("[Error]")
```

### Weather Data Flow

```
WeatherClient.update() (every 15 min)
       │
       ▼
HTTP GET ──> Open-Meteo API
       │
       ▼
WeatherData { type, temperature, valid }
       │
       ▼
Companion.setWeather() + displayWeatherEffects()
       │
       ▼
stateBroadcastTick() includes weatherType + temperature
       │
       ▼
UDPListener (Mac) receives + updates sceneView
```

### Desktop Command Flow

```
User clicks menu item (e.g., "Trigger Happy")
       │
       ▼
TCPSender.triggerAnimate(address, "happy")
       │
       ▼
UDP send to ESP32:19822
       │
       ▼
CmdServer.tickUDP() / tickTCP()
       │
       ▼
processCommand() extracts "animate" + "happy"
       │
       ▼
animateCb("happy") ──> Companion.triggerHappy()
       │
       ▼
Companion.setState(HAPPY) ──> Animation plays
```

---

## Desktop Pet Architecture

### Window Architecture

The macOS app uses two display modes (`src/AppDelegate.swift:5`):

1. **Follow Mode** (`DisplayMode.follow`)
   - `PetWindow`: Transparent borderless window
   - `PetView`: Renders sprite at mouse position
   - Pet perches on Chat Viewer when visible

2. **Scene Mode** (`DisplayMode.scene`)
   - `NSPanel`: Borderless floating panel below menu bar
   - Fixed position with animated sprite
   - Shows weather particles and clock

### Menu Bar Integration

```
NSStatusItem (lobster emoji)
       │
       ▼
NSMenu
       ├── Follow Mode / Scene Mode (toggle)
       ├── Control
       │    ├── Trigger Happy
       │    ├── Trigger Sleep
       │    ├── Send Text...
       │    └── Send Notification...
       ├── Chat Viewer
       ├── ESP32: Connected/Waiting...
       └── Quit
```

### Sprite Rendering Pipeline

```
UDP packet received
       │
       ▼
UDPListener.parsePacket()
       │
       ▼
onStateReceived callback
       │
       ▼
PetBehavior.applySync()
       │
       ▼
PetView.updateSprite()
       │
       ▼
SpriteRenderer.draw() ──> NSImage
```

---

## Component Dependencies

### ESP32 Modules

| Module | Responsibilities | Key Dependencies |
|--------|-----------------|------------------|
| `main.cpp` | Mode dispatch, loop, WiFi | All modules |
| `companion.h/cpp` | Character state, animation, weather display | `sprites.h`, `weather_client.h` |
| `chat.h/cpp` | Message UI, input, scrolling, pixel art | `ai_client.h` |
| `ai_client.h/cpp` | HTTP SSE to OpenClaw, token streaming | None |
| `voice_input.h/cpp` | Microphone recording, STT proxy | None |
| `tts_playback.h/cpp` | TTS download, DMA playback | None |
| `weather_client.h/cpp` | Open-Meteo API calls | None |
| `state_broadcast.h/cpp` | UDP broadcast | `WiFiUDP` |
| `cmd_server.h/cpp` | TCP/UDP command processing | `WiFiServer`, `ArduinoJson` |
| `config.h/cpp` | NVS persistence | None |

### Desktop Modules

| Module | Responsibilities | Key Dependencies |
|--------|-----------------|------------------|
| `AppDelegate.swift` | Menu bar, mode switch, command dispatch | All modules |
| `UDPListener.swift` | BSD socket UDP receive | Foundation, Network |
| `TCPSender.swift` | UDP command send | Foundation |
| `PetBehavior.swift` | Movement logic, mouse follow | None |
| `PetWindow.swift` | Transparent window | AppKit |
| `PetView.swift` | Sprite + weather rendering | AppKit |
| `ChatViewerWindow.swift` | Chat history UI | AppKit |
| `PixelArtPopover.swift` | 256x256 art display | AppKit |

---

## Key Design Patterns

### Timer-Based State Machines

Both ESP32 and desktop use timer-based state machines:

```cpp
// ESP32: src/companion.h:64-67
Timer animTimer{500};
Timer idleTimeout{30000};
Timer clockTimer{1000};
Timer spontaneousTimer{8000};
```

```swift
// Mac: Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true)
```

### Callback-Driven Communication

The AI client uses callback-style streaming:

```cpp
// src/main.cpp:345-372
aiClient.sendMessage(msg,
    [](const char* token) { /* onToken */ },
    []() { /* onDone */ },
    [&](const String& error) { /* onError */ }
);
```

### Memory-Efficient JSON Handling

ESP32 uses stack-only parsing to minimize heap fragmentation:

```cpp
// src/cmd_server.cpp:85-102
// Simple key extraction for small commands (no JsonDocument)
const char* cmdKey = strstr(json, "\"cmd\":\"");
```

---

## Network Topology

```
+-------------------+      WiFi       +-------------------+      UDP       +-------------------+
|   M5Stack         | <-------------> |   OpenClaw        |               |   macOS           |
|   Cardputer       |                  |   Gateway         |               |   Desktop Pet    |
|   (ESP32-S3)      |                  |   (LAN)           |               |   (Swift)        |
+-------------------+                  +-------------------+               +-------------------+
        |                                       |                              ^
        | HTTP                                  | UDP 19820                   | UDP 19822
        v                                       v                              |
+-------------------+                  +-------------------+                   |
|   STT/TTS Proxy   |                  |   UDP 19822       | ──────────────┘
|   (Python)        |                  |   (Commands)     |
+-------------------+                  +-------------------+
        |
        v
+-------------------+
|   Groq Whisper    |
|   (Cloud API)     |
+-------------------+
```
