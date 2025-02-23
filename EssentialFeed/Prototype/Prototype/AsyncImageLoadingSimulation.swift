import SwiftUI

struct AsyncLoadingSimulation: ViewModifier {
  @State private var overlayOpacity: Double = 1
  @State private var positionX: CGFloat = 0
  @State private var size: CGSize = .zero

  func body(content: Content) -> some View {
    content
      .background(GeometryReader { geometry in
        Color.clear
          .onAppear {
            size = geometry.size
            positionX = -geometry.size.width
          }
      })
      .overlay(Color.gray.opacity(overlayOpacity))
      .overlay(
        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [Color.gray, Color.white.opacity(0.05), Color.gray]),
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .opacity(overlayOpacity)
          .frame(width: size.height * sqrt(2) / 3, height: size.height * sqrt(2) + 200)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          .rotationEffect(.degrees(45))
          .offset(x: positionX)
      )
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .onAppear {
        withAnimation(.linear(duration: 0.7).repeatCount(3, autoreverses: false)) {
          positionX = size.width
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
