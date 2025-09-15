import SwiftUI
import CoreHaptics

struct GameTunerView: View {
    let note: String
    let cents: Double
    let confidence: Double
    let isStable: Bool
    let detectedString: String
    
    @State private var needleAngle: Double = 0
    @State private var showParticles: Bool = false
    @State private var hapticsEngine: CHHapticEngine?
    @State private var lastHapticTime: Date = Date()
    
    private let maxCents: Double = 50
    private let perfectThreshold: Double = 2.0
    private let nearThreshold: Double = 10.0
    
    private var targetAngle: Double {
        let clampedCents = max(-maxCents, min(maxCents, cents))
        return (clampedCents / maxCents) * 60
    }
    
    private var tuningState: TuningState {
        let absCents = abs(cents)
        if absCents <= perfectThreshold && isStable {
            return .perfect
        } else if absCents <= nearThreshold {
            return .near
        } else {
            return .off
        }
    }
    
    private var gaugeColor: Color {
        switch tuningState {
        case .perfect:
            return .green
        case .near:
            return .yellow
        case .off:
            return .red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    ZStack {
                        RadialGaugeView(
                            angle: needleAngle,
                            color: gaugeColor,
                            showParticles: showParticles && tuningState == .perfect
                        )
                        .frame(width: min(geometry.size.width * 0.9, 400))
                        .aspectRatio(1, contentMode: .fit)
                        
                        if !detectedString.isEmpty {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text(detectedString)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.trailing, 20)
                                        .padding(.bottom, 40)
                                }
                            }
                        }
                    }
                    
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 8) {
                        Text(note)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(gaugeColor)
                            .animation(.easeInOut(duration: 0.2), value: gaugeColor)
                        
                        if confidence > 0.3 {
                            Text("\(cents >= 0 ? "+" : "")\(Int(cents.rounded())) cents")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if note == "--" {
                            Text("Pluck a string")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 8)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            setupHaptics()
        }
        .onChange(of: targetAngle) { newAngle in
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                needleAngle = newAngle
            }
        }
        .onChange(of: tuningState) { newState in
            handleTuningStateChange(newState)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Guitar tuner showing \(note), \(Int(cents.rounded())) cents \(cents >= 0 ? "sharp" : "flat")")
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticsEngine = try CHHapticEngine()
            try hapticsEngine?.start()
        } catch {
            print("Haptics engine error: \(error)")
        }
    }
    
    private func handleTuningStateChange(_ state: TuningState) {
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) > 0.1 else { return }
        lastHapticTime = now
        
        switch state {
        case .perfect:
            showParticles = true
            triggerHaptic(intensity: 1.0, sharpness: 0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showParticles = false
            }
        case .near:
            triggerHaptic(intensity: 0.6, sharpness: 0.5)
        case .off:
            showParticles = false
        }
    }
    
    private func triggerHaptic(intensity: Float, sharpness: Float) {
        guard let engine = hapticsEngine else { return }
        
        let hapticEvent = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic playback error: \(error)")
        }
    }
}

enum TuningState {
    case perfect
    case near
    case off
}

struct RadialGaugeView: View {
    let angle: Double
    let color: Color
    let showParticles: Bool
    
    @State private var particleOffset: CGSize = .zero
    @State private var particleOpacity: Double = 0
    
    private let gaugeRadius: CGFloat = 140
    private let needleLength: CGFloat = 120
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .red, .red,
                            .yellow, .yellow,
                            .green, .green,
                            .yellow, .yellow,
                            .red, .red
                        ]),
                        center: .center,
                        startAngle: .degrees(120),
                        endAngle: .degrees(60)
                    ),
                    lineWidth: 20
                )
                .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)
            
            ForEach(-5...5, id: \.self) { tick in
                TickMark(
                    angle: Double(tick) * 12,
                    isCenter: tick == 0,
                    isMajor: tick % 5 == 0,
                    radius: gaugeRadius
                )
            }
            
            NeedleView(angle: angle, length: needleLength, color: color)
            
            Circle()
                .fill(Color.black)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 20, height: 20)
            
            if showParticles {
                ParticleSystemView()
                    .frame(width: gaugeRadius * 2, height: gaugeRadius * 2)
            }
        }
    }
}

struct TickMark: View {
    let angle: Double
    let isCenter: Bool
    let isMajor: Bool
    let radius: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(isCenter ? Color.green : (isMajor ? Color.white : Color.gray))
            .frame(
                width: isCenter ? 4 : (isMajor ? 3 : 2),
                height: isCenter ? 25 : (isMajor ? 20 : 12)
            )
            .offset(y: -radius + (isCenter ? 12.5 : (isMajor ? 10 : 6)))
            .rotationEffect(.degrees(angle))
    }
}

struct NeedleView: View {
    let angle: Double
    let length: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.8), color, color.opacity(0.6)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 4, height: length)
                .offset(y: -length / 2)
                .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 0)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .offset(y: -length + 4)
                .shadow(color: color.opacity(0.8), radius: 4, x: 0, y: 0)
        }
        .rotationEffect(.degrees(angle))
        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: angle)
    }
}

struct ParticleSystemView: View {
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            startParticleAnimation()
        }
        .onDisappear {
            stopParticleAnimation()
        }
    }
    
    private func startParticleAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            addParticles()
            updateParticles()
        }
    }
    
    private func stopParticleAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func addParticles() {
        for _ in 0..<3 {
            let particle = Particle(
                id: UUID(),
                offset: CGSize(
                    width: Double.random(in: -50...50),
                    height: Double.random(in: -50...50)
                ),
                velocity: CGSize(
                    width: Double.random(in: -100...100),
                    height: Double.random(in: -150...(-50))
                ),
                color: [Color.green, Color.yellow, Color.white].randomElement()!,
                size: Double.random(in: 4...12),
                opacity: 1.0,
                scale: 1.0,
                life: 1.0
            )
            particles.append(particle)
        }
    }
    
    private func updateParticles() {
        particles = particles.compactMap { particle in
            var updatedParticle = particle
            updatedParticle.offset.width += particle.velocity.width * 0.016
            updatedParticle.offset.height += particle.velocity.height * 0.016
            updatedParticle.velocity.height += 200 * 0.016
            updatedParticle.life -= 0.05
            updatedParticle.opacity = max(0, particle.life)
            updatedParticle.scale = 1.0 + (1.0 - particle.life) * 0.5
            
            return updatedParticle.life > 0 ? updatedParticle : nil
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    var offset: CGSize
    var velocity: CGSize
    let color: Color
    let size: Double
    var opacity: Double
    var scale: Double
    var life: Double
}
