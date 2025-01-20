import Foundation

enum FeedItemsMapper {
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
