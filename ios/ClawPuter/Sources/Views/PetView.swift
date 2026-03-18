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
    var width: CGFloat = 1
}

// Interaction particle model for effects like hearts, stars, bubbles
struct InteractionParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var velocityY: CGFloat
    var velocityX: CGFloat
}

// Pet animation states
enum PetAnimationState: String, CaseIterable {
    case idle
    case walk
    case happy
    case excited
    case eat
    case play
    case wave
    case sleep
    case talk
}

// Dust particle model for walking effects
struct DustParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
    var lifetime: Double
}

struct PetView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var currentFrame = 0
    @State private var timer: Timer?
    @State private var normX: Float = 0.5
    @State private var normY: Float = 0.5
    @State private var facingLeft: Bool = false
    @State private var spriteNormX: CGFloat = 0.5
    @State private var spriteNormY: CGFloat = 0.5

    // Movement system state
    @State private var isMoving: Bool = false
    @State private var targetNormX: Float = 0.5
    @State private var targetNormY: Float = 0.5
    @State private var dustParticles: [DustParticle] = []
    @State private var shadowOpacity: Double = 0.3
    @State private var movementTimer: Timer?
    @State private var dustTimer: Timer?
    @State private var lastDustTime: Date = Date()

    // Scene mode state
    @State private var sceneMode: Bool = true  // Default to scene mode
    @State private var stars: [Bool] = Array(repeating: true, count: 16)
    @State private var lastStarToggle: Date = Date()
    @State private var particles: [WeatherParticle] = []
    @State private var lastWeatherType: Int = -1
    @State private var fogOffset: Int = 0
    @State private var lastFogUpdate: Date = Date()
    @State private var thunderFlash: Bool = false
    @State private var lastFlashTime: Date = Date()
    @State private var nextFlashInterval: TimeInterval = 4.0

    // Interaction particles (hearts, stars, bubbles)
    @State private var interactionParticles: [InteractionParticle] = []
    @State private var interactionTimer: Timer?
    @State private var currentInteractionType: InteractionType = .none

    private let frameDuration: Double = 200
    private let groundHeight: CGFloat = 28
    @State private var sceneWidth: CGFloat = 0
    @State private var sceneHeight: CGFloat = 0

    // Transition animation state
    @State private var isTransitioning: Bool = false
    @State private var transitionProgress: CGFloat = 0
    @State private var previousState: PetAnimationState = .idle
    @State private var currentState: PetAnimationState = .idle

    var body: some View {
        GeometryReader { geometry in
            let sceneW = geometry.size.width
            let sceneH = geometry.size.height

            // Pet size - use larger portion of height
            let spriteSize: CGFloat = min(sceneH * 0.5, 150)
            let scale = Int(spriteSize / 16)

            // Compute offset from state
            let maxOffsetX = max(0, sceneW - spriteSize - 20)
            let horizontalOffset = CGFloat(normX) * maxOffsetX + 10
            // Vertical offset (normY: 0=top, 1=bottom)
            let maxOffsetY = sceneH * 0.3  // Can move up to 30% of height
            let verticalOffset = CGFloat(normY) * maxOffsetY

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

                // Pet shadow (ellipse on ground)
                Ellipse()
                    .fill(Color.black.opacity(sceneMode ? shadowOpacity : 0))
                    .frame(width: spriteSize * 0.8, height: spriteSize * 0.2)
                    .offset(x: horizontalOffset - sceneW/2 + spriteSize/2, y: sceneMode ? (groundHeight + 4 + verticalOffset) : 0)

                // Dust particles when walking
                DustParticleEmitter(particles: dustParticles, spriteSize: spriteSize, horizontalOffset: horizontalOffset, verticalOffset: verticalOffset, groundHeight: groundHeight, sceneMode: sceneMode)

                // Sprite with position offset based on normX and normY
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
                .offset(y: sceneMode ? (groundHeight + 2 + verticalOffset + bounceOffset) : 0)
                .scaleEffect(x: facingLeft ? -1 : 1, y: 1)

                // Interaction particle effects
                if currentInteractionType != .none {
                    InteractionParticleEmitter(
                        particles: interactionParticles,
                        particleType: currentInteractionType,
                        spriteOrigin: CGPoint(x: horizontalOffset, y: groundHeight + 2),
                        spriteSize: spriteSize
                    )
                }

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
                    SleepZAnimation(scale: scale, spriteOrigin: CGPoint(x: horizontalOffset, y: groundHeight + 2), spriteSize: spriteSize)
                }

                // Info overlay at top with safe area
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
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(
                    LinearGradient(colors: [.black.opacity(0.5), .clear],
                                   startPoint: .top, endPoint: .bottom)
                )

                // Clock at bottom center
                if sceneMode {
                    VStack {
                        Spacer()
                        ClockDisplay(temperature: viewModel.deviceState.temperature)
                            .padding(.bottom, groundHeight + 20)
                    }
                }
            }
            .gesture(
                // Tap gesture for tap-to-move
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Calculate normX from drag position
                        let newNormX = Float(value.location.x / sceneW)
                        normX = max(0, min(1, newNormX))
                        spriteNormX = CGFloat(normX)
                        // Calculate normY from drag position (inverted: top=1, bottom=0)
                        let newNormY = Float(1.0 - value.location.y / sceneH)
                        normY = max(0, min(1, newNormY))
                        spriteNormY = CGFloat(normY)
                        // Update direction based on movement
                        if value.translation.width < -5 {
                            facingLeft = true
                        } else if value.translation.width > 5 {
                            facingLeft = false
                        }
                        // Mark as moving during drag
                        if !isMoving {
                            isMoving = true
                            spawnDustParticles(sceneW: sceneW, sceneH: sceneH)
                        }
                    }
                    .onEnded { _ in
                        // Stop moving after drag ends
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.isMoving = false
                        }
                    }
            )
        }
        .clipped()
        .onAppear { startAnimation() }
        .onDisappear {
            stopAnimation()
            interactionParticles.removeAll()
        }
        .onChange(of: viewModel.deviceState.frame) { _ in
            currentFrame = viewModel.deviceState.frame
        }
        .onChange(of: viewModel.deviceState.normX) { newValue in
            normX = newValue
            spriteNormX = CGFloat(newValue)
        }
        .onChange(of: viewModel.deviceState.normY) { newValue in
            normY = newValue
            spriteNormY = CGFloat(normY)
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

        // Determine animation state based on device state and movement
        let targetState = determineAnimationState()

        // Handle transition animation between states
        if isTransitioning && targetState != currentState {
            return getFramesForState(previousState)[currentFrame % getFramesForState(previousState).count]
        }

        return getFramesForState(targetState)[currentFrame % getFramesForState(targetState).count]
    }

    private func determineAnimationState() -> PetAnimationState {
        // Check weather-specific animations first
        if viewModel.deviceState.weatherType >= 3 && sceneMode {
            // Rainy weather - use raincoat pose
            if viewModel.deviceState.state == .idle {
                return .idle // raincoat handled by WeatherAccessories
            }
        }

        switch viewModel.deviceState.state {
        case .happy:
            // Trigger hearts when happy
            if currentInteractionType != .hearts {
                triggerInteraction(.hearts)
            }
            return .happy
        case .sleep:
            return .sleep
        default:
            // Check if pet is moving (using isMoving flag from touch/drag)
            if isMoving {
                // Spawn dust particles occasionally while walking
                if Date().timeIntervalSince(lastDustTime) > 0.15 {
                    spawnDustParticles(sceneW: sceneWidth, sceneH: sceneHeight)
                    lastDustTime = Date()
                }
                return .walk
            }
            return .idle
        }
    }

    private func getFramesForState(_ state: PetAnimationState) -> [[UInt16]] {
        switch state {
        case .idle: return SpriteFrames.idle
        case .walk: return SpriteFrames.walk
        case .happy: return SpriteFrames.happy
        case .excited: return SpriteFrames.excited
        case .eat: return SpriteFrames.eat
        case .play: return SpriteFrames.play
        case .wave: return SpriteFrames.wave
        case .sleep: return SpriteFrames.sleep
        case .talk: return SpriteFrames.talk
        }
    }

    private func transitionTo(_ newState: PetAnimationState) {
        guard !isTransitioning else { return }

        previousState = currentState
        currentState = newState
        isTransitioning = true
        transitionProgress = 0

        // Perform transition over 300ms
        withAnimation(.easeInOut(duration: 0.3)) {
            transitionProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isTransitioning = false
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

    // Bounce offset for transition animations
    private var bounceOffset: CGFloat {
        guard isTransitioning else { return 0 }
        // Sine wave bounce effect during transitions
        return sin(transitionProgress * .pi * 2) * 3
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: frameDuration / 1000.0, repeats: true) { _ in
            self.currentFrame += 1
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        interactionTimer?.invalidate()
        interactionTimer = nil
    }

    // Public method to trigger specific interactions from outside
    func triggerPlayInteraction() {
        triggerInteraction(.bubbles)
        transitionTo(.play)
    }

    func triggerExcitedInteraction() {
        triggerInteraction(.stars)
        transitionTo(.excited)
    }

    func triggerWaveInteraction() {
        transitionTo(.wave)
    }

    func triggerEatInteraction() {
        triggerInteraction(.sparkles)
        transitionTo(.eat)
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

    @State private var cloudOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Enhanced gradient sky
            skyGradient

            // Celestials with moving clouds
            CelestialsView(hour: hour, stars: $stars, lastStarToggle: $lastStarToggle, weatherType: weatherType, cloudOffset: cloudOffset)

            // Environment silhouettes (mountains/trees)
            if weatherType < 6 {
                EnvironmentSilhouetteView(hour: hour, weatherType: weatherType)
            }

            // Weather particles
            if weatherType >= 3 {
                WeatherParticlesView(weatherType: weatherType, particles: $particles, fogOffset: $fogOffset, lastFogUpdate: $lastFogUpdate, sceneWidth: sceneWidth, sceneHeight: sceneHeight, groundHeight: groundHeight)
            }

            // Ground with weather effects
            GroundView(hour: hour, groundHeight: groundHeight, weatherType: weatherType)

            // Thunder flash overlay
            if (weatherType == 6 || weatherType == 7) && thunderFlash {
                thunderOverlay
            }
        }
        .cornerRadius(16)
        .onAppear {
            startCloudMovement()
            updateThunderFlash()
        }
    }

    private var skyGradient: LinearGradient {
        let colors = skyGradientColors
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom)
    }

    private var skyGradientColors: [Color] {
        var baseColors: [Color]
        if hour >= 6 && hour < 17 {
            baseColors = [Color(red: 30/255, green: 80/255, blue: 180/255), Color(red: 60/255, green: 120/255, blue: 200/255), Color(red: 100/255, green: 160/255, blue: 220/255)]
        } else if hour >= 17 && hour < 19 {
            baseColors = [Color(red: 40/255, green: 20/255, blue: 80/255), Color(red: 120/255, green: 50/255, blue: 90/255), Color(red: 200/255, green: 100/255, blue: 60/255), Color(red: 255/255, green: 150/255, blue: 80/255)]
        } else {
            baseColors = [Color(red: 5/255, green: 5/255, blue: 25/255), Color(red: 10/255, green: 10/255, blue: 40/255), Color(red: 20/255, green: 20/255, blue: 50/255)]
        }
        if weatherType >= 2 {
            let tint = weatherTintColor.opacity(weatherBlendFactor * 0.6)
            return baseColors.enumerated().map { index, color in index == 0 ? color.opacity(0.9) : color }
        }
        return baseColors
    }

    private var weatherTintColor: Color {
        switch weatherType { case 2: return Color(red: 100/255, green: 100/255, blue: 110/255); case 3: return Color(red: 80/255, green: 85/255, blue: 95/255); case 4: return Color(red: 120/255, green: 130/255, blue: 150/255); case 5: return Color(red: 70/255, green: 75/255, blue: 90/255); case 6: return Color(red: 50/255, green: 55/255, blue: 70/255); case 7: return Color(red: 40/255, green: 45/255, blue: 60/255); default: return .clear }
    }

    private var weatherBlendFactor: Double {
        switch weatherType { case 2: return 0.4; case 3: return 0.5; case 4: return 0.35; case 5: return 0.55; case 6: return 0.6; case 7: return 0.65; default: return 0 }
    }

    private var thunderOverlay: some View {
        ZStack {
            Color(red: 0.85, green: 0.85, blue: 0.95).opacity(0.35)
            LightningBolt().fill(Color.white.opacity(0.25))
        }
    }

    private func startCloudMovement() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            cloudOffset += 0.4
            if cloudOffset > 500 { cloudOffset = -100 }
        }
    }

    private func updateThunderFlash() {
        if weatherType == 6 || weatherType == 7 {
            let now = Date()
            if now.timeIntervalSince(lastFlashTime) > nextFlashInterval {
                thunderFlash = true
                lastFlashTime = now
                nextFlashInterval = Double.random(in: 4...8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { thunderFlash = false }
            }
        }
    }
}

// MARK: - Lightning Bolt Shape

struct LightningBolt: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.width * 0.5
        path.move(to: CGPoint(x: cx + 25, y: 0))
        path.addLine(to: CGPoint(x: cx - 15, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: cx + 8, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: cx - 25, y: rect.height))
        path.addLine(to: CGPoint(x: cx + 12, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: cx - 8, y: rect.height * 0.55))
        path.closeSubpath()
        return path
    }
}

// MARK: - Environment Silhouette

struct EnvironmentSilhouetteView: View {
    let hour: Int
    let weatherType: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            MountainSilhouette()
            TreesSilhouette()
        }
        .foregroundColor(silhouetteColor)
    }

    private var silhouetteColor: Color {
        if hour >= 6 && hour < 17 { return Color(red: 40/255, green: 80/255, blue: 60/255).opacity(0.35) }
        else if hour >= 17 && hour < 19 { return Color(red: 60/255, green: 40/255, blue: 50/255).opacity(0.45) }
        else { return Color(red: 20/255, green: 25/255, blue: 40/255).opacity(0.55) }
    }
}

struct MountainSilhouette: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            let points: [CGPoint] = [
                CGPoint(x: 0, y: size.height - 35), CGPoint(x: 60, y: size.height - 65),
                CGPoint(x: 120, y: size.height - 45), CGPoint(x: 180, y: size.height - 85),
                CGPoint(x: 240, y: size.height - 60), CGPoint(x: 300, y: size.height - 95),
                CGPoint(x: 360, y: size.height - 70), CGPoint(x: 420, y: size.height - 80),
                CGPoint(x: 480, y: size.height - 50), CGPoint(x: 540, y: size.height - 65),
                CGPoint(x: 600, y: size.height - 40), CGPoint(x: 660, y: size.height - 55),
                CGPoint(x: 720, y: size.height - 35), CGPoint(x: 780, y: size.height - 45),
            ]
            for pt in points { path.addLine(to: pt) }
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            context.fill(path, with: .color(Color(red: 60/255, green: 80/255, blue: 100/255).opacity(0.25)))
        }.frame(height: 110)
    }
}

struct TreesSilhouette: View {
    var body: some View {
        Canvas { context, size in
            let treeColor = Color(red: 30/255, green: 50/255, blue: 40/255).opacity(0.3)
            let treePositions: [CGFloat] = [25, 75, 140, 210, 275, 345, 415, 485, 555, 625, 695, 765]
            for xPos in treePositions {
                drawPineTree(context: &context, x: xPos, height: 45 + CGFloat.random(in: -8...15), color: treeColor)
            }
        }.frame(height: 70)
    }

    private func drawPineTree(context: inout GraphicsContext, x: CGFloat, height: CGFloat, color: Color) {
        var path = Path()
        let baseY: CGFloat = 70
        let trunkH = height * 0.25
        path.move(to: CGPoint(x: x, y: baseY))
        path.addLine(to: CGPoint(x: x - 3, y: baseY - trunkH))
        path.addLine(to: CGPoint(x: x + 3, y: baseY - trunkH))
        path.closeSubpath()
        let foliageH = height * 0.75
        for i in 0..<3 {
            let ly = baseY - trunkH - (foliageH * CGFloat(i) / 3)
            let lw = (height * 0.35) * (1 - CGFloat(i) * 0.22)
            path.move(to: CGPoint(x: x, y: ly))
            path.addLine(to: CGPoint(x: x - lw, y: ly + foliageH/3.5))
            path.addLine(to: CGPoint(x: x + lw, y: ly + foliageH/3.5))
            path.closeSubpath()
        }
        context.fill(path, with: .color(color))
    }
}

// MARK: - Celestials (Sun/Moon/Stars/Clouds)

struct CelestialsView: View {
    let hour: Int
    @Binding var stars: [Bool]
    @Binding var lastStarToggle: Date
    let weatherType: Int
    let cloudOffset: CGFloat

    var body: some View {
        ZStack {
            if hour >= 6 && hour < 17 {
                SunView()
                MovingCloudView(offset: cloudOffset)
            } else if hour >= 17 && hour < 19 {
                EnhancedSunsetView()
            } else {
                MoonGlowView()
                StarsView(stars: $stars, lastStarToggle: $lastStarToggle)
            }
        }
    }
}

struct SunView: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi / 4
                Rectangle().fill(Color(red: 1, green: 220/255, blue: 60/255)).frame(width: 2, height: 6).offset(x: cos(angle) * 18, y: sin(angle) * 18)
            }
            Circle().fill(Color(red: 1, green: 220/255, blue: 60/255)).frame(width: 24, height: 24)
        }
        .position(x: 300, y: 185)
    }
}

struct EnhancedSunsetView: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 255/255, green: 100/255, blue: 50/255)).frame(width: 20, height: 20)
            Circle().fill(Color(red: 255/255, green: 150/255, blue: 80/255)).frame(width: 28, height: 28)
            Circle().fill(Color(red: 255/255, green: 200/255, blue: 120/255)).frame(width: 36, height: 36)
            Circle().fill(Color(red: 255/255, green: 220/255, blue: 180/255).opacity(0.5)).frame(width: 60, height: 30).offset(y: 10)
        }
        .position(x: 300, y: 50)
    }
}

struct MoonGlowView: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 180/255, green: 190/255, blue: 220/255).opacity(0.15)).frame(width: 50, height: 50)
            Circle().fill(Color(red: 180/255, green: 190/255, blue: 220/255).opacity(0.25)).frame(width: 38, height: 38)
            Circle().fill(Color(red: 220/255, green: 225/255, blue: 210/255)).frame(width: 26, height: 26)
            Circle().fill(Color(red: 15/255, green: 15/255, blue: 35/255)).frame(width: 22, height: 22).offset(x: 4, y: 0)
        }
        .position(x: 55, y: 60)
    }
}

struct StarsView: View {
    @Binding var stars: [Bool]
    @Binding var lastStarToggle: Date

    private let positions: [(CGFloat, CGFloat)] = [
        (80, 180), (150, 190), (220, 175), (290, 188), (40, 160), (120, 170), (200, 165), (330, 170),
        (70, 145), (180, 150), (260, 155), (310, 148), (95, 200), (250, 185), (350, 155), (55, 135),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<positions.count, id: \.self) { i in
                if stars[i] {
                    if i % 4 == 0 {
                        Rectangle().fill(Color(red: 220/255, green: 220/255, blue: 160/255)).frame(width: 2, height: 6).offset(x: positions[i].0, y: positions[i].1 - 3)
                        Rectangle().fill(Color(red: 220/255, green: 220/255, blue: 160/255)).frame(width: 6, height: 2).offset(x: positions[i].0, y: positions[i].1)
                    } else {
                        Rectangle().fill(Color(red: 220/255, green: 220/255, blue: 160/255)).frame(width: 2, height: 2).offset(x: positions[i].0, y: positions[i].1)
                    }
                }
            }
        }
        .onAppear { toggleStars() }
    }

    private func toggleStars() {
        let now = Date()
        if now.timeIntervalSince(lastStarToggle) > 0.8 {
            lastStarToggle = now
            for i in stars.indices { stars[i] = Bool.random() }
        }
    }
}

struct MovingCloudView: View {
    let offset: CGFloat

    var body: some View {
        ZStack {
            CloudLayer(color: Color(red: 240/255, green: 245/255, blue: 255/255).opacity(0.9), offset: offset, yOffset: 0, scale: 1.0)
            CloudLayer(color: Color(red: 230/255, green: 238/255, blue: 250/255).opacity(0.7), offset: offset * 0.7 + 100, yOffset: 20, scale: 0.8)
        }
    }
}

struct CloudLayer: View {
    let color: Color
    let offset: CGFloat
    let yOffset: CGFloat
    let scale: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8 * scale).fill(color).frame(width: 55 * scale, height: 16 * scale).offset(x: -40 * scale + (offset.truncatingRemainder(dividingBy: 600)), y: yOffset)
            RoundedRectangle(cornerRadius: 6 * scale).fill(color).frame(width: 35 * scale, height: 12 * scale).offset(x: -18 * scale + (offset.truncatingRemainder(dividingBy: 600)), y: yOffset + 9 * scale)
            RoundedRectangle(cornerRadius: 7 * scale).fill(color).frame(width: 50 * scale, height: 14 * scale).offset(x: 110 * scale + (offset.truncatingRemainder(dividingBy: 600)), y: yOffset + 12 * scale)
            RoundedRectangle(cornerRadius: 5 * scale).fill(color).frame(width: 30 * scale, height: 10 * scale).offset(x: 128 * scale + (offset.truncatingRemainder(dividingBy: 600)), y: yOffset + 18 * scale)
        }
        .position(x: 200, y: 175)
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
                FogView(fogOffset: fogOffset, groundHeight: groundHeight, sceneHeight: sceneHeight)
            } else {
                ForEach(particles) { particle in
                    RainSnowParticleView(particle: particle, weatherType: weatherType)
                }
                if weatherType == 6 || weatherType == 7 {
                    RainSplashView(groundHeight: groundHeight, sceneWidth: sceneWidth)
                }
            }
        }
        .onAppear { initParticles(); startParticleTimer() }
        .onChange(of: weatherType) { _ in initParticles() }
    }

    private func initParticles() {
        if !particles.isEmpty && lastWeatherType() == weatherType { return }
        let w = sceneWidth, h = sceneHeight, skyTop = groundHeight + 30

        switch weatherType {
        case 4: // Gentle snow with drift
            particles = (0..<18).map { _ in
                WeatherParticle(x: CGFloat.random(in: 0...w), y: CGFloat.random(in: skyTop...h), speed: CGFloat.random(in: 2...4), drift: CGFloat.random(in: -0.5...0.5), length: 6)
            }
        case 5, 7: // Heavy snow with swirl
            particles = (0..<30).map { _ in
                WeatherParticle(x: CGFloat.random(in: 0...w), y: CGFloat.random(in: skyTop...h), speed: CGFloat.random(in: 5...9), drift: CGFloat.random(in: -1.5...1.5), length: 12)
            }
        case 6: // Rain with parallax
            particles = (0..<35).map { _ in
                WeatherParticle(x: CGFloat.random(in: 0...w), y: CGFloat.random(in: skyTop...h), speed: CGFloat.random(in: 8...14), drift: CGFloat.random(in: -2...2), length: CGFloat.random(in: 8...16))
            }
        default: break
        }
    }

    private func lastWeatherType() -> Int { return weatherType }

    private func startParticleTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            for i in particles.indices {
                particles[i].y -= particles[i].speed
                particles[i].x += particles[i].drift
                if weatherType == 4 || weatherType == 5 || weatherType == 7 {
                    particles[i].drift += CGFloat.random(in: -0.1...0.1)
                    particles[i].drift = max(-1.5, min(1.5, particles[i].drift))
                }
                if particles[i].y < groundHeight {
                    particles[i].y = sceneHeight + CGFloat.random(in: 5...30)
                    particles[i].x = CGFloat.random(in: 0...sceneWidth)
                    particles[i].drift = weatherType == 6 ? CGFloat.random(in: -2...2) : CGFloat.random(in: -0.5...0.5)
                }
            }
        }
    }
}

struct RainSnowParticleView: View {
    let particle: WeatherParticle
    let weatherType: Int

    var body: some View {
        Rectangle()
            .fill(particleColor)
            .frame(width: particle.width, height: particle.length)
            .rotationEffect(.degrees(weatherType == 6 || weatherType == 7 ? 15 : 0))
            .position(x: particle.x, y: particle.y)
    }

    private var particleColor: Color {
        if weatherType == 4 || weatherType == 5 || weatherType == 7 {
            return Color.white.opacity(0.85)
        } else {
            return Color(red: 180/255, green: 190/255, blue: 220/255).opacity(0.7)
        }
    }
}

struct RainSplashView: View {
    let groundHeight: CGFloat
    let sceneWidth: CGFloat
    @State private var splashes: [(CGFloat, CGFloat, CGFloat)] = []

    var body: some View {
        Canvas { context, size in
            let splashColor = Color(red: 180/255, green: 190/255, blue: 220/255).opacity(0.4)
            for splash in splashes {
                let age = splash.2
                let alpha = max(0, 1 - age)
                let radius = 2 + age * 4
                var path = Path()
                path.addEllipse(in: CGRect(x: splash.0 - radius, y: groundHeight - radius * 0.3, width: radius * 2, height: radius * 0.6))
                context.fill(path, with: .color(splashColor.opacity(alpha * 0.5)))
            }
        }
        .onAppear { startSplashes() }
    }

    private func startSplashes() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            let x = CGFloat.random(in: 20...sceneWidth - 20)
            splashes.append((x, groundHeight, 0))
            splashes = splashes.compactMap { splash in
                let newAge = splash.2 + 0.15
                return newAge < 1 ? (splash.0, splash.1, newAge) : nil
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
    var weatherType: Int = 0

    var body: some View {
        VStack {
            Spacer()
            ZStack(alignment: .bottom) {
                // Main ground with weather effects
                Rectangle()
                    .fill(groundColor)
                    .frame(height: groundHeight)

                // Snow coverage layer
                if weatherType == 4 || weatherType == 5 {
                    SnowCoverageView(groundHeight: groundHeight, intensity: weatherType == 5 ? 0.8 : 0.5)
                }

                // Puddles for rain/thunder
                if weatherType == 3 || weatherType == 6 || weatherType == 7 {
                    PuddlesView(groundHeight: groundHeight, weatherType: weatherType)
                }

                // Top highlight
                Rectangle()
                    .fill(highlightColor)
                    .frame(height: 2)
                    .offset(y: -groundHeight + 2)

                // Grass tufts (hidden under snow)
                if weatherType != 4 && weatherType != 5 {
                    GrassTuftsView(groundHeight: groundHeight, hour: hour)
                }
            }
        }
    }

    private var groundColor: Color {
        if weatherType == 4 || weatherType == 5 {
            return Color(red: 220/255, green: 225/255, blue: 235/255)
        } else if hour >= 6 && hour < 19 {
            return Color(red: 80/255, green: 140/255, blue: 60/255)
        } else {
            return Color(red: 50/255, green: 100/255, blue: 40/255)
        }
    }

    private var highlightColor: Color {
        if weatherType == 4 || weatherType == 5 {
            return Color.white.opacity(0.9)
        } else {
            return Color(red: 100/255, green: 170/255, blue: 70/255)
        }
    }
}

struct SnowCoverageView: View {
    let groundHeight: CGFloat
    let intensity: Double

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(intensity * 0.7))
            .frame(height: groundHeight * 0.6)
            .offset(y: -groundHeight * 0.4)
            .blendMode(.plusLighter)
    }
}

struct PuddlesView: View {
    let groundHeight: CGFloat
    let weatherType: Int

    var body: some View {
        Canvas { context, size in
            let puddleColor = Color(red: 80/255, green: 90/255, blue: 110/255).opacity(0.4)
            let positions: [(CGFloat, CGFloat)] = [(50, 0.3), (150, 0.5), (280, 0.25), (400, 0.4), (520, 0.35), (630, 0.45)]
            for (x, widthMult) in positions {
                let w = size.width * widthMult * 0.3
                let rect = CGRect(x: x, y: groundHeight - 3, width: w, height: 2)
                context.fill(Path(ellipseIn: rect), with: .color(puddleColor))
            }
        }
    }
}

struct GrassTuftsView: View {
    let groundHeight: CGFloat
    let hour: Int

    var body: some View {
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
            .background(Color.black.opacity(0.5))
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
                .offset(x: spriteOrigin.x + 32 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 48))
            Rectangle()
                .fill(Color(red: 20/255, green: 20/255, blue: 40/255))
                .frame(width: 24, height: 8)
                .offset(x: spriteOrigin.x + 72 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 48))
            Rectangle()
                .fill(Color(red: 20/255, green: 20/255, blue: 40/255))
                .frame(width: 16, height: 3)
                .offset(x: spriteOrigin.x + 56 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 46))
        }
    }
}

struct UmbrellaView: View {
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat
    let scale: Int

    var body: some View {
        ZStack {
            // Umbrella top - positioned above sprite
            RoundedRectangle(cornerRadius: 11)
                .fill(Color(red: 60/255, green: 60/255, blue: 200/255))
                .frame(width: 96, height: 21)
                .offset(x: spriteOrigin.x + 16 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize + 6))
            // Handle
            Rectangle()
                .fill(Color(red: 120/255, green: 80/255, blue: 40/255))
                .frame(width: 4, height: 22)
                .offset(x: spriteOrigin.x + 62 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 16))
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
                .offset(x: spriteOrigin.x + 24 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 24))
            // Pom pom
            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)
                .offset(x: spriteOrigin.x + 56 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize))
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
                .offset(x: spriteOrigin.x + 32 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 72))
            // Straps
            Rectangle()
                .fill(Color(red: 120/255, green: 120/255, blue: 120/255))
                .frame(width: 8, height: 3)
                .offset(x: spriteOrigin.x + 24 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 64))
            Rectangle()
                .fill(Color(red: 120/255, green: 120/255, blue: 120/255))
                .frame(width: 8, height: 3)
                .offset(x: spriteOrigin.x + 96 * 8 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize - 64))
        }
    }
}

// MARK: - Sleep Z Animation

// Interaction particle types
enum InteractionType {
    case none
    case hearts
    case stars
    case bubbles
    case sparkles
}

// Dust particle emitter for walking effects
struct DustParticleEmitter: View {
    let particles: [DustParticle]
    let spriteSize: CGFloat
    let horizontalOffset: CGFloat
    let verticalOffset: CGFloat
    let groundHeight: CGFloat
    let sceneMode: Bool

    var body: some View {
        ForEach(particles) { particle in
            Circle()
                .fill(Color.brown.opacity(0.4 * particle.opacity))
                .frame(width: 4 * particle.scale, height: 4 * particle.scale)
                .position(x: particle.x, y: particle.y)
        }
    }
}

// Interaction particle emitter view
struct InteractionParticleEmitter: View {
    let particles: [InteractionParticle]
    let particleType: InteractionType
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                particleView(for: particle)
            }
        }
    }

    @ViewBuilder
    private func particleView(for particle: InteractionParticle) -> some View {
        switch particleType {
        case .hearts:
            heartParticle(particle)
        case .stars:
            starParticle(particle)
        case .bubbles:
            bubbleParticle(particle)
        case .sparkles:
            sparkleParticle(particle)
        case .none:
            EmptyView()
        }
    }

    private func heartParticle(_ particle: InteractionParticle) -> some View {
        Text("❤️")
            .font(.system(size: 12 * particle.scale))
            .opacity(particle.opacity)
            .rotationEffect(.degrees(particle.rotation))
            .position(x: particle.x, y: particle.y)
    }

    private func starParticle(_ particle: InteractionParticle) -> some View {
        Text("⭐")
            .font(.system(size: 10 * particle.scale))
            .opacity(particle.opacity)
            .rotationEffect(.degrees(particle.rotation))
            .position(x: particle.x, y: particle.y)
    }

    private func bubbleParticle(_ particle: InteractionParticle) -> some View {
        Circle()
            .fill(Color.cyan.opacity(0.6))
            .frame(width: 6 * particle.scale, height: 6 * particle.scale)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .opacity(particle.opacity)
            .position(x: particle.x, y: particle.y)
    }

    private func sparkleParticle(_ particle: InteractionParticle) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 2 * particle.scale, height: 2 * particle.scale)
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 2 * particle.scale, height: 6 * particle.scale)
                .offset(y: -2 * particle.scale)
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 6 * particle.scale, height: 2 * particle.scale)
                .offset(x: -2 * particle.scale)
        }
        .opacity(particle.opacity)
        .rotationEffect(.degrees(particle.rotation))
        .position(x: particle.x, y: particle.y)
    }
}

// Extension to PetView to manage interaction particles
extension PetView {
    func triggerInteraction(_ type: InteractionType) {
        currentInteractionType = type
        interactionParticles.removeAll()

        guard type != .none else { return }

        // Spawn 5-8 particles
        let count = Int.random(in: 5...8)
        for i in 0..<count {
            let delay = Double(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                spawnInteractionParticle(type: type)
            }
        }

        // Start animation timer
        startInteractionAnimation()
    }

    private func spawnInteractionParticle(type: InteractionType) {
        let spriteSize: CGFloat = min(sceneHeight * 0.5, 150)
        let scale = Int(spriteSize / 16)
        let baseX = spriteNormX * sceneWidth
        let baseY = (sceneHeight - groundHeight - spriteSize / 2)

        let particle = InteractionParticle(
            x: baseX + CGFloat.random(in: -30...30),
            y: baseY - CGFloat.random(in: 0...40),
            scale: CGFloat.random(in: 0.8...1.5),
            opacity: 1.0,
            rotation: Double.random(in: -30...30),
            velocityY: CGFloat.random(in: -1.5 ... -0.5),
            velocityX: CGFloat.random(in: -0.5...0.5)
        )
        interactionParticles.append(particle)
    }

    private func startInteractionAnimation() {
        interactionTimer?.invalidate()
        interactionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateInteractionParticles()
        }

        // Auto-stop after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            interactionTimer?.invalidate()
            interactionTimer = nil
            // Fade out remaining particles
            fadeOutParticles()
        }
    }

    private func updateInteractionParticles() {
        for i in interactionParticles.indices {
            interactionParticles[i].y += interactionParticles[i].velocityY
            interactionParticles[i].x += interactionParticles[i].velocityX
            interactionParticles[i].rotation += Double.random(in: -5...5)
        }

        // Remove particles that have floated away
        interactionParticles.removeAll { $0.y < (sceneHeight - groundHeight - 150) }
    }

    private func fadeOutParticles() {
        for i in interactionParticles.indices {
            withAnimation(.easeOut(duration: 0.3)) {
                interactionParticles[i].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.interactionParticles.removeAll()
            self.currentInteractionType = .none
        }
    }

    // MARK: - Dust Particle System

    func spawnDustParticles(sceneW: CGFloat, sceneH: CGFloat) {
        let spriteSize: CGFloat = min(sceneH * 0.5, 150)
        let maxOffsetX = max(0, sceneW - spriteSize - 20)
        let horizontalPos = CGFloat(normX) * maxOffsetX + spriteSize / 2
        let groundY = sceneH - groundHeight - 5

        // Spawn 1-3 dust particles
        let count = Int.random(in: 1...3)
        for _ in 0..<count {
            let dust = DustParticle(
                x: horizontalPos + CGFloat.random(in: -10...10),
                y: groundY + CGFloat.random(in: -5...5),
                scale: CGFloat.random(in: 0.5...1.2),
                opacity: 0.6,
                velocityX: CGFloat.random(in: -1.5...1.5),
                velocityY: CGFloat.random(in: -0.8...0.2),
                lifetime: 0.5
            )
            dustParticles.append(dust)
        }

        // Limit total dust particles
        if dustParticles.count > 20 {
            dustParticles.removeFirst(dustParticles.count - 20)
        }

        // Start dust animation if not already running
        startDustAnimation()
    }

    private func startDustAnimation() {
        guard dustTimer == nil else { return }
        dustTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [self] _ in
            updateDustParticles()
        }
    }

    private func updateDustParticles() {
        for i in dustParticles.indices {
            dustParticles[i].x += dustParticles[i].velocityX
            dustParticles[i].y += dustParticles[i].velocityY
            dustParticles[i].opacity -= 0.02
            dustParticles[i].scale *= 0.98
        }

        // Remove faded particles
        dustParticles.removeAll { $0.opacity <= 0 || $0.scale < 0.1 }
    }
}

struct SleepZAnimation: View {
    let scale: Int
    let spriteOrigin: CGPoint
    let spriteSize: CGFloat

    @State private var phase: Int = 0

    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if phase >= 1 {
                Text("z")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: spriteOrigin.x + 106 * 16 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize + 68 * 16 / CGFloat(scale)))
            }
            if phase >= 2 {
                Text("Z")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: spriteOrigin.x + 118 * 16 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize + 96 * 16 / CGFloat(scale)))
            }
            if phase >= 3 {
                Text("Z")
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: spriteOrigin.x + 112 * 16 / CGFloat(scale), y: -(spriteOrigin.y + spriteSize + 132 * 16 / CGFloat(scale)))
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 4
        }
    }
}
