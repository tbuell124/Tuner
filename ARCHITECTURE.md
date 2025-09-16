# TunePlay Architecture Documentation

## System Overview

TunePlay is architected as a real-time audio processing application with a game-like user interface. The system is designed for minimal latency, maximum accuracy, and delightful user experience.

## Core Components

### 1. Audio Processing Layer

#### AudioTuner.swift
- **Purpose**: Main audio processing coordinator
- **Responsibilities**:
  - AVAudioEngine management
  - Audio session configuration
  - Real-time audio buffer processing
  - Noise suppression mode switching
  - Guitar string detection

#### PitchDetectionService.swift
- **Purpose**: Algorithm abstraction layer
- **Responsibilities**:
  - Multiple algorithm support (YIN, HPS, Quadratic, Quinn's)
  - Detector switching at runtime
  - Confidence scoring
  - Performance benchmarking

#### TunaDetectors.swift
- **Purpose**: Tuna library integration
- **Responsibilities**:
  - Wrapper classes for each Tuna algorithm
  - Consistent interface implementation
  - Error handling and fallback logic

### 2. User Interface Layer

#### GameTunerView.swift
- **Purpose**: Main game-like tuning interface
- **Responsibilities**:
  - Full-screen radial gauge rendering
  - Smooth needle animation with physics
  - Particle system for celebrations
  - Haptic feedback coordination
  - Accessibility support

#### ContentView.swift
- **Purpose**: App entry point and coordinator
- **Responsibilities**:
  - AudioTuner lifecycle management
  - Dark mode enforcement
  - Status bar hiding

### 3. Supporting Systems

#### Haptics Management
- Core Haptics integration
- Contextual feedback (near, perfect tuning)
- Performance-optimized triggering

#### Particle System
- SwiftUI-based particle rendering
- Physics simulation for realistic motion
- Performance-optimized for 60/120Hz

## Data Flow

```
Audio Input → AVAudioEngine → AudioTuner → PitchDetectionService → UI Update
                                    ↓
                            Confidence Analysis → Stability Tracking → Haptics
                                    ↓
                            String Detection → Visual Feedback → Particles
```

## Real-Time Constraints

### Audio Thread Safety
- No allocations in audio callback
- Pre-allocated buffers for processing
- Lock-free data structures where possible

### Latency Optimization
- 48kHz sample rate preferred
- 2048 sample buffer size (42.7ms at 48kHz)
- 5ms IO buffer duration
- Vectorized operations with Accelerate

### CPU Optimization
- vDSP for FFT operations
- Efficient algorithm selection
- Background thread for heavy processing

## Algorithm Selection Strategy

### Primary: YIN Algorithm
- **Strengths**: Robust with guitar harmonics, good noise immunity
- **Use Case**: Default for most guitar tuning scenarios
- **Performance**: Medium CPU, high accuracy

### Secondary: HPS (Harmonic Product Spectrum)
- **Strengths**: Excellent with rich harmonic content
- **Use Case**: Electric guitars with complex pickup responses
- **Performance**: Higher CPU, very high accuracy

### Fallback: Quadratic Interpolation
- **Strengths**: Fast execution, good for clean signals
- **Use Case**: Acoustic guitars in quiet environments
- **Performance**: Low CPU, good accuracy

### Experimental: Quinn's Estimators
- **Strengths**: Advanced frequency estimation techniques
- **Use Case**: Research and comparison benchmarking
- **Performance**: Variable CPU, research-grade accuracy

## Noise Suppression Strategy

### Measurement Mode (Default)
```swift
try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
```
- **Advantages**: Minimal processing, maximum accuracy
- **Disadvantages**: No noise reduction
- **Use Case**: Quiet practice environments

### Voice Processing Mode (Fallback)
```swift
try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
```
- **Advantages**: Hardware-accelerated noise reduction
- **Disadvantages**: Potential pitch bias
- **Use Case**: Noisy environments (TV, conversation)

### Adaptive Switching
- Monitor confidence levels over time
- Switch to voice processing if confidence drops
- Return to measurement mode when environment quiets

## Performance Monitoring

### Latency Measurement
```swift
let startTime = CFAbsoluteTimeGetCurrent()
// ... processing ...
let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
```

### CPU Usage Tracking
```swift
let startCPU = ProcessInfo.processInfo.systemUptime
// ... processing ...
let cpuUsage = (ProcessInfo.processInfo.systemUptime - startCPU) * 100
```

### Accuracy Metrics
```swift
let cents = 1200 * log2(detectedFreq / expectedFreq)
let accuracy = abs(detectedFreq - expectedFreq) / expectedFreq
```

## Testing Architecture

### Unit Tests
- Algorithm switching logic
- Tuning math calculations
- Guitar string frequency validation
- Confidence scoring accuracy

### Integration Tests
- Audio pipeline end-to-end
- UI state management
- Haptic feedback timing

### Benchmark Framework
- Synthetic tone generation
- Multi-algorithm comparison
- Performance regression detection
- CSV export for analysis

## Error Handling

### Audio Session Failures
```swift
do {
    try session.setActive(true)
} catch {
    // Graceful degradation to silent mode
    print("Audio session error: \(error)")
}
```

### Microphone Permission
- Request permission on first launch
- Graceful UI state when denied
- Clear user messaging for resolution

### Algorithm Failures
- Automatic fallback to simpler algorithms
- Confidence-based error detection
- Logging for debugging

## Future Extensibility

### Algorithm Plugins
- Protocol-based architecture allows easy addition
- Runtime algorithm discovery
- A/B testing framework built-in

### UI Themes
- Modular visual components
- Color scheme abstraction
- Animation parameter tuning

### Advanced Features
- MIDI output capability
- Custom temperament support
- Multi-instrument detection

## Security Considerations

### Privacy
- All processing on-device
- No network communication
- No audio data storage
- Microphone usage clearly communicated

### Performance
- Memory usage monitoring
- CPU throttling detection
- Battery usage optimization

This architecture provides a solid foundation for a professional-grade guitar tuner while maintaining the flexibility for future enhancements and optimizations.
