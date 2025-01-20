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

private enum FeedItemsMapper {
  static func map(_ response: HTTPClientResponse) throws -> [FeedItem] {
    guard
      response.0.statusCode == 200,
      let root = try? JSONDecoder().decode(Root.self, from: response.1)
    else { throw RemoteFeedLoader.Error.invalidData }

    return root.feedItems
  }

  private struct Root: Decodable {
    let items: [Item]
    var feedItems: [FeedItem] {
      items.map { $0.feedItem }
    }
  }

  private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL

    var feedItem: FeedItem {
      return FeedItem(id: id, description: description, location: location, imageURL: image)
    }
  }
}
