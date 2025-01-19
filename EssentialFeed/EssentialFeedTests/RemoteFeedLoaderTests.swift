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

    try? sut.load()

    #expect(client.requestedURLs == [someURL])
  }

  @Test func loadTwice_requestsDataFromURLTwice() {
    let (sut, client) = makeSUT(url: someURL)

    try? sut.load()
    try? sut.load()

    #expect(client.requestedURLs == [someURL, someURL])
  }

  @Test func load_deliversErrorOnClientError() {
    let (sut, _) = makeSUT()

    let capturedErrors = loadAndCaptureResult(for: sut)

    #expect(capturedErrors == [.connectivity])
  }

  @Test(arguments: [199, 201, 300, 400, 500])
  func load_deliversErrorOnNon200HTTPResponse(code: Int) {
    let (sut, client) = makeSUT(url: someURL)
    client.stubResponse(
      makeResponse(from: someURL, and: code),
      someData
    )

    let capturedErrors = loadAndCaptureResult(for: sut)

    #expect(capturedErrors == [.invalidData])
  }

  @Test func load_deliversErrorOn200HTTPResponseWithInvalidData() {
    let (sut, client) = makeSUT()
    client.stubResponse(
      makeResponse(from: someURL, and: 200),
      invalidJSONData
    )

    let capturedErrors = loadAndCaptureResult(for: sut)

    #expect(capturedErrors == [.invalidData])
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

  private func loadAndCaptureResult(for sut: RemoteFeedLoader) -> [RemoteFeedLoader.Error] {
    var capturedErrors = [RemoteFeedLoader.Error]()
    do {
      try sut.load()
    } catch let error as RemoteFeedLoader.Error {
      capturedErrors.append(error)
    } catch {}

    return capturedErrors
  }

  private class HTTPClientSpy: HTTPClient {
    var requestedURLs = [URL]()
    private var receivedResponses = ([HTTPURLResponse](), [Data]())

    func get(from url: URL) throws -> HTTPClientResponse {
      requestedURLs.append(url)
      guard let firstResponse = receivedResponses.0.first else {
        throw NSError(domain: "HTTPClientSpy error", code: 0)
      }
      return (firstResponse, "Invalid JSON".data(using: .utf8)!)
    }

    func stubResponse(_ response: HTTPURLResponse, _ data: Data) {
      receivedResponses.0.append(response)
      receivedResponses.1.append(data)
    }
  }

}
