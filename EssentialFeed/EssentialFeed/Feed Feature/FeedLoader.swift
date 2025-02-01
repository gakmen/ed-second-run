public protocol FeedLoader {
  func load() async throws -> [FeedItem]
}
