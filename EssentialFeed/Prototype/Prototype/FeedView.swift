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
          .listRowSeparator(.hidden)
        FeedImageCell()
          .listRowSeparator(.hidden)
        FeedImageCell()
          .listRowSeparator(.hidden)
        FeedImageCell()
          .listRowSeparator(.hidden)
        FeedImageCell()
          .listRowSeparator(.hidden)
        FeedImageCell()
          .listRowSeparator(.hidden)
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
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Image(.pin)
          .offset(y: 3)
        Text(
          """
          Location,
          Location
          """
        )
        .font(.system(size: 15))
        .foregroundStyle(.tertiary)
        .lineLimit(2)
        Spacer()
      }

      GeometryReader {
        let squareSize = $0.size.width
        RoundedRectangle(cornerRadius: 22)
          .foregroundStyle(.quaternary)
          .frame(width: squareSize, height: squareSize)
      }
      .aspectRatio(1, contentMode: .fit)

      Text("Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description Description ")
        .lineLimit(6)
        .font(.system(size: 16))
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  FeedView()
}
