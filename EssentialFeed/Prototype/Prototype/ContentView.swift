import SwiftUI

struct ContentView: View {
  init() {
    let appearance = {
      $0.configureWithOpaqueBackground()
      $0.backgroundColor = UIColor.systemBackground
      $0.shadowColor = UIColor.systemGray2
      return $0
    }(UINavigationBarAppearance())

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
  }

  var body: some View {
    NavigationView {
      Text("")
        .toolbar {
          ToolbarItem(placement: .principal) {
            Text("My Feed")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.primary)
          }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}

struct FeedImageCell: View {
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Image(.pin)
          .padding(.top, 2)
        Text("Location, Location")
          .foregroundStyle(.secondary)
        Spacer()
      }
      GeometryReader {
        let squareSize = $0.size.width
        RoundedRectangle(cornerRadius: 20)
          .foregroundStyle(.tertiary)
          .frame(width: squareSize, height: squareSize)
      }
      .aspectRatio(1, contentMode: .fit)
      Text("Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description ")
        .lineLimit(6)
    }
    .padding(.horizontal, 16)
  }
}

#Preview {
  FeedImageCell()
}
