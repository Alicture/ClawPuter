import Foundation

enum PetState: String, Codable {
    case idle, happy, sleep, working, chilling
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String
    let text: String
    let timestamp: Date

    init(role: String, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.timestamp = Date()
    }
}

struct DeviceState {
    var state: PetState = .idle
    var frame: Int = 0
    var mode: String = "home"
    var normX: Float = 0.5
    var normY: Float = 0.5
    var direction: Int = 0
    var weatherType: Int = -1
    var temperature: Float = -999

    mutating func update(state: Int, frame: Int, mode: String, normX: Float, normY: Float, direction: Int, weather: Int, temp: Float) {
        let states = ["idle", "happy", "sleep", "working", "chilling"]
        self.state = (state >= 0 && state < states.count) ? PetState(rawValue: states[state]) ?? .idle : .idle
        self.frame = frame
        self.mode = mode
        self.normX = normX
        self.normY = normY
        self.direction = direction
        self.weatherType = weather
        self.temperature = temp
    }
}
