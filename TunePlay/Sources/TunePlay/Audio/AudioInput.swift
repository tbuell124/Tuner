import Foundation
import AVFoundation

final class AudioInput: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioSession: AVAudioSession
    private var isConfigured = false
    
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    
    init() {
        self.audioSession = AVAudioSession.sharedInstance()
    }
    
    func configure() throws {
        guard !isConfigured else { return }
        
        try configureAudioSession()
        try setupAudioEngine()
        
        isConfigured = true
    }
    
    private func configureAudioSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try audioSession.setPreferredSampleRate(48000)
        try audioSession.setPreferredIOBufferDuration(0.005)
        try audioSession.setActive(true)
    }
    
    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { throw AudioInputError.engineCreationFailed }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { throw AudioInputError.inputNodeNotFound }
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let bufferSize: AVAudioFrameCount = 2048
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.onAudioBuffer?(buffer)
        }
        
        try audioEngine.start()
    }
    
    func start() throws {
        if !isConfigured {
            try configure()
        }
        
        guard let audioEngine = audioEngine else { throw AudioInputError.engineNotConfigured }
        
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
    }
    
    func stop() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
    }
    
    func switchToVoiceProcessingMode() throws {
        stop()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        try setupAudioEngine()
    }
    
    func switchToMeasurementMode() throws {
        stop()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        try setupAudioEngine()
    }
}

enum AudioInputError: Error {
    case engineCreationFailed
    case inputNodeNotFound
    case engineNotConfigured
    case sessionConfigurationFailed
}
