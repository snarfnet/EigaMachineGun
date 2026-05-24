import SwiftUI

struct SpeedControlView: View {
    let speed: Double
    let isPlaying: Bool
    let onSpeedChange: (Double) -> Void
    let onTogglePlay: () -> Void

    private let minSpeed: Double = 1.0
    private let maxSpeed: Double = 15.0

    var speedLabel: String {
        if speed < 2 {
            return "RAPID FIRE"
        } else if speed < 4 {
            return "FULL AUTO"
        } else if speed < 7 {
            return "BURST"
        } else if speed < 11 {
            return "SEMI AUTO"
        } else {
            return "SINGLE"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Speed label
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text(speedLabel)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                }

                Spacer()

                Text(String(format: "%.1fs", speed))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Slider + Play button
            HStack(spacing: 12) {
                // Play/Pause
                Button(action: onTogglePlay) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(isPlaying ? Color.red : Color.white)
                        )
                }

                // Speed slider
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Filled portion
                    GeometryReader { geo in
                        let ratio = (speed - minSpeed) / (maxSpeed - minSpeed)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * ratio, height: 8)
                    }
                    .frame(height: 8)

                    // Slider
                    Slider(value: Binding(
                        get: { speed },
                        set: { onSpeedChange($0) }
                    ), in: minSpeed...maxSpeed, step: 0.5)
                    .tint(.clear)
                }

                // Bullet indicators
                HStack(spacing: 3) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(bulletColor(index: i))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func bulletColor(index: Int) -> Color {
        let threshold = Int((1.0 - (speed - minSpeed) / (maxSpeed - minSpeed)) * 5)
        return index < threshold ? .red : .white.opacity(0.2)
    }
}
