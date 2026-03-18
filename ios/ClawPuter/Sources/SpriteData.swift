import Foundation

// RGB565 color conversion matching Cardputer's utils.h
func rgb565(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> UInt16 {
    (UInt16(r & 0xF8) << 8) | (UInt16(g & 0xFC) << 3) | UInt16(b >> 3)
}

// Color aliases — OpenClaw lobster palette (matching sprites.h)
// Swift reserves `_`, so we use `T_` for transparent
private let T_: UInt16 = rgb565(255, 0, 255) // Transparent (magenta)
private let K: UInt16 = 0x0000               // Black (outline)
private let W: UInt16 = 0xFFFF               // White (eyes)
private let R: UInt16 = rgb565(210, 50, 40)  // Red (main body)
private let D: UInt16 = rgb565(160, 30, 25)  // Dark red (shadow/belly)
private let H: UInt16 = rgb565(240, 100, 80) // Highlight red (light)
private let O: UInt16 = rgb565(230, 140, 60) // Orange (belly/claws inner)
private let E: UInt16 = rgb565(20, 20, 20)   // Eye pupil
private let C: UInt16 = rgb565(190, 40, 35)  // Claw red
private let T: UInt16 = rgb565(180, 60, 50)  // Tail/legs

let SPRITE_W = 16
let SPRITE_H = 16
let TRANSPARENT_COLOR: UInt16 = rgb565(255, 0, 255) // Magenta = transparent

// Using T_ for transparent since _ is a keyword in Swift
// Each sprite is 16x16 = 256 pixels

// ── Idle frame 1: eyes open, claws down ──
let sprite_idle1: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Idle frame 2: blink ──
let sprite_idle2: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,K, R, R, K, K, R, R, K, K, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Idle frame 3: body bob (1px down) ──
let sprite_idle3: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Happy frame 1: claws up! ──
let sprite_happy1: [UInt16] = [
    K, C, C, K, T_,T_,T_,T_,T_,T_,T_,T_,K, C, C, K,
    K, C, C, K, T_,T_,T_,T_,T_,T_,T_,T_,K, C, C, K,
    T_,K, K, T_,K, K, K, K, K, K, K, K, T_,K, K, T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, H, H, R, R, H, H, R, R, K, T_,T_,
    T_,T_,K, R, R, H, E, R, R, H, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, O, K, K, O, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, K, K, K, T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
]

// ── Happy frame 2: claws spread wide ──
let sprite_happy2: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    K, C, K, T_,K, K, K, K, K, K, K, K, T_,K, C, K,
    K, C, C, K, R, R, R, R, R, R, R, R, K, C, C, K,
    T_,K, K, K, R, R, R, R, R, R, R, R, K, K, K, T_,
    T_,T_,K, R, R, H, H, R, R, H, H, R, R, K, T_,T_,
    T_,T_,K, R, R, H, E, R, R, H, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, O, K, K, O, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
]

// ── Sleep frame 1: eyes closed, claws tucked ──
let sprite_sleep1: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,K, R, R, K, K, R, R, K, K, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Talk frame 1: mouth open ──
let sprite_talk1: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, K, O, O, K, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, K, K, K, K, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Talk frame 2: mouth closed ──
let sprite_talk2: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, K, K, K, K, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// Using T_ for transparent since _ is a keyword in Swift
// Each sprite is 16x16 = 256 pixels

// ── Walk Frame 1: legs apart, left forward ──
let sprite_walk1: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    K, C, C, C, K, T_,K, D, D, K, T_,K, C, C, C, K,
    K, C, C, K, T_,T_,K, D, D, K, T_,T_,K, C, C, K,
    T_,K, K, T_,T_,T_,K, D, D, K, T_,T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Walk Frame 2: legs together (mid-stride) ──
let sprite_walk2: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, K, R, R, R, R, K, T_,T_,T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    T_,T_,T_,K, K, K, T_,D, D, T_,K, K, K, T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, T, T, K, T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, T_,T_,K, T_,T_,T_,T_,T_,T_,
]

// ── Walk Frame 3: legs apart, right forward ──
let sprite_walk3: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,
    K, C, C, C, K, T_,K, D, D, K, T_,K, C, C, C, K,
    K, C, C, K, T_,T_,K, D, D, K, T_,T_,K, C, C, K,
    T_,K, K, T_,T_,T_,K, D, D, K, T_,T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Walk Frame 4: legs together (mid-stride back) ──
let sprite_walk4: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, K, R, R, R, R, K, T_,T_,T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    T_,T_,T_,K, K, K, T_,D, D, T_,K, K, K, T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, T, T, K, T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, T_,T_,K, T_,T_,T_,T_,T_,T_,
]

// ── Walk Frame 5: left foot forward, right back ──
let sprite_walk5: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,T_,
    K, C, C, K, T_,K, K, D, D, K, K, T_,K, C, C, K,
    K, C, C, K, T_,T_,K, D, D, K, T_,T_,K, C, C, K,
    T_,K, K, T_,T_,T_,K, D, D, K, T_,T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Walk Frame 6: right foot forward, left back ──
let sprite_walk6: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, C, C, K, D, D, K, C, C, K, T_,T_,
    K, C, C, K, T_,K, K, D, D, K, K, T_,K, C, C, K,
    K, C, C, K, T_,T_,K, D, D, K, T_,T_,K, C, C, K,
    T_,K, K, T_,T_,T_,K, D, D, K, T_,T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Eat Frame 1: mouth open, reaching down ──
let sprite_eat1: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, K, K, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, K, T_,K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, K, T, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Eat Frame 2: mouth closed, chewing ──
let sprite_eat2: [UInt16] = [
    T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,
    T_,T_,T_,K, T_,T_,T_,T_,T_,T_,T_,T_,K, T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    K, C, C, K, T_,K, D, D, D, D, K, T_,K, C, C, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, T, K, T, T, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// ── Play Frame 1: excited pose, claws up high ──
let sprite_play1: [UInt16] = [
    T_,T_,T_,T_,K, C, C, K, K, C, C, K, T_,T_,T_,T_,
    T_,T_,K, C, C, K, T_,T_,T_,T_,K, C, C, K, T_,T_,
    K, C, C, K, T_,T_,T_,T_,T_,T_,T_,T_,K, C, C, K,
    K, C, C, K, T_,K, K, K, K, K, K, T_,K, C, C, K,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    T_,T_,T_,K, R, H, H, R, R, H, H, R, K, T_,T_,T_,
    T_,T_,T_,K, R, H, E, R, R, H, E, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, O, K, K, O, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, K, K, K, T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
]

// ── Play Frame 2: spinning/excited bounce ──
let sprite_play2: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, C, C, C, C, K, T_,T_,T_,T_,T_,
    T_,T_,T_,K, C, C, C, K, K, C, C, C, K, T_,T_,T_,
    T_,T_,K, C, C, K, T_,T_,T_,T_,K, C, C, C, K, T_,
    T_,K, C, C, K, T_,K, R, R, R, K, T_,T_,K, C, C, K,
    T_,K, C, C, K, T_,R, H, H, R, R, K, T_,K, C, C, K,
    T_,T_,K, K, T_,K, R, H, E, R, R, K, T_,K, K, T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,K, R, R, O, K, O, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, D, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, D, D, K, T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,K, K, T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
]

// ── Wave Frame 1: arm raised, happy face ──
let sprite_wave1: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,K, C, C, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,K, C, C, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, C, C, C, C, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,K, K, K, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,K, R, R, H, H, R, R, H, H, R, R, K, T_,T_,
    T_,T_,K, R, R, H, E, R, R, H, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, K, O, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, K, K, K, T_,T_,T_,T_,T_,T_,
]

// ── Wave Frame 2: arm waving ──
let sprite_wave2: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,K, C, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,K, C, C, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,K, C, C, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, C, C, C, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, K, K, K, K, K, K, T_,T_,T_,
    T_,T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,K, R, R, H, H, R, R, H, H, R, R, K, T_,T_,
    T_,T_,K, R, R, H, E, R, R, H, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, K, O, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, K, K, K, T_,T_,T_,T_,T_,T_,
]

// ── Excited Frame 1: super happy, bouncing ──
let sprite_excited1: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,K, C, C, K, K, C, C, K, T_,T_,T_,T_,
    T_,T_,T_,K, C, C, K, T_,T_,T_,K, C, C, K, T_,T_,
    T_,T_,K, C, C, K, T_,K, K, K, T_,K, C, C, K, T_,
    T_,T_,K, C, K, T_,K, R, R, R, K, T_,K, C, K, T_,
    T_,T_,T_,T_,T_,K, R, H, H, R, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, R, H, E, R, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, R, R, R, R, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,K, R, R, O, K, O, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,T_,K, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,T_,T_,T_,K, D, D, D, D, D, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, D, D, D, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,K, K, K, T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
]

// ── Excited Frame 2: highest bounce ──
let sprite_excited2: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,K, C, C, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,K, C, C, C, C, K, T_,T_,T_,
    T_,T_,T_,T_,T_,T_,K, C, C, K, T_,K, C, C, K, T_,
    T_,T_,T_,T_,T_,K, R, R, R, K, T_,K, R, R, R, K,
    T_,T_,T_,T_,T_,K, R, H, H, R, K, T_,R, H, H, R,
    T_,T_,T_,T_,T_,K, R, H, E, R, K, T_,R, H, E, R,
    T_,T_,T_,T_,T_,K, R, R, R, R, K, T_,R, R, R, R,
    T_,T_,T_,T_,K, R, R, O, K, O, R, R, K, O, K, O,
    T_,T_,T_,T_,K, R, R, R, R, R, R, R, R, R, R, R,
    T_,T_,T_,T_,T_,K, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,T_,T_,T_,K, D, D, D, D, D, K, T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,K, D, D, D, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,K, K, K, T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
]

// ── Weather: Rain coat pose (standing in rain) ──
let sprite_raincoat: [UInt16] = [
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,T_,
    T_,T_,T_,T_,K, K, K, K, K, K, K, K, T_,T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,T_,K, R, R, W, W, R, R, W, W, R, R, K, T_,T_,
    T_,T_,K, R, R, W, E, R, R, W, E, R, R, K, T_,T_,
    T_,T_,K, R, R, R, R, R, R, R, R, R, R, K, T_,T_,
    T_,T_,T_,K, R, R, R, O, O, R, R, R, K, T_,T_,T_,
    T_,T_,T_,K, R, R, R, R, R, R, R, R, K, T_,T_,T_,
    T_,K, K, T_,K, R, R, R, R, R, R, K, T_,K, K, T_,
    K, R, R, K, T_,K, D, D, D, D, K, T_,K, R, R, K,
    K, R, R, K, T_,K, D, D, D, D, K, T_,K, R, R, K,
    T_,K, K, T_,T_,K, D, D, D, D, K, T_,T_,K, K, T_,
    T_,T_,T_,T_,K, T, K, D, D, K, T, K, T_,T_,T_,T_,
    T_,T_,T_,T_,T_,K, T_,K, K, T_,K, T_,T_,T_,T_,T_,
]

// Frame lookup arrays (matching Cardputer firmware)
struct SpriteFrames {
    static let idle: [[UInt16]] = [sprite_idle1, sprite_idle2, sprite_idle1, sprite_idle3]
    static let happy: [[UInt16]] = [sprite_happy1, sprite_happy2]
    static let sleep: [[UInt16]] = [sprite_sleep1]
    static let talk: [[UInt16]] = [sprite_talk1, sprite_talk2]
    // Full walk cycle with 6 frames showing leg movement
    static let walk: [[UInt16]] = [sprite_walk1, sprite_walk2, sprite_walk3, sprite_walk4, sprite_walk5, sprite_walk6]
    // Eat animation frames
    static let eat: [[UInt16]] = [sprite_eat1, sprite_eat2, sprite_eat1, sprite_eat2]
    // Play/excited animation frames
    static let play: [[UInt16]] = [sprite_play1, sprite_play2, sprite_play1, sprite_play2]
    // Wave animation frames
    static let wave: [[UInt16]] = [sprite_wave1, sprite_wave2, sprite_wave1, sprite_wave2]
    // Excited animation frames
    static let excited: [[UInt16]] = [sprite_excited1, sprite_excited2, sprite_excited1, sprite_excited2]
    // Weather-specific frames
    static let raincoat: [[UInt16]] = [sprite_raincoat]
    // Legacy aliases
    static let stretch: [[UInt16]] = [sprite_happy1, sprite_happy2]
    static let look: [[UInt16]] = [sprite_idle1, sprite_idle2, sprite_idle1, sprite_idle3]
}
