import SwiftUI
import EssentialFeed

public struct FeedView: View {
  @State public var loader: FeedLoader
  @State public var feed: [FeedItem]?
  @State private var loadingIndicatorOpacity: CGFloat = 1
  public var onDidAppear: ((Self) -> Void)?
  public var onFeedChange: ((Self) -> Void)?
  public var onFinishRefreshing: ((Self) -> Void)?

  public init(loader: FeedLoader) {
    self.loader = loader
  }

  public var body: some View {
    NavigationView {
      List {}
        .refreshable(action: refresh)
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
      feed = try await loader.load()
      withAnimation { loadingIndicatorOpacity = 0 }
      self.onFinishRefreshing?(self)
    } catch {}
  }
}
