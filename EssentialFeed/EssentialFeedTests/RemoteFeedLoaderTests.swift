import Testing
import Foundation

class RemoteFeedLoader {
  let client: HTTPClient
  let url: URL

  init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }

  func load() {
    client.get(from: url)
  }
}

protocol HTTPClient {
  func get(from url: URL)
}

struct RemoteFeedLoaderTests {
  @Test func init_doesNotRequestDataFromURL() {
    let (_, client) = makeSUT()

    #expect(client.requestedURL == nil)
  }

  @Test func load_requestsDataFromURL() {
    let url = URL(string: "https://a-given-url.ru")!
    let (sut, client) = makeSUT(url: url)

    sut.load()
    
    #expect(client.requestedURL == url)
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
    var requestedURL: URL?

    func get(from url: URL) {
      requestedURL = url
    }
  }
  
}
