# TunePlay

TunePlay is a sophisticated iOS guitar tuner application that combines precision with an engaging, game-like interface. Built with SwiftUI and advanced audio processing, it offers multiple pitch detection algorithms, haptic feedback, particle effects, and real-time visual feedback to help guitarists achieve perfect tuning.

## Features

### Core Functionality
- **Real-time pitch detection** with sub-cent accuracy using advanced algorithms
- **Five sophisticated detection algorithms**: 
  - YIN (autocorrelation-based with cumulative mean normalized difference)
  - HPS (Harmonic Product Spectrum with FFT analysis)
  - Quadratic Interpolation (parabolic peak refinement)
  - Quinn's Method (advanced frequency estimation)
  - Current (optimized autocorrelation)
- **Guitar string detection** with automatic string identification for standard tuning
- **Adaptive noise suppression** with multiple processing modes
- **Pitch stabilization** with hysteresis to reduce jitter and false readings

### User Interface
- **Game-like radial gauge** with animated needle and color-coded feedback
- **Particle effects system** when achieving perfect tuning (±2 cents)
- **Haptic feedback** with intensity-based responses for tuning states
- **Professional dark mode** interface optimized for stage use
- **Accessibility support** with comprehensive VoiceOver labels
- **Real-time cents display** with ±50 cent range and smoothing

### Technical Features
- **Dual audio processing modes**: Measurement (high precision) and Voice Processing (noise reduction)
- **Real-time FFT analysis** using Apple's Accelerate framework
- **48kHz sample rate** with 2048-sample buffer for optimal latency/accuracy balance
- **Comprehensive test suite** with mathematical validation and algorithm benchmarking
- **Google AdMob integration** for monetization
- **Cross-platform compatibility** (iOS primary with Swift Package, Web secondary)

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

## Project Structure

```
Tuner/
├── PedalTuner/           # iOS Swift Package
│   ├── Sources/
│   │   └── TunePlay/     # Main source code
│   │       ├── Audio/    # Audio processing and pitch detection
│   │       │   ├── AudioInput.swift
│   │       │   ├── AudioPreprocessor.swift
│   │       │   ├── NativePitchDetectors.swift
│   │       │   ├── NoiseSuppressionEngine.swift
│   │       │   ├── PitchDetectionService.swift
│   │       │   ├── PitchStabilizer.swift
│   │       │   └── TunerViewModel.swift
│   │       ├── UI/       # User interface components
│   │       │   ├── AdBannerView.swift
│   │       │   └── GameTunerView.swift
│   │       ├── AudioTuner.swift      # Main tuner controller
│   │       ├── ContentView.swift     # Root view with AdMob
│   │       ├── TunePlayApp.swift     # App entry point
│   │       └── TunerView.swift       # Simple tuner view
│   ├── Tests/
│   │   └── TunePlayTests/    # Comprehensive unit tests
│   │       ├── AudioTunerTests.swift
│   │       ├── PitchDetectionTests.swift
│   │       ├── TuningMathTests.swift
│   │       └── PedalTunerTests.swift
│   └── Package.swift        # Package configuration with AdMob
├── TunePlayApp/             # iOS App Project for App Store
│   └── TunePlayApp/
│       ├── TunePlayAppApp.swift
│       ├── ContentView.swift
│       └── Info.plist       # AdMob configuration
├── README.md               # This file
└── ARCHITECTURE.md         # Technical architecture details
```

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15.0+
- Microphone access
- Apple Developer Account (for App Store submission)

## Installation & Development

### Swift Package Development
1. Clone the repository
2. Open `PedalTuner/Package.swift` in Xcode
3. Build and run on device or simulator
4. Grant microphone permission when prompted

### iOS App for App Store
1. Open `TunePlayApp/TunePlayApp.xcodeproj` in Xcode
2. Configure your development team and bundle identifier
3. Build and run on device
4. Follow the Google AdMob setup guide for production deployment

## Usage

1. Launch TunePlay
2. Pluck a guitar string
3. Watch the radial gauge and needle indicate tuning
4. Celebrate with particles when perfectly in tune!

## Testing

### Unit Tests
```bash
cd PedalTuner
swift test
```

### Test Coverage
- Pitch detection algorithm switching and accuracy
- Tuning math calculations (frequency to note conversion)
- Guitar string frequency validation
- Cents calculation and smoothing algorithms
- Audio tuner state management and stability
- Mathematical validation of all pitch detection algorithms

## Dependencies

- **GoogleMobileAds** - Monetization through banner advertisements
- **AVFoundation** - Real-time audio processing and microphone access
- **Accelerate** - High-performance DSP operations and FFT analysis
- **SwiftUI** - Modern declarative user interface
- **CoreHaptics** - Tactile feedback for enhanced user experience

## Architecture

The app uses a sophisticated multi-layered architecture:

1. **Audio Layer**: Real-time microphone input with noise suppression
2. **Processing Layer**: Five different pitch detection algorithms
3. **Analysis Layer**: Confidence scoring and pitch stabilization
4. **UI Layer**: Game-like visual feedback with animations
5. **Feedback Layer**: Haptic and particle effects for perfect tuning

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests and benchmarks
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Tuna library for advanced pitch detection algorithms
- Apple's AVAudioEngine for real-time audio processing
- Core Haptics for tactile feedback
- SwiftUI for modern declarative UI
