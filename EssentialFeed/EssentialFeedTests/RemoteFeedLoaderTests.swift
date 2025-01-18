import EssentialFeed
import Foundation
import Testing

struct RemoteFeedLoaderTests {
  @Test func init_doesNotRequestDataFromURL() {
    let (_, client) = makeSUT()

    #expect(client.requestedURLs.isEmpty)
  }

  @Test func load_requestsDataFromURL() {
    let url = URL(string: "https://a-given-url.ru")!
    let (sut, client) = makeSUT(url: url)

    try? sut.load()

    #expect(client.requestedURLs == [url])
  }

  @Test func loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://a-given-url.ru")!
    let (sut, client) = makeSUT(url: url)

    try? sut.load()
    try? sut.load()

    #expect(client.requestedURLs == [url, url])
  }

  @Test func load_deliversErrorOnClientError() {
    let (sut, _) = makeSUT()

    var capturedErrors = [RemoteFeedLoader.Error]()
    do {
      try sut.load()
    } catch let error as RemoteFeedLoader.Error {
      capturedErrors.append(error)
    } catch {}

    #expect(capturedErrors == [.connectivity])
  }

  @Test(arguments: [199, 201, 300, 400, 500])
  func load_deliversErrorOnNon200HTTPResponse(code: Int) {
    let url = URL(string: "https://a-given-url.ru")!
    let (sut, client) = makeSUT(url: url)
    client.responses.append(
      HTTPURLResponse(
        url: url,
        statusCode: code,
        httpVersion: nil,
        headerFields: nil
      )!
    )

    var capturedErrors = [RemoteFeedLoader.Error]()
    do {
      try sut.load()
    } catch let error as RemoteFeedLoader.Error {
      capturedErrors.append(error)
    } catch {}

    #expect(capturedErrors == [.invalidData])
  }

  // MARK: - Helpers

  func makeSUT(
    url: URL = URL(string: "https://a-url.ru")!
  ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    return (sut, client)
  }

  class HTTPClientSpy: HTTPClient {
    var requestedURLs = [URL]()
    var responses = [HTTPURLResponse]()

    func get(from url: URL) throws -> HTTPURLResponse {
      requestedURLs.append(url)
      guard let firstResponse = responses.first else {
        throw NSError(domain: "HTTPClientSpy error", code: 0)
      }
      return firstResponse
    }
  }

}
