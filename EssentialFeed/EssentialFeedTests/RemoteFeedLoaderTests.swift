import EssentialFeed
import Foundation
import Testing

final class RemoteFeedLoaderTests {
  var memoryLeaksTracker: () -> Void = {}

  deinit {
    memoryLeaksTracker()
  }

  @Test func init_doesNotRequestDataFromURL() {
    let (_, client) = makeSUT()

    #expect(client.requestedURLs.isEmpty)
  }

  @Test func load_requestsDataFromURL() {
    let (sut, client) = makeSUT(url: someURL)

    _ = try? sut.load()

    #expect(client.requestedURLs == [someURL])
  }

  @Test func loadTwice_requestsDataFromURLTwice() {
    let (sut, client) = makeSUT(url: someURL)

    _ = try? sut.load()
    _ = try? sut.load()

    #expect(client.requestedURLs == [someURL, someURL])
  }

  @Test func load_deliversErrorOnClientError() {
    let (sut, _) = makeSUT()

    let capturedErrors = loadAndCaptureResult(for: sut)

    #expect(capturedErrors == [.failure(.connectivity)])
  }

  @Test(arguments: [199, 201, 300, 400, 500])
  func load_deliversErrorOnNon200HTTPResponse(code: Int) {
    let (sut, client) = makeSUT()
    client.stubResponse(
      makeResponse(from: someURL, and: code),
      someData
    )

    let capturedErrors = loadAndCaptureResult(for: sut)

    #expect(capturedErrors == [.failure(.invalidData)])
  }

  @Test func load_deliversErrorOn200HTTPResponseWithInvalidData() {
    let (sut, client) = makeSUT()
    client.stubResponse(
      makeResponse(from: someURL, and: 200),
      invalidJSONData
    )

    let capturedErrors = loadAndCaptureResult(for: sut)

    #expect(capturedErrors == [.failure(.invalidData)])
  }

  @Test func load_deliversNoItemsOn200HTTPResponseWithEmptyJSON() {
    let (sut, client) = makeSUT()
    let emptyJSON = makeItemsJSON([])
    client.stubResponse(
      makeResponse(from: someURL, and: 200),
      emptyJSON
    )

    let capturedResult = loadAndCaptureResult(for: sut)

    #expect(capturedResult == [.success([])])
  }

  @Test func load_deliversFeedItemsOn200HTTPResponseWithValidJSON() {
    let (sut, client) = makeSUT()
    let item1 = makeItem(id: UUID(), imageURL: URL(string: "https://image1.ru")!)
    let item2 = makeItem(
      id: UUID(),
      description: "a description",
      location: "a location",
      imageURL: URL(string: "https://image2.ru")!
    )
    let itemsJSON = makeItemsJSON([item1.json, item2.json])
    client.stubResponse(
      makeResponse(from: someURL, and: 200),
      itemsJSON
    )

    let capturedResult = loadAndCaptureResult(for: sut)
    let items = [item1.model, item2.model]

    #expect(capturedResult == [.success(items)])
  }

  // MARK: - Helpers

  private func makeSUT(
    url: URL = URL(string: "https://a-url.ru")!
  ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    memoryLeaksTracker = { [weak client, weak sut] in
      #expect(client == nil)
      #expect(sut == nil)
    }

    return (sut, client)
  }

  private let someURL = URL(string: "https://some-url.ru")!
  private let someData = "Some data".data(using: .utf8)!
  private let invalidJSONData = "Invalid JSON".data(using: .utf8)!

  private func makeResponse(from url: URL, and code: Int) -> HTTPURLResponse {
    HTTPURLResponse(
      url: url,
      statusCode: code,
      httpVersion: nil,
      headerFields: nil
    )!
  }

  private func makeItem(
    id: UUID,
    description: String? = nil,
    location: String? = nil,
    imageURL: URL
  ) -> (model: FeedItem, json: [String: Any]) {
    let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)

    let json = [
      "id": id.uuidString,
      "description": description,
      "location": location,
      "image": imageURL.absoluteString
    ].reduce(into: [String: Any]()) { (acc, e) in
      if let value = e.value { acc[e.key] = value }
    }

    return (item, json)
  }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
      let json = ["items": items]
      return try! JSONSerialization.data(withJSONObject: json)
    }

  private func loadAndCaptureResult(for sut: RemoteFeedLoader) -> [RemoteFeedLoader.Result] {
    var capturedResult = [RemoteFeedLoader.Result]()
    do {
      capturedResult.append(try sut.load())
    } catch let error as RemoteFeedLoader.Error {
      capturedResult.append(.failure(error))
    } catch {}

    return capturedResult
  }

  private class HTTPClientSpy: HTTPClient {
    var requestedURLs = [URL]()
    private var receivedResponses = ([HTTPURLResponse](), [Data]())

    func stubResponse(_ response: HTTPURLResponse, _ data: Data) {
      receivedResponses.0.append(response)
      receivedResponses.1.append(data)
    }

    func get(from url: URL) throws -> HTTPClientResponse {
      requestedURLs.append(url)
      guard let firstResponse = receivedResponses.0.first, let firstData = receivedResponses.1.first
      else {
        throw NSError(domain: "HTTPClientSpy error", code: 0)
      }
      return (firstResponse, firstData)
    }
  }

}
