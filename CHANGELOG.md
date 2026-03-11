# Changelog

## Unreleased

- Open-source readiness: added `.env.example`, `CONTRIBUTING.md`, issue templates

## 2026-03 — Community & Polish

- Pixel art generation in chat (`/draw`, `/draw16`) with 16-color palette
- Desktop bidirectional communication (Mac ↔ ESP32)
- Desktop weather Scene Mode with dual-mode switching
- Community suggestions added to roadmap

## 2026-02 — Movement & Weather

- Movable pet with time-travel sky (walk left = past, right = future)
- Desktop pet position sync via UDP
- Weather simulation mode (Fn+W, keys 1-8)
- Pet accessories (sunglasses, umbrella, snow hat, mask)
- Clock with temperature display and separator

## 2026-02 — Voice & TTS

- TTS voice replies through built-in speaker
- Push-to-talk voice input via Groq Whisper STT
- STT proxy server (`tools/stt_proxy.py`)
- Heap fragmentation fixes for stable multi-round voice chat

## 2026-01 — Desktop & Networking

- macOS desktop pet companion app (Swift)
- UDP state sync between Cardputer and desktop
- Dual WiFi with auto-fallback (home + phone hotspot)
- Offline mode when all WiFi fails
- Runtime config setup wizard (Fn+R)

## 2025-12 — Foundation

- Pixel companion with 6 animation states (idle, happy, sleep, talk, stretch, look)
- OpenClaw lobster sprite design (16x16, 4KB)
- Chat mode with SSE streaming and scrollable history
- OpenClaw Gateway integration (multi-model AI backend)
- Boot animation with pixel wipe transitions
- Day/night cycle with stars, moon, sun
- Real-time weather from Open-Meteo API
- Sound effects (key clicks, happy melody, notification tones)
