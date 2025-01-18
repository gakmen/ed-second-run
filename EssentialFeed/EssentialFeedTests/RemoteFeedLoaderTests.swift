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

  @Test func load_deliversConnectivityErrorOnClientError() {
    let (sut, client) = makeSUT()
    client.error = NSError(domain: "Test", code: 0)

    var capturedError: RemoteFeedLoader.Error?
    do {
      try sut.load()
    } catch {
      capturedError = error as? RemoteFeedLoader.Error
    }

    #expect(capturedError == .connectivity)
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
    var error: Error?

    func get(from url: URL) throws {
      requestedURLs.append(url)
      if let error { throw error }
    }
  }

}
