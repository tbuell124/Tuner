#if canImport(SwiftUI)
import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @StateObject private var tuner = AudioTuner()

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some View {
        ZStack {
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
            
            AdBannerViewContainer()
        }
    }
}
#endif
