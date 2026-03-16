import Foundation

class UDPSender {
    static let shared = UDPSender()

    private let sendPort: UInt16 = 19822
    private var deviceAddress: String?
    private var socket: Int32 = -1

    private init() {
        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        if socket < 0 {
            print("[UDP] Failed to create send socket")
        }
    }

    func setDeviceAddress(_ address: String) {
        deviceAddress = address
        print("[UDP] Device address set to: \(address)")
    }

    func send(json: String) {
        guard let address = deviceAddress else {
            print("[UDP] No device address set")
            return
        }

        guard socket >= 0 else {
            print("[UDP] Invalid socket")
            return
        }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = sendPort.bigEndian

        inet_pton(AF_INET, address, &addr.sin_addr)

        // Add newline at end as expected by ESP32
        let jsonWithNewline = json + "\n"
        let data = jsonWithNewline.data(using: .utf8)!

        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                data.withUnsafeBytes { dataPtr in
                    sendto(socket, dataPtr.baseAddress, data.count, 0, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        if result < 0 {
            print("[UDP] Send failed: \(String(cString: strerror(errno)))")
        } else {
            print("[UDP] Sent: \(json)")
        }
    }

    // MARK: - Commands

    func sendAnimate(state: String) {
        let json = "{\"cmd\":\"animate\",\"state\":\"\(escapeJSON(state))\"}"
        send(json: json)
    }

    func sendText(text: String, autoSend: Bool = false) {
        let cmd = autoSend ? "say" : "text"
        let json = "{\"cmd\":\"\(cmd)\",\"msg\":\"\(escapeJSON(text))\"}"
        send(json: json)
    }

    func sendNotification(app: String, title: String, body: String) {
        let json = "{\"cmd\":\"notify\",\"app\":\"\(escapeJSON(app))\",\"title\":\"\(escapeJSON(title))\",\"body\":\"\(escapeJSON(body))\"}"
        send(json: json)
    }

    func requestHistory() {
        let json = "{\"cmd\":\"history\"}"
        send(json: json)
    }

    private func escapeJSON(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    deinit {
        if socket >= 0 {
            close(socket)
        }
    }
}
