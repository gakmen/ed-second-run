import Foundation

public typealias HTTPClientResponse = (HTTPURLResponse, Data)

public protocol HTTPClient {
  func get(from url: URL) throws -> HTTPClientResponse
}

public final class RemoteFeedLoader {
  private let url: URL
  private let client: HTTPClient

  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  public func load() throws {
    do {
      _ = try client.get(from: url)
    } catch {
      throw Error.connectivity
    }
    throw Error.invalidData
  }

  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
}
