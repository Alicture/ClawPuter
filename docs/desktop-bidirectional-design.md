# 桌面联动增强：双向通信实现文档

## Overview

ESP32 Cardputer 与 Mac 桌面宠物之间的双向通信系统。ESP32→Mac 通过 UDP 19820（像素画、聊天消息），Mac→ESP32 通过 UDP 19822（控制命令）。

## 通信架构

```
  ESP32 (Cardputer)                    Mac (Desktop App)

  UDP 19820 (现有)     ────────>       UDPListener
  状态广播 5Hz                          解析 state + 新消息类型

  UDP 19820 (新增)     ────────>       UDPListener
  像素画/聊天 (broadcast once)          onPixelArtReceived / onChatMessageReceived

  UDP 19822 (新增)     <────────       TCPSender (实际用 UDP)
  命令服务器                            控制命令、文字、通知
```

### 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| ESP32→Mac | 复用 UDP 19820 | 通过 `"type"` 字段区分消息类型，向后兼容 |
| Mac→ESP32 | UDP 19822 | TCP 被 macOS 本地网络隐私阻止（见踩坑记录），UDP sendto 无此问题 |
| 发现机制 | UDP 源 IP 自动提取 | `recvfrom()` 提取 ESP32 IP，零配置 |
| 一次性消息 | broadcast only | chat/pixelart 用 `sendPacketOnce()` 避免 broadcast+unicast 重复 |

## 协议规格

### ESP32 → Mac 消息类型

**状态同步（现有，5Hz 广播）**
```json
{"s":0,"f":1,"m":"COMPANION","x":0.50,"y":0.80,"d":0,"w":5,"t":22.3}
```

**像素画数据（新增，一次性 broadcast）**
```json
{"type":"pixelart","size":8,"rows":["00330000","03333300",...]}
```

**聊天消息（新增，一次性 broadcast）**
```json
{"type":"chat","role":"user","text":"Hello"}
{"type":"chat","role":"ai","text":"Hi there!"}
```

### Mac → ESP32 命令（UDP 19822）

发送 JSON + `\n`，ESP32 返回 `{"ok":true}`。

| 命令 | 格式 | 说明 |
|------|------|------|
| 触发动画 | `{"cmd":"animate","state":"happy"}` | happy/idle/sleep/talk |
| 输入文字 | `{"cmd":"text","msg":"Hello"}` | 放入聊天输入框 |
| 发送消息 | `{"cmd":"say","msg":"Hello"}` | 放入并自动发送 |
| 通知 | `{"cmd":"notify","app":"Messages","title":"Mom","body":"Dinner?"}` | 3 秒 toast |
| 请求历史 | `{"cmd":"history"}` | 返回聊天记录 JSON |

## 改动文件清单

### ESP32 新增
- `src/cmd_server.h` — 命令服务器头文件（TCP 19821 + UDP 19822）
- `src/cmd_server.cpp` — 双协议命令接收、JSON 解析、回调分发

### ESP32 修改
- `src/state_broadcast.h/cpp` — 新增 `stateBroadcastPixelArt()`, `stateBroadcastChatMsg()`, `sendPacketOnce()`
- `src/companion.h/cpp` — 新增 `showNotification()` toast、`triggerSleep()`
- `src/main.cpp` — 接入 cmdServer + 回调注册 + 聊天/像素画广播

### Mac 新增
- `Sources/TCPSender.swift` — UDP 命令客户端（名称保留历史兼容）
- `Sources/PixelArtPopover.swift` — 浮动像素画展示窗口（256×256 高清渲染）
- `Sources/ChatViewerWindow.swift` — 聊天历史查看器 + 远程发送
- `Info.plist` — NSLocalNetworkUsageDescription（本地网络权限）
- `run.sh` — .app bundle 构建脚本

### Mac 修改
- `Sources/UDPListener.swift` — `recvfrom()` 提取源 IP、解析新消息类型
- `Sources/AppDelegate.swift` — Control 菜单、Chat Viewer、连接状态、宠物 perch
- `Sources/PetBehavior.swift` — 新增 `perchTarget` 支持窗口停靠

## 踩坑记录

### macOS 本地网络隐私阻止 TCP 出站

**现象**：Mac 端 BSD socket `connect()` 到 ESP32 返回 `EHOSTUNREACH (errno=65)`，但 `ping` 和 `nc` 从终端正常。NWConnection 同样超时。甚至 `Process` 启动 `nc` 也被阻止。

**根因**：macOS 26 (Tahoe) 对未签名的 SPM 裸可执行文件施加本地网络限制。入站 UDP 监听（被动）不受影响，但出站 TCP/UDP 连接（主动）被静默拒绝。系统工具（nc、ping）有 Apple 签名，不受限。

**解决方案**：
1. 将可执行文件包装为 `.app` bundle + `Info.plist`（含 `NSLocalNetworkUsageDescription`）
2. Ad-hoc 签名 `codesign --force --sign -`
3. 通过 `open` 启动（LaunchServices 注册触发 TCC 权限弹窗）
4. Mac→ESP32 改用 UDP `sendto()`（比 TCP `connect()` 限制更松）

### 聊天消息重复

**现象**：Chat Viewer 每条消息显示两次。

**根因**：`sendPacket()` 同时发送 broadcast + unicast，Mac 收到两份。

**解决方案**：新增 `sendPacketOnce()` 只发 broadcast，用于 chat/pixelart 等一次性消息。state sync 仍用 `sendPacket()`（幂等，双发无害）。

## 安全注意事项

- 命令服务器无认证（局域网内任何设备可发命令）— 未来可加 token 校验
- 聊天内容通过 UDP broadcast 明文传输 — 未来可改为 unicast 到已知 IP
- `snprintf` 返回值已加截断保护，防止 buffer over-read
- Mac 端 chat/pixelart 历史有上限（500/50 条）防止内存增长
