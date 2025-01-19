import EssentialFeed
import Foundation
import Testing

struct RemoteFeedLoaderTests {
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
    let emptyJSON = "{\"items\": []}".data(using: .utf8)!
    client.stubResponse(
      makeResponse(from: someURL, and: 200),
      emptyJSON
    )

    let capturedResult = loadAndCaptureResult(for: sut)

    #expect(capturedResult == [.success([])])
  }

  // MARK: - Helpers

  private func makeSUT(
    url: URL = URL(string: "https://a-url.ru")!
  ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
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
