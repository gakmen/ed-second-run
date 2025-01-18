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

class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?

  func get(from url: URL) {
    requestedURL = url
  }
}

struct RemoteFeedLoaderTests {
  @Test func init_doesNotRequestDataFromURL() {
    let url = URL(string: "https://a-given-url.ru")!
    let client = HTTPClientSpy()
    _ = RemoteFeedLoader(url: url, client: client)

    #expect(client.requestedURL == nil)
  }

  @Test func load_requestsDataFromURL() {
    let url = URL(string: "https://a-given-url.ru")!
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)

    sut.load()
    
    #expect(client.requestedURL == url)
  }
}
