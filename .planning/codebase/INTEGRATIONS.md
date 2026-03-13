# ClawPuter External Integrations

## Overview

ClawPuter integrates with several external services and APIs to provide weather data, AI chat, speech-to-text, and text-to-speech functionality.

---

## Open-Meteo Weather API

### Purpose

Real-time weather data for the companion's weather display and effects.

### Endpoint

```
https://api.open-meteo.com/v1/forecast
```

### Features

- Free API, no API key required
- Updates every 15 minutes
- Supports geocoding via city name
- Returns temperature, weather codes, day/night status

### Weather Data Used

| Field | Description |
|-------|-------------|
| `temperature_2m` | Current temperature |
| `weather_code` | WMO weather interpretation code |
| `is_day` | Day/night indicator |

### Weather Code Mapping

Maps WMO codes to internal `WeatherType` enum:
- 0 → CLEAR
- 1-3 → PARTLY_CLOUDY
- 45-48 → FOG
- 51-67 → DRIZZLE/RAIN
- 71-77 → SNOW
- 80-82 → RAIN
- 85-86 → SNOW
- 95-99 → THUNDER

### Implementation

See `/Users/alexluo/ClawPuter/src/weather_client.cpp` and `/Users/alexluo/ClawPuter/src/weather_client.h`

---

## OpenClaw Gateway

### Purpose

AI chat backend providing conversation capabilities with support for multiple AI models (Kimi, Claude, GPT, Gemini), persistent memory, and community skills.

### Connection

- Protocol: HTTP/HTTPS
- Default port: 8080
- LAN access only (configured via `OPENCLAW_HOST`)
- Requires authentication token

### Endpoints Used

```
POST /v1/chat/completions
```

With SSE (Server-Sent Events) streaming for token-by-token responses.

### Features

- Multi-model fallback (Kimi/Claude/GPT/Gemini)
- Persistent memory across sessions
- 5400+ community skills
- Streaming responses with typing sound effects

### Configuration

```json
{
  "gateway": {
    "bind": "lan",
    "http": {
      "endpoints": {
        "chatCompletions": { "enabled": true }
      }
    }
  }
}
```

### Implementation

See `/Users/alexluo/ClawPuter/src/ai_client.cpp` and `/Users/alexluo/ClawPuter/src/ai_client.h`

---

## Groq Whisper API

### Purpose

Speech-to-text (STT) for voice input functionality.

### Endpoint

```
https://api.groq.com/openai/v1/audio/transcriptions
```

### Authentication

- Requires `GROQ_API_KEY`
- Used by the STT proxy server, not directly by ESP32

### Model

- `whisper-large-v3` (default)
- High accuracy transcription

### Flow

1. ESP32 records audio (push-to-talk via Fn key)
2. Audio sent to local STT proxy (`stt_proxy.py`)
3. Proxy forwards to Groq Whisper API
4. Transcription returned to ESP32

### Implementation

See `/Users/alexluo/ClawPuter/tools/stt_proxy.py` (lines 150-210)

---

## Edge TTS (Microsoft Azure)

### Purpose

Text-to-speech (TTS) for AI voice responses.

### Implementation

- Used via `edge-tts` Python library
- Runs locally on the STT proxy machine
- Converts text to MP3, then transcodes to PCM (8kHz, mono)

### Default Voice

```
zh-CN-XiaoxiaoNeural
```

### Supported Voices

Any voice available in Microsoft Edge TTS. Common options:
- `en-US-JennyNeural`
- `zh-CN-XiaoxiaoNeural`
- `zh-CN-YunxiNeural`

### Audio Format

- Output: Raw PCM (signed 16-bit LE, 8kHz, mono)
- Max duration: ~10 seconds (160KB buffer limit)
- Fade-out applied for truncated audio

### Implementation

See `/Users/alexluo/ClawPuter/tools/stt_proxy.py` (lines 47-149)

---

## NTP (Network Time Protocol)

### Purpose

Synchronize device clock for day/night cycle and time display.

### Server

```
pool.ntp.org
```

### Configuration

- Default timezone: UTC+8 (China)
- No daylight saving offset

### Implementation

See `/Users/alexluo/ClawPuter/src/main.cpp` (lines 72-75)

---

## UDP Communication (ESP32 <-> macOS)

### State Broadcast (ESP32 -> Mac)

- **Port**: 19820
- **Protocol**: UDP broadcast
- **Frequency**: 5Hz (continuous)
- **Data**: Pet state, position, weather, temperature

### Command Channel (Mac -> ESP32)

- **Port**: 19822
- **Protocol**: UDP unicast
- **Purpose**: Remote trigger animations, send text, notifications

### Commands Supported

| Command | Description |
|---------|-------------|
| `happy` | Trigger happy animation |
| `idle` | Trigger idle animation |
| `sleep` | Trigger sleep animation |
| `talk` | Trigger talk animation |
| `text:<message>` | Send text to chat input |
| `msg:<message>` | Send and auto-send message |
| `notify:<app>:<title>:<body>` | Display notification toast |
| `history` | Request chat history |

### Implementation

- ESP32: `/Users/alexluo/ClawPuter/src/state_broadcast.cpp` and `/Users/alexluo/ClawPuter/src/cmd_server.cpp`
- macOS: `/Users/alexluo/ClawPuter/desktop/CardputerDesktopPet/Sources/UDPListener.swift` and `/Users/alexluo/ClawPuter/desktop/CardputerDesktopPet/Sources/TCPSender.swift`

---

## Summary Table

| Service | Protocol | API Key Required | Purpose |
|---------|----------|------------------|---------|
| Open-Meteo | HTTPS | No | Weather data |
| OpenClaw Gateway | HTTP | Token | AI chat |
| Groq Whisper | HTTPS | Yes (GROQ_API_KEY) | Speech-to-text |
| Edge TTS | Local | No | Text-to-speech |
| NTP | UDP | No | Time sync |
| Desktop Pet | UDP | No | State sync |

---

## Security Notes

- OpenClaw Gateway token stored in build flags and NVS
- Groq API key used only on local proxy machine (not on ESP32)
- All communication over local network (LAN) except cloud APIs
- No TLS on UDP local network communication
