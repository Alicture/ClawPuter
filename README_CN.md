# Cardputer Companion 🦞

[English](README.md)

M5Stack Cardputer (ESP32-S3) 上的像素风桌面伴侣。小龙虾角色 + 动画 + 实时天气 + AI 聊天 + 语音输入/TTS + macOS 桌面宠物同步。

## 功能

- **伴侣模式** — 像素小龙虾，支持待机、开心、睡觉、说话、伸懒腰、东张西望等动画。键盘方向键移动（按住持续走）。时光倒流天空（向左走=过去，向右走=未来）。NTP 时钟显示。
- **实时天气** — 每 15 分钟从 Open-Meteo 获取天气数据（免费，无需 API Key）。根据天气类型显示雨滴、雪花、雾气、雷电闪光等背景特效。宠物自动佩戴天气配饰（墨镜、雨伞、雪帽、口罩）。时钟旁显示实时温度。
- **天气模拟** — Fn+W 切换模拟模式，数字键 1-8 预览全部 8 种天气类型（晴天、多云、阴天、雾、小雨、大雨、雪、雷暴）。
- **聊天模式** — 键盘输入，AI 对话支持 SSE 流式响应（逐字显示），消息自动换行和翻页滚动。
- **语音输入** — 按住 Fn 键说话（最长 3 秒），松开后通过 Groq Whisper API 语音转文字，识别结果自动填入输入栏。
- **TTS 语音回复** — AI 回复通过扬声器朗读。按任意键可中断播放。麦克风和扬声器共享 GPIO 43，系统自动切换。
- **桌面宠物同步** — macOS 端桌面宠物应用，通过 UDP 接收小龙虾状态、位置和天气信息，实时同步动画。在 Cardputer 上移动宠物，桌面上也跟着动。
- **OpenClaw 集成** — 局域网连接本地 OpenClaw Gateway。多模型自动切换（Kimi/Claude/GPT/Gemini），持久记忆，5400+ 社区技能。
- **双 WiFi + 离线模式** — 主 WiFi 连不上自动尝试备用（手机热点），Gateway IP 自动切换。所有 WiFi 都失败可进入离线模式（伴侣模式正常可用，聊天显示离线提示）。
- **运行时配置** — Setup 向导支持运行时修改 WiFi、Gateway、STT Host，编译时值作为默认，Fn+R 重置。
- **开机动画** — 小龙虾像素画逐行渐入，模式切换像素擦除过渡。
- **音效** — 按键咔嗒、开心音阶、AI 流式回复打字音、通知提示音。

## 快速开始

### 1. 设置环境变量

```bash
# WiFi
export WIFI_SSID="<your-wifi-ssid>"
export WIFI_PASS="<your-wifi-password>"

# AI 后端（OpenClaw Gateway）
export OPENCLAW_HOST="<your-host-ip>"       # OpenClaw Gateway 局域网 IP
export OPENCLAW_PORT="<your-port>"           # Gateway 端口
export OPENCLAW_TOKEN="<your-gateway-token>"

# 语音输入（可选，供 stt_proxy.py 使用）
export GROQ_API_KEY="<your-groq-api-key>"    # 供 tools/stt_proxy.py 使用，非固件
export STT_PROXY_HOST="<your-host-ip>"       # 运行 stt_proxy.py 的机器 IP
export STT_PROXY_PORT="8090"                 # STT 代理端口（默认 8090）

# 天气（可选）
export DEFAULT_CITY="Beijing"                # 天气查询城市

# 备用 WiFi（可选，手机热点降级）
export WIFI_SSID2="<your-hotspot-ssid>"
export WIFI_PASS2="<your-hotspot-password>"
export OPENCLAW_HOST2="<your-hotspot-host-ip>"  # 热点网络上 Mac 的 IP
```

### 2. 编译烧录

```bash
pio run -t upload
```

首次烧录需要手动进入下载模式：按住 **G0** + 按 **Reset**，然后松开 G0。详见[烧录指南](docs/setup-and-flash.md)。

### 3. 启动 STT 代理（语音输入）

```bash
python3 tools/stt_proxy.py
```

代理运行在 Mac/PC 上，将 Cardputer 录制的音频转发到 Groq Whisper API 进行语音识别。需要在 `.env` 或环境变量中配置 `GROQ_API_KEY`。

### 4. 串口调试

```bash
pio device monitor
```

## 操作方式

| 按键 | 伴侣模式 | 聊天模式 |
|------|---------|---------|
| TAB | 切换到聊天 | 切换到伴侣 |
| `,`（按住） | 向左移动 | — |
| `/`（按住） | 向右移动 | — |
| `;`（按住） | 向上移动 | — |
| `.`（按住） | 向下移动 | — |
| 空格 / Enter | 角色开心跳跃 | 发送消息 |
| Backspace | — | 删除字符 |
| Fn（长按） | — | 按住说话，松开转文字 |
| Fn + ; | — | 向上翻页 |
| Fn + / | — | 向下翻页 |
| Fn + W | 切换天气模拟 | — |
| 1-8（天气模拟中） | 切换天气类型 | — |
| Fn + R | 重置配置 + Setup 向导 | — |
| 任意键（睡眠中） | 唤醒角色 | — |
| 任意键（TTS 播放中） | — | 中断语音播放 |
| TAB（Setup 中） | 退出向导，进入伴侣模式 | — |

## 玩法详解

### 伴侣模式 — 你的像素宠物

小龙虾生活在 240×135 像素的屏幕上，背景会随时间和天气动态变化：

- **日夜循环** — 天空颜色根据 NTP 实时时间变化。白天蓝天白云，17-19 点橙色夕阳，19 点后深色夜空配闪烁星星和月亮。
- **时光倒流天空** — 向左/右移动宠物会让天空偏移 ±12 小时。走到最左边看昨晚的星空，走到最右边看明天的日出。底部时钟始终显示真实时间。
- **自发动作** — 宠物每 8-15 秒随机伸懒腰或东张西望。30 秒无互动后自动入睡，显示 "Zzz" 动画。按任意键唤醒。
- **键盘移动** — 按住 `,` `/` `;` `.` 持续走动，精灵自动翻转朝向。
- **互动** — 按空格或 Enter 让宠物开心跳跃，配欢快音效。

### 天气系统

- **自动刷新**：每 15 分钟从 Open-Meteo 获取天气数据（免费，不需要 API Key），根据 `DEFAULT_CITY` 配置自动定位。
- **背景特效**：雨滴下落、雪花飘飞（带横向漂移）、雾气点阵闪烁、雷暴白色闪光。天空色调随天气变暗。
- **宠物配饰**：晴天/多云戴墨镜 🕶️、雨天/雷暴撑雨伞 ☂️、下雪戴红色雪帽 🎅、雾天/阴天戴口罩 😷。配饰随精灵左右翻转。
- **温度显示**：时钟旁显示当前温度（°），用竖线分隔。
- **模拟模式**：Fn+W 进入天气模拟，用数字键 1-8 切换 8 种天气：1=晴天 2=多云 3=阴天 4=雾 5=小雨 6=大雨 7=雪 8=雷暴。底部显示 `[SIM] 天气名称` 状态栏。再按 Fn+W 退出。

### 聊天模式 — AI 对话

- 键盘输入消息，Enter 发送。AI 回复逐字流式显示，配打字音效。
- **语音输入**：按住 Fn 录音（最长 3 秒），松开后发送到 Groq Whisper 转文字。转写过程中显示 "Transcribing..." 进度条。
- **TTS 语音回复**：AI 回复完成后，通过扬声器朗读回复内容。按任意键可中断播放。
- **离线模式**：未连接 WiFi 时，发送消息显示 `[Offline] No network connection`。

### 桌面宠物同步

- macOS Swift 应用（`desktop/CardputerDesktopPet/`）通过 UDP 广播接收宠物状态、位置和天气。
- 在 Cardputer 上移动宠物 → 桌面宠物同步移动。动画状态实时同步。

### 联网与配置

- **双 WiFi**：主 WiFi 连不上 → 自动尝试备用 WiFi（如手机热点），Gateway IP 自动切换。
- **离线模式**：所有 WiFi 失败后，按 Tab 进入离线伴侣模式（动画、时钟、音效照常工作）。
- **运行时配置**：Fn+R 打开 Setup 向导，可修改 WiFi SSID/密码、Gateway 地址/端口/Token、STT Host，无需重新烧录。
- **WiFi 失败菜单**：连接失败后提供三个选项——重试 / Setup 向导 / 离线模式。

## 项目结构

```
src/
├── main.cpp              # 入口，模式调度，WiFi/NTP
├── companion.h/cpp       # 伴侣模式：动画、状态机、时钟、天气特效
├── chat.h/cpp            # 聊天模式：消息气泡、输入栏、滚动
├── ai_client.h/cpp       # AI 客户端（OpenClaw/Claude），SSE 流式响应
├── voice_input.h/cpp     # 按键说话录音、WAV 编码、STT 代理客户端
├── tts_playback.h/cpp    # TTS 语音回复，PCM 下载 + DMA 播放
├── weather_client.h/cpp  # Open-Meteo 天气 API、地理编码、15 分钟自动刷新
├── state_broadcast.h/cpp # UDP 状态广播，桌面宠物同步
├── sprites.h             # 像素小龙虾素材（RGB565）
├── config.h/cpp          # WiFi/API 配置，NVS 持久化
└── utils.h               # 颜色定义、屏幕常量、定时器

desktop/
└── CardputerDesktopPet/  # macOS 桌面宠物（Swift，接收 UDP 状态同步）

tools/
└── stt_proxy.py          # 本地 HTTP 代理：ESP32 音频 → Groq Whisper API + TTS
```

## iPhone 热点小贴士

使用 iPhone 热点作为备用 WiFi 时：

1. **开启"最大化兼容性"** — 进入设置 > 个人热点，打开此选项。iPhone 默认 5GHz，ESP32 只支持 2.4GHz。
2. **保持热点设置页面打开** — iPhone 热点无设备连接时进入休眠，ESP32 扫描不到。需在 iPhone 上打开"个人热点"设置页面保持唤醒。
3. **UDP 广播被隔离** — iPhone 热点有客户端隔离，设备间 UDP 广播被过滤。固件已做绕过：同时发 broadcast + unicast 到 Gateway IP。
4. **查看 Mac 的热点 IP** — Mac 连上 iPhone 热点后，用 `ifconfig en0` 查看 IP（通常是 `172.20.10.x`），设为 `OPENCLAW_HOST2`。

## 硬件

- **M5Stack Cardputer** — ESP32-S3，240×135 IPS 屏幕，56 键键盘，PDM 麦克风（SPM1423），扬声器（与麦克风共享 GPIO 43）
- ESP32-S3 **仅支持 2.4GHz WiFi**（不支持 5GHz）

## OpenClaw 配置

本项目连接运行在 Mac 或 VPS 上的 OpenClaw Gateway：

1. [安装 OpenClaw](https://openclaw.ai)
2. 在 `~/.openclaw/openclaw.json` 中启用局域网绑定和 HTTP API：
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
3. 重启 Gateway：`openclaw gateway restart`
4. 将 `OPENCLAW_HOST` 设为 Mac 的局域网 IP

完整集成方案见 [OpenClaw 调研文档](docs/openclaw-research.md)。

## 文档

- [环境搭建与烧录](docs/setup-and-flash.md)
- [硬件要点](docs/hardware-notes.md)
- [API 接入记录](docs/api-integration.md)
- [代码架构](docs/architecture.md)
- [OpenClaw 集成](docs/openclaw-research.md)
- [语音输入设计](docs/voice-input-design.md)
- [桌面宠物设计](docs/desktop-pet-design.md)
- [UDP 状态同步设计](docs/udp-state-sync-design.md)
- [ESP32 内存踩坑记录](docs/esp32-voice-chat-lessons.md)
- [问题排查](docs/troubleshooting.md)
- [路线图](docs/roadmap.md)

## 路线图

- [x] 流式响应（SSE 逐字显示）
- [x] 语音输入（按住说话 + Groq Whisper 语音转文字）
- [x] 桌面宠物同步（macOS 端通过 UDP 同步）
- [x] 双 WiFi + 离线模式 + 运行时配置
- [x] TTS 语音回复（AI 通过扬声器播放回复）
- [x] 宠物移动 + 时光倒流天空 + 桌面位置同步
- [x] 实时天气（Open-Meteo API + 背景特效 + 宠物配饰）
- [x] 天气模拟模式（Fn+W + 1-8 预览全部天气类型）
- [ ] 电量显示 + 低电量角色变虚弱
- [ ] 聊天历史持久化（NVS/SD 卡）
- [ ] 养成系统（饥饿值/心情值）
- [ ] 番茄钟
- [ ] BLE 手机通知推送

完整路线图见 [roadmap.md](docs/roadmap.md)。

## 许可证

MIT
