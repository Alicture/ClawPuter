# PRD: Chat Mode Pixel Art Generation

## User Scenarios

- User types `/draw a cat` in Chat mode, AI returns 8x8 pixel art data, ESP32 renders colored pixel grid inline
- `/draw16 a heart` for 16x16 higher resolution
- Pixel art exists as chat messages, scrollable with text messages
- Parse failure degrades to normal text display

## Encoding Format

### Palette (16 colors, fixed)

```
0=transparent  1=black  2=white  3=red  4=darkred  5=orange  6=yellow  7=green
8=darkgreen  9=blue  a=lightblue  b=purple  c=pink  d=brown  e=gray  f=lightgray
```

### AI Output Format

```
[PIXELART:8]
00330000
03333300
33333330
33333330
03333300
00333000
00033000
00003000
[/PIXELART]
```

- 8x8: ~98 chars, within 300 char limit
- 16x16: ~299 chars, response limit raised to 400 for /draw16

## Technical Approach

### Message Struct Extension

```cpp
struct Message {
    String text;
    bool isUser;
    bool isPixelArt = false;
    uint8_t pixelSize = 0;        // 8 or 16
    uint16_t pixels[256];          // RGB565 bitmap (max 16x16)
};
```

### Rendering

- 8x8 @ 12x scale = 96x96px
- 16x16 @ 6x scale = 96x96px
- 1px border + size label

### AI Prompt Routing

`/draw` prefix triggers pixel art system prompt, no conversation history sent.

## Implementation Phases

1. **Phase 1**: Core pipeline (struct, palette, parser, renderer)
2. **Phase 2**: AI integration (/draw routing, prompt, fallback)
3. **Phase 3**: Polish (border, label, scroll verification)
