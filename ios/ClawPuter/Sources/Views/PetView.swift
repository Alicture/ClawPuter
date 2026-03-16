import SwiftUI
import CoreGraphics

// Weather particle model - defined at top level
struct WeatherParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var drift: CGFloat
    var length: CGFloat
}

struct PetView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var currentFrame = 0
    @State private var timer: Timer?
    @State private var normX: Float = 0.5
    @State private var facingLeft: Bool = false
    @State private var spriteNormX: CGFloat = 0.5

    // Scene mode state
    @State private var sceneMode: Bool = true  // Default to scene mode
    @State private var stars: [Bool] = Array(repeating: true, count: 12)
    @State private var lastStarToggle: Date = Date()
    @State private var particles: [WeatherParticle] = []
    @State private var lastWeatherType: Int = -1
    @State private var fogOffset: Int = 0
    @State private var lastFogUpdate: Date = Date()
    @State private var thunderFlash: Bool = false
    @State private var lastFlashTime: Date = Date()
    @State private var nextFlashInterval: TimeInterval = 4.0

    private let frameDuration: Double = 200
    private let groundHeight: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let scale = Int(size / 16)
            let spriteSize = CGFloat(scale * 16)
            let sceneWidth = geometry.size.width
            let sceneHeight = geometry.size.height

            // Compute offset from state
            let maxOffset = max(0, sceneWidth - spriteSize)
            let horizontalOffset = CGFloat(normX) * maxOffset

            ZStack {
                // Background with weather/scene
                if sceneMode {
                    SceneBackground(
                        weatherType: viewModel.deviceState.weatherType,
                        hour: displayHour,
                        stars: $stars,
                        particles: $particles,
                        fogOffset: $fogOffset,
                        thunderFlash: $thunderFlash,
                        lastStarToggle: $lastStarToggle,
                        lastFogUpdate: $lastFogUpdate,
                        lastFlashTime: $lastFlashTime,
                        nextFlashInterval: $nextFlashInterval,
                        sceneWidth: sceneWidth,
                        sceneHeight: sceneHeight,
                        groundHeight: groundHeight
                    )
                } else {
                    weatherBackground
                }

                // Sprite with position offset based on normX
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
                .offset(y: sceneMode ? -(groundHeight + 2) : 0)

                // Accessories based on weather
                if sceneMode {
                    WeatherAccessories(
                        weatherType: viewModel.deviceState.weatherType,
                        spriteOrigin: CGPoint(x: horizontalOffset, y: groundHeight + 2),
                        spriteSize: spriteSize,
                        scale: scale
                    )
                }

                // Sleep Z animation
                if viewModel.deviceState.state == .sleep && sceneMode {
                    SleepZAnimation(scale: scale, spriteOrigin: CGPoint(x: horizontalOffset, y: groundHeight + 2))
                }

                // Clock in scene mode
                if sceneMode {
                    ClockDisplay(temperature: viewModel.deviceState.temperature)
                        .offset(y: -groundHeight / 2 + 8)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { startAnimation() }
        .onDisappear { stopAnimation() }
        .onChange(of: viewModel.deviceState.frame) { _ in
            currentFrame = viewModel.deviceState.frame
        }
        .onChange(of: viewModel.deviceState.normX) { newValue in
            normX = newValue
            spriteNormX = CGFloat(newValue)
        }
        .onChange(of: viewModel.deviceState.direction) { newValue in
            facingLeft = newValue == 1
        }
        .onChange(of: viewModel.deviceState.weatherType) { newValue in
            if newValue != lastWeatherType {
                lastWeatherType = newValue
                particles.removeAll()
            }
        }
    }

    private var displayHour: Int {
        let baseHour = Calendar.current.component(.hour, from: Date())
        if sceneMode {
            // Time-travel: sprite position offsets the hour (-12 to +12)
            let offset = Int(spriteNormX * 24) - 12
            return (baseHour + offset + 24) % 24
        }
        return baseHour
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

// MARK: - Scene Background

struct SceneBackground: View {
    let weatherType: Int
    let hour: Int
    @Binding var stars: [Bool]
    @Binding var particles: [WeatherParticle]
    @Binding var fogOffset: Int
    @Binding var thunderFlash: Bool
    @Binding var lastStarToggle: Date
    @Binding var lastFogUpdate: Date
    @Binding var lastFlashTime: Date
    @Binding var nextFlashInterval: TimeInterval
    let sceneWidth: CGFloat
    let sceneHeight: CGFloat
    let groundHeight: CGFloat

    var body: some View {
        ZStack {
            // Sky
            skyColor

            // Celestials (hidden in heavy weather)
            if weatherType < 2 {
                CelestialsView(hour: hour, stars: $stars, lastStarToggle: $lastStarToggle)
            }

            // Weather particles
            if weatherType >= 3 {
                WeatherParticlesView(
                    weatherType: weatherType,
                    particles: $particles,
                    fogOffset: $fogOffset,
                    lastFogUpdate: $lastFogUpdate,
                    sceneWidth: sceneWidth,
                    sceneHeight: sceneHeight,
                    groundHeight: groundHeight
                )
            }

            // Ground
            GroundView(hour: hour, groundHeight: groundHeight)

            // Thunder flash
            if weatherType == 7 && thunderFlash {
                Color(red: 0.78, green: 0.78, blue: 0.78)
            }
        }
        .cornerRadius(16)
        .onAppear {
            updateThunderFlash()
        }
    }

    private var skyColor: Color {
        let baseColor = skyBaseColor
        if weatherType >= 2 {
            return weatherTint.opacity(weatherBlendFactor)
        }
        return baseColor
    }

    private var skyBaseColor: Color {
        if hour >= 6 && hour < 17 {
            return Color(red: 60/255, green: 120/255, blue: 200/255)
        } else if hour >= 17 && hour < 19 {
            return Color(red: 180/255, green: 80/255, blue: 60/255)
        } else {
            return Color(red: 10/255, green: 10/255, blue: 30/255)
        }
    }

    private var weatherTint: Color {
        switch weatherType {
        case 2: return Color(red: 100/255, green: 100/255, blue: 110/255)
        case 3: return Color(red: 140/255, green: 140/255, blue: 145/255)
        case 4: return Color(red: 90/255, green: 90/255, blue: 105/255)
        case 5: return Color(red: 60/255, green: 60/255, blue: 75/255)
        case 6: return Color(red: 120/255, green: 120/255, blue: 135/255)
        case 7: return Color(red: 60/255, green: 60/255, blue: 75/255)
        default: return .black
        }
    }

    private var weatherBlendFactor: Double {
        switch weatherType {
        case 2: return 0.63
        case 3: return 0.67
        case 4: return 0.55
        case 5: return 0.71
        case 6: return 0.59
        case 7: return 0.71
        default: return 0
        }
    }

    private func updateThunderFlash() {
        if weatherType == 7 {
            let now = Date()
            if now.timeIntervalSince(lastFlashTime) > nextFlashInterval {
                thunderFlash = true
                lastFlashTime = now
                nextFlashInterval = Double.random(in: 3...5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    thunderFlash = false
                }
            }
        }
    }
}

// MARK: - Celestials (Sun/Moon/Stars/Clouds)

struct CelestialsView: View {
    let hour: Int
    @Binding var stars: [Bool]
    @Binding var lastStarToggle: Date

    var body: some View {
        ZStack {
            if hour >= 6 && hour < 17 {
                // Sun
                SunView()
                CloudView()
            } else if hour >= 17 && hour < 19 {
                // Sunset
                SunsetView()
            } else {
                // Moon and stars
                MoonView()
                StarsView(stars: $stars, lastStarToggle: $lastStarToggle)
            }
        }
    }
}

struct SunView: View {
    var body: some View {
        ZStack {
            // Sun rays
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi / 4
                Rectangle()
                    .fill(Color(red: 1, green: 220/255, blue: 60/255))
                    .frame(width: 2, height: 6)
                    .offset(x: cos(angle) * 18, y: sin(angle) * 18)
            }
            // Sun circle
            Circle()
                .fill(Color(red: 1, green: 220/255, blue: 60/255))
                .frame(width: 24, height: 24)
        }
        .position(x: 300, y: 185)
    }
}

struct SunsetView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 230/255, green: 120/255, blue: 50/255))
                .frame(width: 24, height: 24)
            Circle()
                .fill(Color(red: 1, green: 220/255, blue: 60/255))
                .frame(width: 30, height: 30)
        }
        .position(x: 300, y: 43)
    }
}

struct MoonView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 220/255, green: 220/255, blue: 200/255))
                .frame(width: 24, height: 24)
            Circle()
                .fill(Color(red: 10/255, green: 10/255, blue: 30/255))
                .frame(width: 20, height: 20)
                .offset(x: 5, y: 0)
        }
        .position(x: 45, y: 185)
    }
}

struct StarsView: View {
    @Binding var stars: [Bool]
    @Binding var lastStarToggle: Date

    private let positions: [(CGFloat, CGFloat)] = [
        (80, 180), (150, 190), (220, 175), (290, 188),
        (40, 160), (120, 170), (200, 165), (330, 170),
        (70, 145), (180, 150), (260, 155), (310, 148)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<positions.count, id: \.self) { i in
                if stars[i] {
                    if i % 3 == 0 {
                        // Cross star
                        Rectangle()
                            .fill(Color(red: 200/255, green: 200/255, blue: 140/255))
                            .frame(width: 2, height: 6)
                            .offset(x: positions[i].0, y: positions[i].1 - 3)
                        Rectangle()
                            .fill(Color(red: 200/255, green: 200/255, blue: 140/255))
                            .frame(width: 6, height: 2)
                            .offset(x: positions[i].0, y: positions[i].1)
                    } else {
                        Rectangle()
                            .fill(Color(red: 200/255, green: 200/255, blue: 140/255))
                            .frame(width: 2, height: 2)
                            .offset(x: positions[i].0, y: positions[i].1)
                    }
                }
            }
        }
        .onAppear {
            toggleStars()
        }
    }

    private func toggleStars() {
        let now = Date()
        if now.timeIntervalSince(lastStarToggle) > 0.8 {
            lastStarToggle = now
            for i in stars.indices {
                stars[i] = Bool.random()
            }
        }
    }
}

struct CloudView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(red: 220/255, green: 230/255, blue: 240/255))
                .frame(width: 50, height: 14)
                .offset(x: -35, y: 0)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 220/255, green: 230/255, blue: 240/255))
                .frame(width: 30, height: 10)
                .offset(x: -15, y: 8)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 220/255, green: 230/255, blue: 240/255))
                .frame(width: 45, height: 12)
                .offset(x: 115, y: 10)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 220/255, green: 230/255, blue: 240/255))
                .frame(width: 28, height: 10)
                .offset(x: 130, y: 16)
        }
        .position(x: 187, y: 180)
    }
}

// MARK: - Weather Particles

struct WeatherParticlesView: View {
    let weatherType: Int
    @Binding var particles: [WeatherParticle]
    @Binding var fogOffset: Int
    @Binding var lastFogUpdate: Date
    let sceneWidth: CGFloat
    let sceneHeight: CGFloat
    let groundHeight: CGFloat

    var body: some View {
        ZStack {
            if weatherType == 3 {
                // Fog
                FogView(fogOffset: fogOffset, groundHeight: groundHeight, sceneHeight: sceneHeight)
            } else if weatherType == 6 {
                // Rain drops
                ForEach(particles) { particle in
                    Rectangle()
                        .fill(Color(red: 220/255, green: 220/255, blue: 230/255))
                        .frame(width: 2, height: 2)
                        .position(x: particle.x, y: particle.y)
                }
            } else {
                // Rain or snow
                ForEach(particles) { particle in
                    Rectangle()
                        .fill(Color(red: 140/255, green: 160/255, blue: 200/255))
                        .frame(width: 1, height: particle.length)
                        .position(x: particle.x, y: particle.y)
                }
            }
        }
        .onAppear {
            initParticles()
            startParticleTimer()
        }
        .onChange(of: weatherType) { _ in
            initParticles()
        }
    }

    private func initParticles() {
        if !particles.isEmpty && lastWeatherType() == weatherType { return }

        let w = sceneWidth
        let h = sceneHeight

        switch weatherType {
        case 4: // Snow
            particles = (0..<12).map { _ in
                WeatherParticle(
                    x: CGFloat.random(in: 0...w),
                    y: CGFloat.random(in: groundHeight...h),
                    speed: 4,
                    drift: 0,
                    length: 8
                )
            }
        case 5, 7: // Heavy snow or thunderstorm
            particles = (0..<20).map { _ in
                WeatherParticle(
                    x: CGFloat.random(in: 0...w),
                    y: CGFloat.random(in: groundHeight...h),
                    speed: 7,
                    drift: 0,
                    length: 14
                )
            }
        case 6: // Rain
            particles = (0..<20).map { _ in
                WeatherParticle(
                    x: CGFloat.random(in: 0...w),
                    y: CGFloat.random(in: groundHeight...h),
                    speed: 1.5,
                    drift: CGFloat([-1.0, 0, 1.0].randomElement()!),
                    length: 3
                )
            }
        default: break
        }
    }

    private func lastWeatherType() -> Int {
        return weatherType
    }

    private func startParticleTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].y -= particles[i].speed
                particles[i].x += particles[i].drift

                if particles[i].y < groundHeight {
                    particles[i].y = sceneHeight + CGFloat.random(in: 0...20)
                    particles[i].x = CGFloat.random(in: 0...sceneWidth)
                    if weatherType == 6 {
                        particles[i].drift = CGFloat([-1.0, 0, 1.0].randomElement()!)
                    }
                }
            }
        }
    }
}

struct FogView: View {
    let fogOffset: Int
    let groundHeight: CGFloat
    let sceneHeight: CGFloat

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 6
            let fogColor = Color(red: 180/255, green: 180/255, blue: 190/255).opacity(0.6)

            var y = groundHeight
            var row = 0
            while y < sceneHeight {
                var x = CGFloat((row + fogOffset) % Int(spacing))
                while x < size.width {
                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(fogColor))
                    x += spacing
                }
                y += spacing
                row += 1
            }
        }
    }
}

// MARK: - Ground

struct GroundView: View {
    let hour: Int
    let groundHeight: CGFloat

    var body: some View {
        VStack {
            Spacer()
            ZStack(alignment: .bottom) {
                // Main ground
                Rectangle()
                    .fill(groundColor)
                    .frame(height: groundHeight)

                // Top highlight
                Rectangle()
                    .fill(Color(red: 100/255, green: 170/255, blue: 70/255))
                    .frame(height: 2)
                    .offset(y: -groundHeight + 2)

                // Grass tufts
                HStack(spacing: 0) {
                    ForEach([20, 65, 110, 155, 205, 250, 295, 335], id: \.self) { gx in
                        Rectangle()
                            .fill(Color(red: 60/255, green: 130/255, blue: 50/255))
                            .frame(width: 2, height: 3)
                        Rectangle()
                            .fill(Color(red: 60/255, green: 130/255, blue: 50/255))
                            .frame(width: 2, height: 2)
                            .offset(x: -2)
                        Rectangle()
                            .fill(Color(red: 60/255, green: 130/255, blue: 50/255))
                            .frame(width: 2, height: 2)
                            .offset(x: 2)
                        Spacer()
                            .frame(width: gx > 295 ? 0 : gx == 295 ? 5 : 0)
                    }
                }
                .offset(y: -groundHeight)
            }
        }
    }

    private var groundColor: Color {
        if hour >= 6 && hour < 19 {
            return Color(red: 80/255, green: 140/255, blue: 60/255)
        } else {
            return Color(red: 50/255, green: 100/255, blue: 40/255)
        }
    }
}

// MARK: - Clock

struct ClockDisplay: View {
    let temperature: Float

    private var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: Date())
        if temperature > -999 {
            return "\(timeStr) | \(Int(roundf(temperature)))°"
        }
        return timeStr
    }

    var body: some View {
        Text(displayText)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(Color(red: 180/255, green: 180/255, blue: 200/255))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
    }
}

// MARK: - Weather Accessories

struct WeatherAccessories: View {
    let weatherType: Int
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat
    let scale: Int

    var body: some View {
        ZStack {
            switch weatherType {
            case 0, 1: // Sunglasses
                SunglassesView(spriteOrigin: spriteOrigin, spriteSize: spriteSize, scale: scale)
            case 4, 5, 7: // Umbrella
                UmbrellaView(spriteOrigin: spriteOrigin, spriteSize: spriteSize, scale: scale)
            case 6: // Snow hat
                SnowHatView(spriteOrigin: spriteOrigin, spriteSize: spriteSize, scale: scale)
            case 2, 3: // Mask
                MaskView(spriteOrigin: spriteOrigin, spriteSize: spriteSize, scale: scale)
            default:
                EmptyView()
            }
        }
    }
}

struct SunglassesView: View {
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat
    let scale: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 20/255, green: 20/255, blue: 40/255))
                .frame(width: 24, height: 8)
                .offset(x: spriteOrigin.x + 32 * 8 / CGFloat(scale), y: -(spriteSize - 48))
            Rectangle()
                .fill(Color(red: 20/255, green: 20/255, blue: 40/255))
                .frame(width: 24, height: 8)
                .offset(x: spriteOrigin.x + 72 * 8 / CGFloat(scale), y: -(spriteSize - 48))
            Rectangle()
                .fill(Color(red: 20/255, green: 20/255, blue: 40/255))
                .frame(width: 16, height: 3)
                .offset(x: spriteOrigin.x + 56 * 8 / CGFloat(scale), y: -(spriteSize - 46))
        }
    }
}

struct UmbrellaView: View {
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat
    let scale: Int

    var body: some View {
        ZStack {
            // Umbrella top
            RoundedRectangle(cornerRadius: 11)
                .fill(Color(red: 60/255, green: 60/255, blue: 200/255))
                .frame(width: 96, height: 21)
                .offset(x: spriteOrigin.x + 16 * 8 / CGFloat(scale), y: -(spriteSize + 6))
            // Handle
            Rectangle()
                .fill(Color(red: 120/255, green: 80/255, blue: 40/255))
                .frame(width: 4, height: 22)
                .offset(x: spriteOrigin.x + 62 * 8 / CGFloat(scale), y: -(spriteSize - 16))
        }
    }
}

struct SnowHatView: View {
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat
    let scale: Int

    var body: some View {
        ZStack {
            // Hat base
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 200/255, green: 60/255, blue: 60/255))
                .frame(width: 80, height: 16)
                .offset(x: spriteOrigin.x + 24 * 8 / CGFloat(scale), y: -(spriteSize - 24))
            // Pom pom
            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)
                .offset(x: spriteOrigin.x + 56 * 8 / CGFloat(scale), y: -(spriteSize))
        }
    }
}

struct MaskView: View {
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat
    let scale: Int

    var body: some View {
        ZStack {
            // Mask
            Rectangle()
                .fill(Color(red: 180/255, green: 200/255, blue: 180/255))
                .frame(width: 64, height: 16)
                .offset(x: spriteOrigin.x + 32 * 8 / CGFloat(scale), y: -(spriteSize - 72))
            // Straps
            Rectangle()
                .fill(Color(red: 120/255, green: 120/255, blue: 120/255))
                .frame(width: 8, height: 3)
                .offset(x: spriteOrigin.x + 24 * 8 / CGFloat(scale), y: -(spriteSize - 64))
            Rectangle()
                .fill(Color(red: 120/255, green: 120/255, blue: 120/255))
                .frame(width: 8, height: 3)
                .offset(x: spriteOrigin.x + 96 * 8 / CGFloat(scale), y: -(spriteSize - 64))
        }
    }
}

// MARK: - Sleep Z Animation

struct SleepZAnimation: View {
    let scale: Int
    let spriteOrigin: CGPoint

    @State private var phase: Int = 0

    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if phase >= 1 {
                Text("z")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: spriteOrigin.x + 106 * 16 / CGFloat(scale), y: -(spriteOrigin.y + 68 * 16 / CGFloat(scale)))
            }
            if phase >= 2 {
                Text("Z")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: spriteOrigin.x + 118 * 16 / CGFloat(scale), y: -(spriteOrigin.y + 96 * 16 / CGFloat(scale)))
            }
            if phase >= 3 {
                Text("Z")
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: spriteOrigin.x + 112 * 16 / CGFloat(scale), y: -(spriteOrigin.y + 132 * 16 / CGFloat(scale)))
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 4
        }
    }
}
