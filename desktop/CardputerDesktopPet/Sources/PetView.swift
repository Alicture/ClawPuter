import AppKit

/// NSView subclass that renders the pixel pet sprite
class PetView: NSView {
    private var currentImage: NSImage?
    var facingLeft: Bool = false
    var petState: PetState = .idle
    var spriteSize: CGFloat = 128
    var weatherType: Int = -1  // -1=none, 0=CLEAR..7=THUNDER
    private var sleepStartTime: TimeInterval = 0

    override var isFlipped: Bool { false }

    func updateSprite(_ sprite: [UInt16], facingLeft: Bool, state: PetState, weatherType: Int = -1) {
        self.facingLeft = facingLeft
        // Track when sleep state begins (for Z animation phase)
        if state == .sleep && self.petState != .sleep {
            sleepStartTime = ProcessInfo.processInfo.systemUptime
        }
        self.petState = state
        self.weatherType = weatherType
        self.currentImage = SpriteRenderer.render(sprite: sprite)
        needsDisplay = true
    }

    /// The rect where the sprite is drawn (bottom-left of the view)
    private var spriteRect: NSRect {
        NSRect(x: 0, y: 0, width: spriteSize, height: spriteSize)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image = currentImage else { return }

        NSGraphicsContext.current?.imageInterpolation = .none

        var drawRect = spriteRect
        if facingLeft {
            // Flip: mirror the sprite rect horizontally within the view
            let transform = NSAffineTransform()
            transform.translateX(by: bounds.width, yBy: 0)
            transform.scaleX(by: -1, yBy: 1)
            transform.concat()
            // Adjust drawRect so sprite stays at the right edge when flipped
            drawRect.origin.x = bounds.width - spriteSize
        }

        image.draw(in: drawRect,
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .sourceOver,
                   fraction: 1.0)

        // Draw accessories (in same coordinate space as sprite, so they flip together)
        drawAccessory(origin: drawRect.origin)

        // Reset transform before drawing Z overlay (always draw right-side up)
        if facingLeft {
            let transform = NSAffineTransform()
            transform.scaleX(by: -1, yBy: 1)
            transform.translateX(by: -bounds.width, yBy: 0)
            transform.concat()
        }

        if petState == .sleep {
            drawSleepZ()
        }
    }

    /// Draw weather-based accessory on the pet (coordinates at 8× sprite scale)
    /// Origin is the bottom-left of the sprite rect in view coordinates.
    /// Sprite pixel (px, py) maps to: x = origin.x + px*8, y = origin.y + spriteSize - py*8 - 8
    private func drawAccessory(origin: NSPoint) {
        // Determine accessory from weather type
        // 0=CLEAR, 1=PARTLY_CLOUDY → sunglasses
        // 4=DRIZZLE, 5=RAIN, 7=THUNDER → umbrella
        // 6=SNOW → snow hat
        // 2=OVERCAST, 3=FOG → mask
        let ox = origin.x
        let oy = origin.y

        switch weatherType {
        case 0, 1: // Sunglasses
            let glassColor = NSColor(red: 20/255, green: 20/255, blue: 40/255, alpha: 1)
            glassColor.setFill()
            // Left lens (ESP32: x+12, y+15, 9×3 at 3× → sprite ~col 4, row 5)
            NSRect(x: ox + 32, y: oy + spriteSize - 40 - 8, width: 24, height: 8).fill()
            // Right lens (ESP32: x+27, y+15)
            NSRect(x: ox + 72, y: oy + spriteSize - 40 - 8, width: 24, height: 8).fill()
            // Bridge (ESP32: x+21, y+16, 6)
            NSRect(x: ox + 56, y: oy + spriteSize - 43 - 3, width: 16, height: 3).fill()

        case 4, 5, 7: // Umbrella
            // Canopy (ESP32: x+6, y-10, 36×8, rounded)
            let umbColor = NSColor(red: 60/255, green: 60/255, blue: 200/255, alpha: 1)
            umbColor.setFill()
            let canopyRect = NSRect(x: ox + 16, y: oy + spriteSize + 6, width: 96, height: 21)
            NSBezierPath(roundedRect: canopyRect, xRadius: 11, yRadius: 11).fill()
            // Handle (ESP32: x+24, y-2, VLine 8px)
            NSColor(red: 120/255, green: 80/255, blue: 40/255, alpha: 1).setFill()
            NSRect(x: ox + 62, y: oy + spriteSize - 16, width: 4, height: 22).fill()

        case 6: // Snow hat
            // Hat body (ESP32: x+9, y+3, 30×6, rounded)
            NSColor(red: 200/255, green: 60/255, blue: 60/255, alpha: 1).setFill()
            let hatRect = NSRect(x: ox + 24, y: oy + spriteSize - 8 - 16, width: 80, height: 16)
            NSBezierPath(roundedRect: hatRect, xRadius: 8, yRadius: 8).fill()
            // Pompom (ESP32: fillCircle x+24, y+2, r=3)
            NSColor.white.setFill()
            let pompomRect = NSRect(x: ox + 56, y: oy + spriteSize - 5 + 5, width: 16, height: 16)
            NSBezierPath(ovalIn: pompomRect).fill()

        case 2, 3: // Mask
            let maskColor = NSColor(red: 180/255, green: 200/255, blue: 180/255, alpha: 1)
            maskColor.setFill()
            // Mask body (ESP32: x+12, y+21, 24×6)
            NSRect(x: ox + 32, y: oy + spriteSize - 56 - 16, width: 64, height: 16).fill()
            // Ear straps
            NSColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1).setFill()
            NSRect(x: ox + 24, y: oy + spriteSize - 61 - 3, width: 8, height: 3).fill()
            NSRect(x: ox + 96, y: oy + spriteSize - 61 - 3, width: 8, height: 3).fill()

        default:
            break // No accessory
        }
    }

    /// Draw floating "z Z Z" animation matching the Cardputer firmware layout
    /// Z's float diagonally up-right from the head into the padding area
    private func drawSleepZ() {
        let elapsed = ProcessInfo.processInfo.systemUptime - sleepStartTime
        let phase = Int(elapsed / 0.6) % 4  // 4 phases, 600ms each, matching firmware

        let color = NSColor.white.withAlphaComponent(0.9)

        // Phase 1: small "z" — right of head, near eye level
        if phase >= 1 {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
                .foregroundColor: color
            ]
            "z".draw(at: NSPoint(x: 106, y: 68), withAttributes: attrs)
        }

        // Phase 2: + medium "Z" — higher and further right
        if phase >= 2 {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 20, weight: .bold),
                .foregroundColor: color
            ]
            "Z".draw(at: NSPoint(x: 118, y: 96), withAttributes: attrs)
        }

        // Phase 3: + large "Z" — top-right, big and dramatic
        if phase >= 3 {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 34, weight: .bold),
                .foregroundColor: color
            ]
            "Z".draw(at: NSPoint(x: 112, y: 132), withAttributes: attrs)
        }
    }
}
