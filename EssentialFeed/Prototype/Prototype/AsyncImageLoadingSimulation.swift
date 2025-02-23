import SwiftUI

struct AsyncLoadingSimulation: ViewModifier {
  @State private var overlayOpacity: Double = 1
  @State private var positionX: CGFloat = -350

  func body(content: Content) -> some View {
    let gradient = LinearGradient(
      gradient: Gradient(
        colors: [Color.gray, Color.white.opacity(0.05), Color.gray]
      ),
      startPoint: .leading,
      endPoint: .trailing
    )
    content
      .overlay(Color.gray.opacity(overlayOpacity))
      .overlay(
        Rectangle()
          .fill(gradient)
          .opacity(overlayOpacity)
          .frame(width: 200, height: 600)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          .rotationEffect(.degrees(45))
          .offset(x: positionX)
      )
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .onAppear {
        withAnimation(.linear(duration: 0.7).repeatCount(3, autoreverses: false)) {
          positionX = 350
        }

        let shimmerDuration = 0.7 * 3
        DispatchQueue.main.asyncAfter(deadline: .now() + shimmerDuration) {
          withAnimation(.easeInOut(duration: 0.5)) {
            overlayOpacity = 0
          }
        }
      }
  }
}

extension View {
  func simulateImageLoading() -> some View {
    self.modifier(AsyncLoadingSimulation())
  }
}
