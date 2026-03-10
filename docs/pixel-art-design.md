# Chat 像素画生成：实现文档

## Overview

在 Chat 模式中通过 `/draw` 命令让 AI 生成像素画，解析后在 Cardputer 屏幕上渲染为 96×96 彩色像素网格，并同步到 Mac 桌面高清展示。

## 用户交互

- `/draw a cat` — AI 生成 8×8 像素画
- `/draw16 a heart` — AI 生成 16×16 像素画
- 像素画作为聊天消息混合滚动浏览
- 解析失败时 fallback 为普通文字

## 编码格式

### 16 色调色板（固定 RGB565）

```
0=透明  1=黑  2=白  3=红  4=深红  5=橙  6=黄  7=绿
8=深绿  9=蓝  a=浅蓝  b=紫  c=粉  d=棕  e=灰  f=浅灰
```

### AI 输出格式

```
[PIXELART:8]
00330000
03333300
33333330
...
[/PIXELART]
```

`[PIXELART:N]` / `[/PIXELART]` 显式分隔符确保可靠提取。

## 技术实现

### 内存优化：共享像素缓冲

原方案每 Message 含 `uint16_t pixels[256]` → 20 条 × 514B = 10.3KB 浪费。

优化后使用 2 个共享 slot（round-robin 复用）：

```cpp
static constexpr int PIXEL_SLOTS = 2;
uint16_t pixelBuffers[PIXEL_SLOTS][256];  // 只占 1KB
int nextPixelSlot = 0;

struct Message {
    int8_t pixelSlot = -1;  // 指向共享 buffer，-1 = 无
};
```

当分配新 slot 时，旧 slot 对应的 message 被标记为失效。

### 解析逻辑（零堆分配）

在 `onAIResponseComplete()` 时执行：

1. `strstr()` 找 `[PIXELART:N]` 和 `[/PIXELART]`
2. 逐行逐字符解析 hex char → PROGMEM palette → RGB565
3. 存入共享 pixelBuffer，设置 `msg.isPixelArt = true`
4. 释放原始文本 `msg.text = "[pixel art]"`

### 渲染

```cpp
int scale = (pixelSize == 8) ? 12 : 6;  // 都渲染为 96×96px
canvas.fillRect(x + px*scale, y + py*scale, scale, scale, color);
```

### AI Prompt 路由

检测 `/draw` 前缀 → 专用 system prompt（只要求输出像素画格式）→ 不发送对话历史 → 响应上限提至 400 字符。

### 桌面同步

解析完成后调用 `stateBroadcastPixelArt()` → Mac `UDPListener` 收到 `"type":"pixelart"` → `PixelArtPopover` 弹窗 256×256 高清渲染。

## 改动文件

| 文件 | 改动 |
|------|------|
| `src/chat.h` | 调色板常量、Message 扩展、共享缓冲、新方法声明 |
| `src/chat.cpp` | `/draw` 检测、解析器、渲染器、高度计算、广播数据导出 |
| `src/ai_client.h/cpp` | `setPixelArtMode()` + 专用 prompt + 响应上限调整 |
| `desktop/.../PixelArtPopover.swift` | 浮动窗口 256×256 渲染 + 历史浏览 |
