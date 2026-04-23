import SwiftUI

struct WavingLogoView: View {
    @State private var wave = false

    var body: some View {
        BlueBotGraduationLogoView()
            .frame(width: 96, height: 96)
            .rotationEffect(.degrees(wave ? 8 : -8), anchor: .bottomLeading)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: wave)
            .onAppear { wave = true }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.16))
            )
            .accessibilityHidden(true)
    }
}

struct BlueBotGraduationLogoView: View {
    private let darkBlue = Color(red: 0.08, green: 0.18, blue: 0.36)
    private let midBlue  = Color(red: 0.15, green: 0.30, blue: 0.58)
    private let lightBlue = Color(red: 0.75, green: 0.86, blue: 1.0)
    private let gold = Color(red: 0.96, green: 0.78, blue: 0.20)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: s * 0.5, y: s * 0.62)

            ZStack {
                //(cap) - dark blue
                Path { p in
                    p.move(to: CGPoint(x: s * 0.50, y: s * 0.08))
                    p.addLine(to: CGPoint(x: s * 0.88, y: s * 0.22))
                    p.addLine(to: CGPoint(x: s * 0.50, y: s * 0.36))
                    p.addLine(to: CGPoint(x: s * 0.12, y: s * 0.22))
                    p.closeSubpath()
                }
                .fill(darkBlue)

                RoundedRectangle(cornerRadius: s * 0.02, style: .continuous)
                    .fill(midBlue)
                    .frame(width: s * 0.54, height: s * 0.06)
                    .position(x: s * 0.50, y: s * 0.40)

                // Tassel - gold
                Path { p in
                    p.move(to: CGPoint(x: s * 0.80, y: s * 0.24))
                    p.addLine(to: CGPoint(x: s * 0.80, y: s * 0.50))
                }
                .stroke(gold, style: StrokeStyle(lineWidth: s * 0.028, lineCap: .round))
                Circle()
                    .fill(gold)
                    .frame(width: s * 0.08, height: s * 0.08)
                    .position(x: s * 0.80, y: s * 0.54)

                // Head - circular robot with ring
                Circle()
                    .fill(darkBlue)
                    .frame(width: s * 0.72, height: s * 0.72)
                    .position(center)
                    .overlay(
                        Circle()
                            .stroke(midBlue, lineWidth: s * 0.04)
                    )

                // Face visor
                Circle()
                    .fill(midBlue)
                    .frame(width: s * 0.54, height: s * 0.54)
                    .position(center)
                    .overlay(
                        Circle()
                            .stroke(lightBlue.opacity(0.7), lineWidth: s * 0.02)
                    )

                // Eyes
                HStack(spacing: s * 0.16) {
                    Circle().fill(.green)
                        .frame(width: s * 0.10, height: s * 0.10)
                    Circle().fill(.green)
                        .frame(width: s * 0.10, height: s * 0.10)
                }
                .position(x: center.x, y: center.y - s * 0.08)

                // Smile
                Capsule(style: .continuous)
                    .fill(lightBlue)
                    .frame(width: s * 0.17, height: s * 0.15)
                    .position(x: center.x, y: center.y + s * 0.10)

                // Ears/antennas
                Capsule(style: .continuous)
                    .fill(darkBlue)
                    .frame(width: s * 0.06, height: s * 0.18)
                    .position(x: center.x - s * 0.42, y: center.y)
                Capsule(style: .continuous)
                    .fill(darkBlue)
                    .frame(width: s * 0.06, height: s * 0.18)
                    .position(x: center.x + s * 0.42, y: center.y)

                // Small antenna on top
                RoundedRectangle(cornerRadius: s * 0.02, style: .continuous)
                    .fill(darkBlue)
                    .frame(width: s * 0.08, height: s * 0.12)
                    .position(x: s * 0.50, y: s * 0.43)
                Circle()
                    .fill(gold)
                    .frame(width: s * 0.06, height: s * 0.06)
                    .position(x: s * 0.50, y: s * 0.36)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct GraduationRobotLogoView: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let centerX = s * 0.5

            ZStack {
                // Graduation cap
                Path { p in
                    p.move(to: CGPoint(x: centerX, y: s * 0.08))
                    p.addLine(to: CGPoint(x: s * 0.86, y: s * 0.20))
                    p.addLine(to: CGPoint(x: centerX, y: s * 0.32))
                    p.addLine(to: CGPoint(x: s * 0.14, y: s * 0.20))
                    p.closeSubpath()
                }
                .fill(Color.white)
                .opacity(0.95)

                // Cap band
                RoundedRectangle(cornerRadius: s * 0.02, style: .continuous)
                    .fill(Color.white)
                    .frame(width: s * 0.52, height: s * 0.06)
                    .position(x: centerX, y: s * 0.36)

                // Tassel
                Path { p in
                    p.move(to: CGPoint(x: s * 0.78, y: s * 0.22))
                    p.addLine(to: CGPoint(x: s * 0.78, y: s * 0.48))
                }
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
                Circle()
                    .fill(Color.yellow)
                    .frame(width: s * 0.08, height: s * 0.08)
                    .position(x: s * 0.78, y: s * 0.52)

                // Robot head
                RoundedRectangle(cornerRadius: s * 0.14, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: s * 0.74, height: s * 0.54)
                    .position(x: centerX, y: s * 0.68)
                    .overlay(
                        RoundedRectangle(cornerRadius: s * 0.14, style: .continuous)
                            .stroke(Color.white, lineWidth: s * 0.035)
                    )

                // Eyes
                HStack(spacing: s * 0.18) {
                    Circle().fill(Color.white)
                        .frame(width: s * 0.10, height: s * 0.10)
                    Circle().fill(Color.white)
                        .frame(width: s * 0.10, height: s * 0.10)
                }
                .position(x: centerX, y: s * 0.60)

                // Mouth
                RoundedRectangle(cornerRadius: s * 0.05, style: .continuous)
                    .stroke(Color.white, lineWidth: s * 0.03)
                    .frame(width: s * 0.36, height: s * 0.10)
                    .position(x: centerX, y: s * 0.78)

                // Side ears
                Capsule(style: .continuous)
                    .fill(Color.white)
                    .frame(width: s * 0.06, height: s * 0.18)
                    .position(x: s * 0.13, y: s * 0.68)
                Capsule(style: .continuous)
                    .fill(Color.white)
                    .frame(width: s * 0.06, height: s * 0.18)
                    .position(x: s * 0.87, y: s * 0.68)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct DynamicLogoMessageView: View {
    @State private var index: Int = 0
    private let messages = [
        "Click on me",
        "Let's study",
        "How are you?",
        "Are you lost again?"
    ]

    var body: some View {
        Text(messages[index])
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.18))
            )
            .onAppear {
                // Rotate every 2.5 seconds
                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        index = (index + 1) % messages.count
                    }
                }
            }
    }
}


