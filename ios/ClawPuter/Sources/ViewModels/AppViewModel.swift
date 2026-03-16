import Foundation
import Combine

class AppViewModel: ObservableObject {
    static let shared = AppViewModel()

    private let udpListener = UDPListener()
    private let udpSender = UDPSender.shared

    @Published var deviceState = DeviceState()
    @Published var chatMessages: [ChatMessage] = []
    @Published var connectedIP: String?
    @Published var isConnected: Bool = false
    @Published var inputText: String = ""
    @Published var notifyApp: String = ""
    @Published var notifyTitle: String = ""
    @Published var notifyBody: String = ""

    private init() { setupCallbacks() }

    func start() { udpListener.start() }
    func stop() { udpListener.stop() }

    private func setupCallbacks() {
        udpListener.onDeviceAddress = { [weak self] ip in
            self?.connectedIP = ip
            self?.isConnected = true
        }

        udpListener.onDeviceState = { [weak self] state, frame, mode, normX, normY, direction, weather, temp in
            self?.deviceState.update(state: state, frame: frame, mode: mode, normX: normX, normY: normY, direction: direction, weather: weather, temp: temp)
        }

        udpListener.onChatMessage = { [weak self] role, text in
            self?.chatMessages.append(ChatMessage(role: role, text: text))
        }
    }

    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let message = inputText
        chatMessages.append(ChatMessage(role: "user", text: message))
        udpSender.sendText(text: message, autoSend: true)
        inputText = ""
    }

    func sendNotification() {
        guard !notifyApp.isEmpty && !notifyTitle.isEmpty && !notifyBody.isEmpty else { return }
        udpSender.sendNotification(app: notifyApp, title: notifyTitle, body: notifyBody)
        notifyApp = ""; notifyTitle = ""; notifyBody = ""
    }

    func triggerHappy() { udpSender.sendAnimate(state: "happy") }
    func triggerSleep() { udpSender.sendAnimate(state: "sleep") }
    func clearMessages() { chatMessages.removeAll() }
}
