#if canImport(SwiftUI)
import SwiftUI

struct TunerView: View {
    var note: String
    var cents: Double // +/- cents offset

    private var angle: Double {
        cents * 0.9 // map cents to angle (~0.9 degrees per cent)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.teal, .blue]),
                        center: .center
                    ),
                    lineWidth: 16
                )
                .padding(40)

            Capsule()
                .fill(Color.white)
                .frame(width: 4, height: 120)
                .offset(y: -60)
                .rotationEffect(.degrees(angle))
                .animation(.linear(duration: 0.1), value: angle)

            Text(note)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
#endif
