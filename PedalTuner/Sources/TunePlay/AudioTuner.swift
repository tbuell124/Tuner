#if canImport(AVFoundation)
import AVFoundation
import Accelerate
import SwiftUI

final class AudioTuner: ObservableObject {
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()

    @Published var note: String = "--"
    @Published var cents: Double = 0

    func start() {
        configureSession()
        let input = engine.inputNode
        let bus = 0
        let format = input.outputFormat(forBus: bus)

        input.installTap(onBus: bus, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        do {
            try engine.start()
        } catch {
            print("Engine start error: \(error)")
        }
    }

    private func configureSession() {
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Session error: \(error)")
        }
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?.pointee else { return }
        let frameLength = Int(buffer.frameLength)
        var autocorr = [Float](repeating: 0, count: frameLength)
        vDSP_conv(channelData, 1, channelData, 1, &autocorr, 1, vDSP_Length(frameLength), vDSP_Length(frameLength))

        var maxIndex = 0
        var maxValue: Float = 0
        for lag in 1..<frameLength {
            let value = autocorr[lag]
            if value > maxValue {
                maxValue = value
                maxIndex = lag
            }
        }

        let sampleRate = buffer.format.sampleRate
        let frequency = sampleRate / Double(maxIndex)
        updateDisplay(frequency: frequency)
    }

    private func updateDisplay(frequency: Double) {
        guard frequency > 0 && frequency.isFinite else { return }
        let a4 = 440.0
        let noteNumber = 12 * log2(frequency / a4) + 69
        let rounded = Int(round(noteNumber))
        let noteIndex = (rounded + 1200) % 12
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let diff = noteNumber - Double(rounded)
        DispatchQueue.main.async {
            self.note = names[noteIndex]
            self.cents = diff * 100
        }
    }
}
#else
final class AudioTuner {
    var note: String = "--"
    var cents: Double = 0
    func start() { }
}
#endif
