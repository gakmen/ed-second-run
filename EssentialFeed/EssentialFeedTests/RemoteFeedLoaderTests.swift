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

    sut.load()
    
    #expect(client.requestedURLs == [url])
  }

  @Test func loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://a-given-url.ru")!
    let (sut, client) = makeSUT(url: url)

    sut.load()
    sut.load()

    #expect(client.requestedURLs == [url, url])
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

    func get(from url: URL) {
      requestedURLs.append(url)
    }
  }

}
