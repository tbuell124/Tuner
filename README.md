# TunePlay - Modern Game-Like Guitar Tuner for iOS

TunePlay is a fast, dead-accurate, zero-interaction chromatic guitar tuner for iPhone that feels like a tiny game the moment it opens. No buttons, no menus on the main screen—just open and it works.

## Features

### Zero-Interaction Design
- App auto-starts listening and tuning immediately upon launch
- No taps, buttons, or menus required on the main screen
- Full-screen radial gauge with smooth needle animation
- Game-like visual feedback with particle celebrations

### Advanced Pitch Detection
- Multiple switchable algorithms: YIN, HPS, Quadratic Interpolation, Quinn's Estimators
- Native Swift implementations using AVFoundation and Accelerate frameworks
- Confidence scoring and stability tracking with hysteresis
- Guitar string detection for E2-E4 range

### Noise Suppression
- Hybrid approach with measurement and voice processing modes
- Adaptive switching based on environmental conditions
- Optimized for guitar frequencies with band-pass filtering

### Performance Optimized
- Target ≤40ms latency on iPhone 12+, ≤60ms on iPhone X/XS
- ≤15% CPU usage on A15, ≤25% on A12
- 48kHz audio processing with 5ms buffer duration
- Real-time safe audio callbacks with no allocations

### Accessibility & Haptics
- Core Haptics integration for pitch lock feedback
- Colorblind-safe color palette (red → yellow → green)
- VoiceOver support with descriptive labels
- High contrast mode support

## Technical Architecture

### Audio Pipeline
```
Microphone → AVAudioEngine → Noise Processing → Pitch Detection → UI Update
                                    ↓
                            Confidence Scoring → Stability Tracking → Haptics
```

### Pitch Detection Algorithms
1. **YIN** - Robust autocorrelation-based estimator
2. **HPS** - Harmonic Product Spectrum for rich harmonics
3. **Quadratic** - Interpolated peak detection
4. **Quinn's** - Advanced frequency estimation
5. **Current** - Basic autocorrelation fallback

### Noise Suppression Modes
- **Measurement Mode**: Minimal processing for maximum accuracy
- **Voice Processing**: Hardware-accelerated noise reduction
- **Adaptive**: Switches based on confidence levels

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15.0+
- Microphone access

## Installation

1. Clone the repository
2. Open `PedalTuner/Package.swift` in Xcode
3. Build and run on device or simulator
4. Grant microphone permission when prompted

## Usage

1. Launch TunePlay
2. Pluck a guitar string
3. Watch the radial gauge and needle indicate tuning
4. Celebrate with particles when perfectly in tune!

## Testing

### Unit Tests
```bash
swift test
```

### Benchmark Suite
```swift
let runner = BenchmarkRunner()
let results = runner.runComprehensiveBenchmark()
runner.exportResultsToCSV(results, filename: "benchmark_results.csv")
```

### Test Coverage
- Pitch detection algorithm switching
- Tuning math calculations (frequency to note conversion)
- Guitar string frequency validation
- Cents calculation and smoothing
- Audio tuner state management

## Performance Metrics

### Accuracy Targets
- ≤±1 cent in quiet rooms
- ≤±3 cents with typical room noise (TV at 55-60 dBA)

### Latency Targets
- ≤40ms median on iPhone 12 and newer
- ≤60ms on iPhone X/XS

### CPU Usage Targets
- ≤15% on A15 Bionic
- ≤25% on A12 Bionic

### Stability Requirements
- Stable lock for sustained notes ≥250ms
- Fast reacquisition between plucks

## Dependencies

- AVFoundation - Audio processing
- Accelerate - DSP operations
- SwiftUI - User interface
- Core Haptics - Tactile feedback

## Architecture Decisions

### Why Hybrid Noise Suppression?
- Measurement mode provides maximum accuracy
- Voice processing mode handles noisy environments
- A/B testing determines optimal approach per use case

### Why SwiftUI over UIKit?
- Declarative UI matches game-like requirements
- Built-in animation system
- Better accessibility support
- Easier particle system implementation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests and benchmarks
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Apple's AVAudioEngine for real-time audio processing
- Apple's Accelerate framework for DSP operations
- Core Haptics for tactile feedback
- SwiftUI for modern declarative UI
