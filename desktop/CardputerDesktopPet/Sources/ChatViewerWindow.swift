import AppKit

/// Window that displays synced chat messages from the Cardputer
class ChatViewerWindow: NSObject, NSTextFieldDelegate {
    private var window: NSWindow?
    private var scrollView: NSScrollView?
    private var textView: NSTextView?
    private var inputField: NSTextField?

    private var messages: [(role: String, text: String)] = []
    private var autoScroll = true

    /// Callback when user sends a message from the input field
    var onSendMessage: ((String) -> Void)?

    /// Whether the chat window is currently visible
    var isWindowVisible: Bool { window?.isVisible ?? false }

    /// The chat window's frame in screen coordinates
    var windowFrame: NSRect? { window?.frame }

    func addMessage(role: String, text: String) {
        messages.append((role: role, text: text))
        if messages.count > 500 { messages.removeFirst() }
        updateTextView()
    }

    func show() {
        if window == nil {
            createWindow()
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        window?.orderOut(nil)
    }

    private func createWindow() {
        let w: CGFloat = 380
        let h: CGFloat = 480

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Chat History"
        win.level = .floating
        win.minSize = NSSize(width: 300, height: 300)
        win.backgroundColor = NSColor(red: 24/255, green: 20/255, blue: 37/255, alpha: 1)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        container.autoresizingMask = [.width, .height]

        // Scroll view with text view
        let sv = NSScrollView(frame: NSRect(x: 10, y: 50, width: w - 20, height: h - 60))
        sv.autoresizingMask = [.width, .height]
        sv.hasVerticalScroller = true
        sv.drawsBackground = true
        sv.backgroundColor = NSColor(red: 30/255, green: 26/255, blue: 43/255, alpha: 1)

        let tv = NSTextView(frame: sv.bounds)
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = NSColor(red: 30/255, green: 26/255, blue: 43/255, alpha: 1)
        tv.textColor = NSColor(red: 180/255, green: 180/255, blue: 200/255, alpha: 1)
        tv.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.autoresizingMask = [.width]
        tv.isVerticallyResizable = true
        tv.textContainer?.widthTracksTextView = true

        sv.documentView = tv
        container.addSubview(sv)
        scrollView = sv
        textView = tv

        // Input field at bottom
        let inputBg = NSView(frame: NSRect(x: 0, y: 0, width: w, height: 44))
        inputBg.wantsLayer = true
        inputBg.layer?.backgroundColor = NSColor(red: 40/255, green: 36/255, blue: 50/255, alpha: 1).cgColor
        inputBg.autoresizingMask = [.width]
        container.addSubview(inputBg)

        let field = NSTextField(frame: NSRect(x: 10, y: 10, width: w - 80, height: 24))
        field.placeholderString = "Send to Cardputer..."
        field.font = NSFont.systemFont(ofSize: 12)
        field.autoresizingMask = [.width]
        field.delegate = self
        container.addSubview(field)
        inputField = field

        let sendBtn = NSButton(frame: NSRect(x: w - 64, y: 8, width: 54, height: 28))
        sendBtn.isBordered = false
        sendBtn.attributedTitle = NSAttributedString(
            string: "Send",
            attributes: [.foregroundColor: NSColor.white,
                         .font: NSFont.systemFont(ofSize: 13, weight: .medium)]
        )
        sendBtn.wantsLayer = true
        sendBtn.layer?.backgroundColor = NSColor.black.cgColor
        sendBtn.layer?.cornerRadius = 4
        sendBtn.target = self
        sendBtn.action = #selector(sendButtonClicked)
        sendBtn.autoresizingMask = [.minXMargin]
        container.addSubview(sendBtn)

        win.contentView = container
        window = win

        // Center on screen
        if let screen = NSScreen.main {
            let x = screen.frame.maxX - w - 20
            let y = screen.visibleFrame.midY - h / 2
            win.setFrameOrigin(NSPoint(x: x, y: y))
        }

        updateTextView()
    }

    @objc private func sendButtonClicked() {
        sendCurrentInput()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            sendCurrentInput()
            return true
        }
        return false
    }

    private func sendCurrentInput() {
        guard let text = inputField?.stringValue, !text.isEmpty else { return }
        onSendMessage?(text)
        inputField?.stringValue = ""
    }

    private func updateTextView() {
        guard let tv = textView else { return }

        let attrStr = NSMutableAttributedString()
        let userColor = NSColor(red: 80/255, green: 120/255, blue: 200/255, alpha: 1)
        let aiColor = NSColor(red: 60/255, green: 160/255, blue: 80/255, alpha: 1)
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        for msg in messages {
            let prefix: String
            let color: NSColor
            if msg.role == "user" {
                prefix = "You: "
                color = userColor
            } else {
                prefix = "AI:  "
                color = aiColor
            }

            let line = NSAttributedString(string: prefix + msg.text + "\n",
                                          attributes: [.foregroundColor: color, .font: font])
            attrStr.append(line)
        }

        tv.textStorage?.setAttributedString(attrStr)

        // Auto-scroll to bottom
        if autoScroll {
            tv.scrollToEndOfDocument(nil)
        }
    }
}
