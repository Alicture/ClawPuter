import AppKit

/// Floating window that displays pixel art at high resolution
class PixelArtPopover {
    private var panel: NSPanel?
    private var imageView: NSImageView?
    private var titleLabel: NSTextField?

    // Palette matching ESP32 side
    private static let palette: [Character: NSColor] = [
        "0": .clear,
        "1": NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1),
        "2": NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1),
        "3": NSColor(red: 220/255, green: 50/255, blue: 47/255, alpha: 1),
        "4": NSColor(red: 160/255, green: 30/255, blue: 25/255, alpha: 1),
        "5": NSColor(red: 230/255, green: 140/255, blue: 60/255, alpha: 1),
        "6": NSColor(red: 250/255, green: 220/255, blue: 50/255, alpha: 1),
        "7": NSColor(red: 50/255, green: 180/255, blue: 50/255, alpha: 1),
        "8": NSColor(red: 30/255, green: 100/255, blue: 30/255, alpha: 1),
        "9": NSColor(red: 40/255, green: 60/255, blue: 200/255, alpha: 1),
        "a": NSColor(red: 100/255, green: 160/255, blue: 240/255, alpha: 1),
        "b": NSColor(red: 130/255, green: 50/255, blue: 180/255, alpha: 1),
        "c": NSColor(red: 230/255, green: 120/255, blue: 180/255, alpha: 1),
        "d": NSColor(red: 120/255, green: 70/255, blue: 30/255, alpha: 1),
        "e": NSColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1),
        "f": NSColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1),
    ]

    // History of received pixel arts
    private var history: [(size: Int, rows: [String])] = []
    private var currentIndex: Int = -1

    func show(size: Int, rows: [String]) {
        // Add to history (cap at 50 entries)
        history.append((size: size, rows: rows))
        if history.count > 50 { history.removeFirst(); currentIndex -= 1 }
        currentIndex = history.count - 1

        renderCurrent()
    }

    private func renderCurrent() {
        guard currentIndex >= 0 && currentIndex < history.count else { return }
        let entry = history[currentIndex]
        let size = entry.size
        let rows = entry.rows

        let scale = size == 8 ? 32 : 16  // 8×8@32x=256px, 16×16@16x=256px
        let imageSize = size * scale

        // Create pixel art image
        let image = NSImage(size: NSSize(width: imageSize, height: imageSize))
        image.lockFocus()

        // Dark background
        NSColor(red: 24/255, green: 20/255, blue: 37/255, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: imageSize, height: imageSize).fill()

        for (rowIdx, row) in rows.prefix(size).enumerated() {
            for (colIdx, char) in row.prefix(size).enumerated() {
                let lowered = Character(String(char).lowercased())
                guard let color = Self.palette[lowered], lowered != "0" else { continue }
                color.setFill()
                // NSImage y-axis is flipped (0 at bottom)
                let rect = NSRect(x: colIdx * scale,
                                  y: imageSize - (rowIdx + 1) * scale,
                                  width: scale, height: scale)
                rect.fill()
            }
        }
        image.unlockFocus()

        if panel == nil {
            createPanel()
        }

        imageView?.image = image
        titleLabel?.stringValue = "\(size)×\(size)  [\(currentIndex + 1)/\(history.count)]"

        panel?.orderFront(nil)
        positionNearMenuBar()
    }

    private func createPanel() {
        let panelW: CGFloat = 300
        let panelH: CGFloat = 330

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelW, height: panelH),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.title = "Pixel Art"
        p.level = .floating
        p.isFloatingPanel = true
        p.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        p.backgroundColor = NSColor(red: 30/255, green: 26/255, blue: 43/255, alpha: 1)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: panelW, height: panelH))

        let iv = NSImageView(frame: NSRect(x: (panelW - 256) / 2, y: 40, width: 256, height: 256))
        iv.imageScaling = .scaleNone
        iv.wantsLayer = true
        iv.layer?.borderColor = NSColor.gray.withAlphaComponent(0.3).cgColor
        iv.layer?.borderWidth = 1
        container.addSubview(iv)
        imageView = iv

        let label = NSTextField(labelWithString: "")
        label.frame = NSRect(x: 10, y: 10, width: panelW - 20, height: 20)
        label.textColor = NSColor(red: 180/255, green: 180/255, blue: 200/255, alpha: 1)
        label.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.alignment = .center
        container.addSubview(label)
        titleLabel = label

        p.contentView = container
        panel = p
    }

    private func positionNearMenuBar() {
        guard let screen = NSScreen.main, let p = panel else { return }
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let x = screenFrame.maxX - p.frame.width - 20
        let y = visibleFrame.maxY - p.frame.height - 10
        p.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func dismiss() {
        panel?.orderOut(nil)
    }
}
