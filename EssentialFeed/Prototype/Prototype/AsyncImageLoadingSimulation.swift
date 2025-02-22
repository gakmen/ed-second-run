import SwiftUI

struct AsyncLoadingSimulation: ViewModifier {
  @State private var overlayOpacity: Double = 1.0

  func body(content: Content) -> some View {
    content
      .overlay { Color.gray.opacity(overlayOpacity) }
      .clipShape(RoundedRectangle(cornerRadius: 22))
      .onAppear { withAnimation(.easeInOut(duration: 0.7)) { overlayOpacity = 0 } }
  }
}

extension View {
  func simulateImageLoading() -> some View {
    self.modifier(AsyncLoadingSimulation())
  }
}
