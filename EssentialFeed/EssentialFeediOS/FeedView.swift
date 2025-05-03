import Combine
import SwiftUI
import EssentialFeed

final public class FeedViewModel: ObservableObject {
  public var loader: FeedLoader

  public init(loader: FeedLoader) {
    self.loader = loader
  }
}

public struct FeedView: View {
  public var loader: FeedLoader
  @State public var feed: [FeedItem]?
  @State private var loadingIndicatorOpacity: CGFloat = 1
  public var onDidAppear: ((Self) -> Void)?
  public var onFinishRefreshing: ((Self) -> Void)?

  public init(loader: FeedLoader) {
    self.loader = loader
  }

  public var body: some View {
    NavigationView {
      List {
        ForEach(feed ?? [], id: \.self) { item in
          VStack(alignment: .leading, spacing: 10) {
            if let location = item.location {
              HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(location)
                  .id("location")
                  .font(.system(size: 15))
                  .foregroundStyle(.tertiary)
                  .lineLimit(2)
                Spacer()
              }
            }

            if let description = item.description {
              Text(description)
                .id("description")
                .lineLimit(6)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .refreshable(action: refresh)
      .listStyle(.plain)
      .overlay {
        ProgressView()
          .id("loading indicator")
          .opacity(loadingIndicatorOpacity)
      }
    }
    .onAppear {
      Task {
        self.onDidAppear?(self)
        await refresh()
      }
    }
  }

  @Sendable
  public func refresh() async {
    do {
      let newFeed = try await loader.load()
      feed = newFeed
      withAnimation { loadingIndicatorOpacity = 0 }
      self.onFinishRefreshing?(self)
    } catch {}
  }
}
