#if canImport(SwiftUI)
import SwiftUI

struct ContentView: View {
    @StateObject private var tuner = AudioTuner()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                TunerView(note: tuner.note, cents: tuner.cents)
                Spacer()
            }
        }
        .onAppear { tuner.start() }
    }
}
#endif
