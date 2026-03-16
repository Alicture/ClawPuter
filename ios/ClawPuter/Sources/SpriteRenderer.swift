import SwiftUI
import CoreGraphics

/// Converts RGB565 sprite data to CGImage for display in SwiftUI
enum SpriteRenderer {

    /// Convert a 16x16 RGB565 sprite to a CGImage scaled up by `scale` factor
    static func render(sprite: [UInt16], scale: Int = 8) -> CGImage? {
        let w = SPRITE_W
        let h = SPRITE_H
        guard sprite.count == w * h else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let buffer = context.data else {
            return nil
        }

        // Convert RGB565 → RGBA8888
        let rgba = buffer.assumingMemoryBound(to: UInt8.self)
        for i in 0..<(w * h) {
            let pixel = sprite[i]
            if pixel == TRANSPARENT_COLOR {
                rgba[i * 4 + 0] = 0
                rgba[i * 4 + 1] = 0
                rgba[i * 4 + 2] = 0
                rgba[i * 4 + 3] = 0
            } else {
                let r5 = (pixel >> 11) & 0x1F
                let g6 = (pixel >> 5) & 0x3F
                let b5 = pixel & 0x1F
                rgba[i * 4 + 0] = UInt8((r5 << 3) | (r5 >> 2))
                rgba[i * 4 + 1] = UInt8((g6 << 2) | (g6 >> 4))
                rgba[i * 4 + 2] = UInt8((b5 << 3) | (b5 >> 2))
                rgba[i * 4 + 3] = 255
            }
        }

        guard let smallImage = context.makeImage() else { return nil }

        // Scale up with nearest-neighbor
        let scaledW = w * scale
        let scaledH = h * scale
        guard let scaledContext = CGContext(
            data: nil,
            width: scaledW,
            height: scaledH,
            bitsPerComponent: 8,
            bytesPerRow: scaledW * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        scaledContext.interpolationQuality = .none
        scaledContext.draw(smallImage, in: CGRect(x: 0, y: 0, width: scaledW, height: scaledH))

        return scaledContext.makeImage()
    }
}
