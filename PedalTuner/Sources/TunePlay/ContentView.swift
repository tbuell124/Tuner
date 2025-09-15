#if canImport(SwiftUI)
import SwiftUI

struct ContentView: View {
    @StateObject private var tuner = AudioTuner()

    var body: some View {
        GameTunerView(
            note: tuner.note,
            cents: tuner.cents,
            confidence: tuner.confidence,
            isStable: tuner.isStable,
            detectedString: tuner.detectedString
        )
        .onAppear { 
            tuner.start() 
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
}
#endif
