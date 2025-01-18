import Testing
import Foundation

class RemoteFeedLoader {

}

class HTTPClient {
  var requestedURL: URL?
}

struct RemoteFeedLoaderTests {
  @Test
  func init_doesNotRequestDataFromURL() {
    let client = HTTPClient()
    _ = RemoteFeedLoader()

    #expect(client.requestedURL == nil)
  }
}
