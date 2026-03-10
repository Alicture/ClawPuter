import Foundation

/// Sends commands to the ESP32 Cardputer via UDP (port 19822).
/// UDP avoids macOS local network TCP restrictions on unsigned executables.
/// Fire-and-forget with optional response wait.
class TCPSender {
    static let port: UInt16 = 19822
    private static let recvTimeout: TimeInterval = 2.0

    /// Send a command to the ESP32 at the given address.
    /// Returns the response string, or nil on failure/timeout.
    @discardableResult
    static func send(to address: String, json: String) -> String? {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else {
            print("[CMD] Failed to create socket: \(String(cString: strerror(errno)))")
            return nil
        }
        defer { Darwin.close(fd) }

        // Receive timeout for response
        var tv = timeval(tv_sec: Int(recvTimeout), tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        // Target address
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian

        guard inet_pton(AF_INET, address, &addr.sin_addr) == 1 else {
            print("[CMD] Invalid address: \(address)")
            return nil
        }

        // Send JSON + newline via UDP
        guard let payload = (json + "\n").data(using: .utf8) else { return nil }

        let sent = payload.withUnsafeBytes { rawPtr in
            withUnsafePointer(to: &addr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    sendto(fd, rawPtr.baseAddress, payload.count, 0,
                           sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        guard sent > 0 else {
            print("[CMD] sendto \(address):\(port) failed: \(String(cString: strerror(errno)))")
            return nil
        }

        print("[CMD] Sent \(sent) bytes to \(address):\(port)")

        // Wait for response
        var buf = [UInt8](repeating: 0, count: 1024)
        let n = recv(fd, &buf, buf.count, 0)
        if n > 0 {
            let response = String(bytes: buf[0..<n], encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            print("[CMD] Response: \(response ?? "(nil)")")
            return response
        }

        return nil
    }

    // ── JSON Helpers ──

    private static func jsonEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\n", with: "\\n")
         .replacingOccurrences(of: "\r", with: "\\r")
         .replacingOccurrences(of: "\t", with: "\\t")
    }

    // ── Convenience methods ──

    static func triggerAnimate(address: String, state: String) {
        send(to: address, json: "{\"cmd\":\"animate\",\"state\":\"\(jsonEscape(state))\"}")
    }

    static func sendText(address: String, text: String, autoSend: Bool = false) {
        let cmd = autoSend ? "say" : "text"
        send(to: address, json: "{\"cmd\":\"\(cmd)\",\"msg\":\"\(jsonEscape(text))\"}")
    }

    static func sendNotification(address: String, app: String, title: String, body: String) {
        send(to: address, json: "{\"cmd\":\"notify\",\"app\":\"\(jsonEscape(app))\",\"title\":\"\(jsonEscape(title))\",\"body\":\"\(jsonEscape(body))\"}")
    }

    static func requestHistory(address: String) -> String? {
        return send(to: address, json: "{\"cmd\":\"history\"}")
    }
}
