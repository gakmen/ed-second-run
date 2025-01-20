import Foundation

public final class RemoteFeedLoader {
  private let url: URL
  private let client: HTTPClient

  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load() throws -> Result {
    var response: HTTPClientResponse?
    do {
      response = try client.get(from: url)
    } catch { throw Error.connectivity }

    guard let response else { throw Error.invalidData }

    return .success(try FeedItemsMapper.map(response))
  }

  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }

  public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
  }
}
