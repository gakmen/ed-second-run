import Foundation

public final class RemoteFeedLoader: FeedLoader {
  private let url: URL
  private let client: HTTPClient

  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load() async throws -> [FeedItem] {
    let response: HTTPClientResponse
    do {
      response = try await client.get(from: url)
    } catch { throw Error.connectivity }

    return try FeedItemsMapper.map(response)
  }

  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
}
