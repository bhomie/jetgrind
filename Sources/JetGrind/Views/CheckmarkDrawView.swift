import SwiftUI

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Checkmark: start bottom-left, dip to bottom-center, rise to top-right
        path.move(to: CGPoint(x: rect.width * 0.15, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.width * 0.85, y: rect.height * 0.2))
        return path
    }
}

struct CheckmarkDrawView: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        CheckmarkShape()
            .trim(from: 0, to: progress)
            .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    progress = 1
                }
            }
    }
}
