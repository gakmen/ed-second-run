import SwiftUI

struct FeedImageViewModel {
  let description: String?
  let location: String?
  let imageName: String
}

struct FeedView: View {
  init() {
    let appearance = {
      $0.configureWithOpaqueBackground()
      $0.backgroundColor = UIColor.systemGray6
      $0.shadowColor = UIColor.systemGray3
      return $0
    }(UINavigationBarAppearance())

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
  }

  var body: some View {
    NavigationView {
      List {
        Spacer()
          .frame(height: 10)
          .listRowSeparator(.hidden)
        ForEach(FeedImageViewModel.prototypeFeed, id: \.self) {
          FeedImageCell(image: $0.imageName, location: $0.location, description: $0.description)
            .listRowSeparator(.hidden)
        }
        Spacer()
          .listRowSeparator(.hidden)
      }
      .listStyle(.plain)
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
  let image: String
  let location: String?
  let description: String?

  init(image: String, location: String?, description: String?) {
    self.image = image
    self.location = location
    self.description = description
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let location {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Image(.pin)
            .offset(y: 3)
          Text(location)
          .font(.system(size: 15))
          .foregroundStyle(.tertiary)
          .lineLimit(2)
          Spacer()
        }
      }

      GeometryReader { geometry in
        let squareSide = geometry.size.width
        Image(.init(stringLiteral: image))
          .resizable()
          .scaledToFill()
          .frame(width: squareSide, height: squareSide)
          .simulateImageLoading()
      }
      .aspectRatio(1, contentMode: .fit)

      if let description {
        Text(description)
          .lineLimit(6)
          .font(.system(size: 16))
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  FeedView()
}
