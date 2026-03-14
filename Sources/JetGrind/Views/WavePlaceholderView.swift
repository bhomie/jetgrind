import SwiftUI

struct WavePlaceholderView: View {
    let isFocused: Bool

    private let text = Array("Add a task...")
    private let waveSpeed: Double = 20
    private let sigma: Double = 1.5
    private let amplitude: CGFloat = 4
    private let pauseDuration: Double = 1.25
    private let settleDuration: Double = 0.3

    private var traversalDuration: Double {
        (Double(text.count) + 4 * sigma) / waveSpeed
    }

    private var cycleDuration: Double {
        traversalDuration + pauseDuration
    }

    @State private var waveStart: Date = .now
    @State private var settleStart: Date? = nil
    @State private var animating = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animating)) { context in
            let elapsed = animating ? context.date.timeIntervalSince(waveStart) : 0
            let phase = elapsed.truncatingRemainder(dividingBy: cycleDuration)
            let wavePeak = phase * waveSpeed - 2 * sigma

            let settleDecay: Double = if let settleStart {
                max(0, 1 - context.date.timeIntervalSince(settleStart) / settleDuration)
            } else if animating {
                1
            } else {
                0
            }

            HStack(spacing: 0) {
                ForEach(0..<text.count, id: \.self) { i in
                    let distance = Double(i) - wavePeak
                    let rawBump = phase < traversalDuration
                        ? exp(-distance * distance / (2 * sigma * sigma))
                        : 0
                    let bump = rawBump * settleDecay

                    Text(String(text[i]))
                        .font(.system(size: Theme.Font.body))
                        .foregroundStyle(.secondary)
                        .overlay {
                            Text(String(text[i]))
                                .font(.system(size: Theme.Font.body))
                                .foregroundStyle(Theme.Pastel.color(for: i))
                                .opacity(bump)
                        }
                        .offset(y: -amplitude * bump)
                }
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                settleStart = nil
                waveStart = .now
                animating = true
            } else if animating {
                settleStart = .now
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(Int(settleDuration * 1000)))
                    if !isFocused {
                        animating = false
                        settleStart = nil
                    }
                }
            }
        }
    }
}
