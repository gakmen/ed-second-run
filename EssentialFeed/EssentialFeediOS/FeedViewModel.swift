import EssentialFeed

final public class FeedViewModel {
  public var loader: FeedLoader
  public var showLoadingIndicator: Bool = true
  public var feed = [FeedItem]()

  public init(loader: FeedLoader) {
    self.loader = loader
  }

  public func refresh() async {
    do {
      feed = try await loader.load()
    } catch {}
      
    showLoadingIndicator = false
  }
}
