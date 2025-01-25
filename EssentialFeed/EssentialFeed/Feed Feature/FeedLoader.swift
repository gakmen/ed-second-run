public protocol FeedLoader {
  func load() throws -> [FeedItem]
}
