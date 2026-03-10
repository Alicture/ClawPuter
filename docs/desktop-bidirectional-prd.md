# PRD: Desktop Bidirectional Communication

## User Scenarios

- **Pixel art sync**: /draw on Cardputer -> Mac popover shows high-res version
- **Remote control**: Mac menu -> trigger ESP32 animations
- **Send text**: Mac -> Cardputer chat input
- **Notifications**: Mac -> Cardputer toast overlay
- **Chat sync**: Mac Chat Viewer mirrors Cardputer chat in real-time

## Communication Architecture

```
ESP32 (Cardputer)                    Mac (Desktop App)

UDP 19820 (existing)     -------->   UDPListener (extended)
State broadcast 5Hz                  Parse state + new message types

UDP 19820 (new)          -------->   UDPListener
Pixel art / chat msgs               onPixelArtReceived / onChatMessageReceived

TCP 19821 (new)          <--------   TCPSender (new)
Command server                       Control commands, text, notifications
```

## Protocol

### ESP32 -> Mac (UDP)

- State sync: existing format (no "type" field) - backward compatible
- Pixel art: `{"type":"pixelart","size":8,"rows":[...]}`
- Chat message: `{"type":"chat","role":"user|ai","text":"..."}`

### Mac -> ESP32 (TCP 19821)

Short connections: connect -> send JSON line -> recv ack -> close

- `{"cmd":"animate","state":"happy|idle|sleep|talk"}`
- `{"cmd":"text","msg":"Hello"}` (set input, don't send)
- `{"cmd":"say","msg":"Hello"}` (set input + auto-send)
- `{"cmd":"notify","app":"Messages","title":"Mom","body":"Dinner?"}`
- `{"cmd":"history"}` (returns chat history JSON)

## Implementation Phases

1. **Phase 1**: TCP server + Mac TCP client + Control menu + basic commands
2. **Phase 2**: Pixel art sync (depends on Feature 1)
3. **Phase 3**: Chat sync + notifications + Chat Viewer
4. **Phase 4**: Polish (connection status, auto-scroll, history browse)
