# TunePlay Repository Shortlist & Technology Assessment

## Pitch Detection Libraries

### 1. Beethoven (vadymmarkov/Beethoven)
- **Stars**: 850
- **License**: MIT
- **Language**: Swift
- **Last Updated**: Active (recent commits)
- **Algorithms**: YIN, HPS, Quadratic Interpolation, Quinn's First/Second Estimators, Jains Estimator, HPSProduct
- **Integration Effort**: Medium - Well documented, Swift Package Manager support
- **Expected Benefit**: High - Multiple robust algorithms, proven in production
- **Pros**: 
  - Comprehensive algorithm suite
  - Active maintenance
  - Good documentation
  - Real-time audio processing with AVAudioEngine
  - Guitar tuner example included
- **Cons**: 
  - May need customization for game-like features
  - No built-in noise suppression

### 2. Tuna (alladinian/Tuna)
- **Stars**: 44
- **License**: MIT
- **Language**: Swift 5+
- **Last Updated**: Moderately active
- **Algorithms**: Based on Beethoven - YIN, HPS, Quadratic, Quinn's estimators
- **Integration Effort**: Low-Medium - Modern Swift implementation
- **Expected Benefit**: High - Updated for Swift 5, cleaner API
- **Pros**:
  - Modern Swift 5 implementation
  - Based on proven Beethoven algorithms
  - Cleaner, more maintainable codebase
  - Swift Package Manager support
- **Cons**:
  - Smaller community
  - Less battle-tested than Beethoven

### 3. SwiftBSAC (lancylot2004/SwiftBSAC)
- **Stars**: 1
- **License**: Not specified (appears open source)
- **Language**: Swift
- **Last Updated**: Recent (Jan 2024)
- **Algorithms**: Bitstream Autocorrelation (BSAC)
- **Integration Effort**: Low - Simple implementation
- **Expected Benefit**: Medium - Fast algorithm, good for real-time
- **Pros**:
  - Fast execution
  - Low CPU usage
  - Simple implementation
- **Cons**:
  - Limited algorithm variety
  - Minimal documentation
  - Small community
  - Unknown license status

### 4. Current Implementation (AudioTuner.swift)
- **Algorithms**: Basic autocorrelation with vDSP
- **Integration Effort**: None - already implemented
- **Expected Benefit**: Low - Basic functionality only
- **Pros**:
  - Already integrated
  - Uses Accelerate framework
- **Cons**:
  - Simple autocorrelation only
  - No noise handling
  - Limited accuracy
  - No advanced algorithms

## Noise Suppression Solutions

### 1. AVAudioSession Voice Processing
- **Availability**: Built into iOS
- **License**: Apple frameworks
- **Integration Effort**: Low - Configuration only
- **Expected Benefit**: Medium-High - Hardware-accelerated, battery efficient
- **Implementation**: Use `.voiceChat` mode with voice processing I/O
- **Pros**:
  - Hardware accelerated
  - Battery efficient
  - No additional dependencies
  - Proven noise reduction
- **Cons**:
  - May introduce pitch bias
  - Limited customization
  - iOS-specific

### 2. AVAudioSession Measurement Mode
- **Availability**: Built into iOS
- **License**: Apple frameworks  
- **Integration Effort**: Low - Configuration only
- **Expected Benefit**: Medium - Minimal processing, accurate
- **Implementation**: Use `.measurement` mode for raw audio
- **Pros**:
  - Minimal processing
  - Most accurate for pitch detection
  - Low latency
- **Cons**:
  - No noise suppression
  - Requires manual noise handling

### 3. Custom Spectral Subtraction
- **Availability**: Custom implementation needed
- **License**: Custom code
- **Integration Effort**: High - Full implementation required
- **Expected Benefit**: Medium - Customizable but complex
- **Pros**:
  - Full control over algorithm
  - Tunable for guitar frequencies
- **Cons**:
  - High development effort
  - Potential performance impact
  - Requires extensive testing

## Visualization Libraries

### 1. SwiftUI + Metal (for particles)
- **Availability**: Built into iOS
- **License**: Apple frameworks
- **Integration Effort**: Medium - Custom particle system needed
- **Expected Benefit**: High - 120Hz ProMotion support, hardware accelerated
- **Pros**:
  - Hardware accelerated
  - 120Hz support
  - Native integration
- **Cons**:
  - Requires Metal knowledge
  - Complex particle system implementation

### 2. SwiftUI Only
- **Availability**: Built into iOS
- **License**: Apple frameworks
- **Integration Effort**: Low - Built-in animations
- **Expected Benefit**: Medium - Good performance, easier implementation
- **Pros**:
  - Simple implementation
  - Good performance
  - Native animations
- **Cons**:
  - Limited to 60Hz on non-ProMotion devices
  - Less sophisticated particle effects

## Recommended Technology Stack

### Primary Pitch Detection: Tuna
- Modern Swift 5 implementation
- Multiple robust algorithms (YIN, HPS, Quinn's)
- MIT license
- Clean API for easy integration

### Fallback Pitch Detection: Beethoven
- If Tuna integration issues arise
- More battle-tested
- Larger community

### Noise Suppression: Hybrid Approach
1. **Primary**: AVAudioSession measurement mode for accuracy
2. **Fallback**: Voice processing mode for noisy environments
3. **A/B testing**: Compare both approaches with metrics

### Visualization: SwiftUI + Optional Metal
- Start with SwiftUI-only implementation
- Add Metal particle system if performance requires it
- Target 120Hz on ProMotion devices

### Audio Processing: AVAudioEngine + Accelerate
- 48kHz preferred, 44.1kHz fallback
- vDSP for FFT operations
- Real-time safe audio callbacks

## Implementation Priority

1. **Phase 1**: Integrate Tuna for multiple pitch detection algorithms
2. **Phase 2**: Implement game-like SwiftUI interface with radial gauge
3. **Phase 3**: Add noise suppression comparison (measurement vs voice processing)
4. **Phase 4**: Optimize performance and add haptics
5. **Phase 5**: Add Metal particle system if needed for 120Hz
6. **Phase 6**: Comprehensive testing and benchmarking

## Risk Assessment

### Low Risk
- SwiftUI interface implementation
- Basic haptics integration
- Settings bundle configuration

### Medium Risk  
- Tuna/Beethoven integration complexity
- Performance optimization for real-time constraints
- Noise suppression effectiveness

### High Risk
- Meeting latency requirements (≤40ms on iPhone 12+)
- Achieving accuracy targets in noisy environments
- Metal particle system complexity (if required)

## Success Metrics Mapping

| Requirement | Technology Solution | Risk Level |
|-------------|-------------------|------------|
| ≤40ms latency | Tuna + optimized audio pipeline | Medium |
| ≤±1 cent accuracy | YIN/HPS algorithms + measurement mode | Low |
| ≤±3 cents with noise | Voice processing mode fallback | Medium |
| ≤15% CPU on A15 | Accelerate framework + optimization | Medium |
| Game-like visuals | SwiftUI + optional Metal | Low-Medium |
| Zero-interaction UI | SwiftUI state management | Low |
| 120Hz particles | Metal compute shaders | High |
