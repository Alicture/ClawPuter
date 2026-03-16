import SwiftUI

struct PetView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var currentFrame = 0
    @State private var timer: Timer?
    private let frameDuration: Double = 200

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let scale = Int(size / 16)
            let spriteSize = CGFloat(scale * 16)

            ZStack {
                // Background with weather
                weatherBackground

                // Sprite with position offset based on normX
                let maxOffset = geometry.size.width - spriteSize
                let horizontalOffset = CGFloat(viewModel.deviceState.normX) * maxOffset

                HStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: horizontalOffset)
                    if let cgImage = SpriteRenderer.render(sprite: currentSprite, scale: scale) {
                        Image(decorative: cgImage, scale: 1.0)
                            .interpolation(.none)
                    }
                    Spacer()
                }

                // Info overlay
                VStack {
                    HStack {
                        // Connection status
                        if viewModel.isConnected {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }

                        Text(viewModel.deviceState.state.rawValue.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)

                        if viewModel.deviceState.weatherType >= 0 {
                            Text(weatherIcon)
                                .font(.system(size: 12))
                        }

                        if viewModel.deviceState.temperature > -999 {
                            Text("\(Int(viewModel.deviceState.temperature))°C")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    Spacer()
                    if let ip = viewModel.connectedIP {
                        Text(ip)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(8)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(16)
        .onAppear { startAnimation() }
        .onDisappear { stopAnimation() }
        .onChange(of: viewModel.deviceState.frame) { _ in
            currentFrame = viewModel.deviceState.frame
        }
    }

    private var weatherBackground: some View {
        Group {
            switch viewModel.deviceState.weatherType {
            case 0: LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
            case 1: LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
            case 2: LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .top, endPoint: .bottom)
            case 3: LinearGradient(colors: [.gray, .blue], startPoint: .top, endPoint: .bottom)
            case 4,5: LinearGradient(colors: [.gray.opacity(0.8), .white], startPoint: .top, endPoint: .bottom)
            case 6,7: LinearGradient(colors: [.purple, .gray], startPoint: .top, endPoint: .bottom)
            default: LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    private var weatherIcon: String {
        switch viewModel.deviceState.weatherType {
        case 0: return "☀️"
        case 1: return "⛅"
        case 2: return "☁️"
        case 3: return "🌧️"
        case 4: return "🌨️"
        case 5: return "❄️"
        case 6: return "⛈️"
        case 7: return "🌩️"
        default: return ""
        }
    }

    private var currentSprite: [UInt16] {
        let frames: [[UInt16]]
        switch viewModel.deviceState.state {
        case .happy: frames = SpriteFrames.happy
        case .sleep: frames = SpriteFrames.sleep
        default: frames = SpriteFrames.idle
        }
        return frames[currentFrame % frames.count]
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: frameDuration / 1000.0, repeats: true) { _ in
            currentFrame += 1
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}
