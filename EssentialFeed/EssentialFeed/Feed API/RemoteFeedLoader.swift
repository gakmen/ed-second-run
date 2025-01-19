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

  public func load() throws -> Result {
    var response: HTTPClientResponse?
    do {
      response = try client.get(from: url)
    } catch {
      throw Error.connectivity
    }
    guard
      let response,
      response.0.statusCode == 200,
      let _ = try? JSONSerialization.jsonObject(with: response.1)
    else {
      throw Error.invalidData
    }
    
    return .success([])
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
