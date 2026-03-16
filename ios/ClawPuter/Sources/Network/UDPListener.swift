import Foundation

class UDPListener {
    private let receivePort: UInt16 = 19820
    private var socket: Int32 = -1
    private var isRunning = false

    var onDeviceState: ((Int, Int, String, Float, Float, Int, Int, Float) -> Void)?
    var onChatMessage: ((String, String) -> Void)?
    var onPixelArt: ((Int, [String]) -> Void)?
    var onDeviceAddress: ((String) -> Void)?

    init() {}

    func start() {
        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket >= 0 else { return }

        var reuse: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = receivePort.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(socket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else { close(socket); socket = -1; return }

        isRunning = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.receiveLoop()
        }
    }

    func stop() {
        isRunning = false
        if socket >= 0 { close(socket); socket = -1 }
    }

    private func receiveLoop() {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var senderAddr = sockaddr_in()
        var senderAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        while isRunning {
            let bytesRead = withUnsafeMutablePointer(to: &senderAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    recvfrom(socket, &buffer, buffer.count, 0, sockaddrPtr, &senderAddrLen)
                }
            }

            guard bytesRead > 0 else { continue }

            let data = Data(buffer[0..<bytesRead])
            guard let jsonString = String(data: data, encoding: .utf8) else { continue }

            var senderIP = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &senderAddr.sin_addr, &senderIP, socklen_t(INET_ADDRSTRLEN))
            let ipString = String(cString: senderIP)

            DispatchQueue.main.async { [weak self] in
                self?.handlePacket(jsonString, from: ipString)
            }
        }
    }

    private func handlePacket(_ json: String, from ip: String) {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let type = dict["type"] as? String {
            switch type {
            case "chat":
                if let role = dict["role"] as? String, let text = dict["text"] as? String {
                    onChatMessage?(role, text)
                }
            case "pixelart":
                if let size = dict["size"] as? Int, let rows = dict["rows"] as? [String] {
                    onPixelArt?(size, rows)
                }
            default: break
            }
            return
        }

        // Legacy: {"s":state,"f":frame,"m":"mode","x":normX,"y":normY,"d":direction,"w":weather,"t":temp}
        if let state = dict["s"] as? Int,
           let frame = dict["f"] as? Int,
           let mode = dict["m"] as? String {

            let normX = dict["x"] as? Float ?? 0.5
            let normY = dict["y"] as? Float ?? 0.5
            let direction = dict["d"] as? Int ?? 0
            let weather = dict["w"] as? Int ?? -1
            let temperature = dict["t"] as? Float ?? -999

            UDPSender.shared.setDeviceAddress(ip)
            onDeviceAddress?(ip)
            onDeviceState?(state, frame, mode, normX, normY, direction, weather, temperature)
        }
    }

    deinit { stop() }
}
