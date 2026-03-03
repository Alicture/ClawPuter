import AppKit

/// NSView subclass that renders the pixel pet sprite
class PetView: NSView {
    private var currentImage: NSImage?
    var facingLeft: Bool = false
    var petState: PetState = .idle
    var spriteSize: CGFloat = 128
    private var sleepStartTime: TimeInterval = 0

    override var isFlipped: Bool { false }

    func updateSprite(_ sprite: [UInt16], facingLeft: Bool, state: PetState) {
        self.facingLeft = facingLeft
        // Track when sleep state begins (for Z animation phase)
        if state == .sleep && self.petState != .sleep {
            sleepStartTime = ProcessInfo.processInfo.systemUptime
        }
        self.petState = state
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
