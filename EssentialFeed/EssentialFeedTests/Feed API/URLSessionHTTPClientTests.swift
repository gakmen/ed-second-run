import Testing
import Foundation
import EssentialFeed

struct URLSessionHTTPClient: HTTPClient {
  let session: URLSession

  init(session: URLSession = URLSession.shared) {
    self.session = session
  }

  func get(from url: URL) async throws -> HTTPClientResponse {
    do {
      let (data, response) = try await session.data(from: url)
      if let httpResponse = response as? HTTPURLResponse {
        return (httpResponse, data)
      } else {
        throw UnexpectedResponse()
      }
    } catch {
      throw error
    }
  }

  struct UnexpectedResponse: Error {}
}

@Suite(.serialized)
final class URLSessionHTTPClientTests {
  init() { URLProtocolStub.startInterceptingRequests() }
  deinit { URLProtocolStub.stopInterceptingRequests() }

  @Test func getFromURL_performsGETRequestWithAGivenURL() async throws {
    URLProtocolStub.stub(with: .failure(someError))

    _ = try? await makeSUT().get(from: someURL)

    let (observedURL, observedMethod) = try await URLProtocolStub.observeRequest()

    #expect(observedURL == someURL)
    #expect(observedMethod == "GET")
  }

  @Test func getFromURL_failsOnRequestError() async {
    let expectedError = NSError(domain: "test error", code: 0)
    URLProtocolStub.stub(with: .failure(expectedError))

    do {
      _ = try await makeSUT().get(from: someURL)
    } catch let receivedError as NSError {
      #expect(receivedError.domain == expectedError.domain)
    } catch { Issue.record("Could not cast error to NSError: \(error)") }
  }

  @Test func getFromURL_failsOnUnexpectedNonHTTPResponse() async {
    let nonHTTPResponse = URLResponse(
      url: someURL,
      mimeType: nil,
      expectedContentLength: 0,
      textEncodingName: nil
    )
    URLProtocolStub.stub(with: .success((someData, nonHTTPResponse)))

    do {
      _ = try await makeSUT().get(from: someURL)
    } catch {
      #expect(error is URLSessionHTTPClient.UnexpectedResponse)
    }
  }

  @Test func getFromURL_succeedsOnHTTPResponseWithData() async {
    let expectedResponse = HTTPURLResponse(
      url: someURL,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )!
    URLProtocolStub.stub(with: .success((someData, expectedResponse)))

    do {
      let (response, data) = try await makeSUT().get(from: someURL)
      #expect(data == someData)
      #expect(response.url == expectedResponse.url)
      #expect(response.statusCode == expectedResponse.statusCode)
    } catch {
      Issue.record("Expected successful execution, got error instead: \(error)")
    }
  }

  // MARK: - Helpers

  private func makeSUT() -> HTTPClient {
    URLSessionHTTPClient()
  }

  private let someURL: URL = URL(string: "https://some-url.ru")!
  private let someError: Error = NSError(domain: "some error", code: 0)
  private let someData: Data = "some data".data(using: .utf8)!

  typealias StubbedResult = Result<(Data, URLResponse), Error>

  private class URLProtocolStub: URLProtocol {
    private static var request: URLRequest?
    private static var stubs = [StubbedResult]()

    static func observeRequest() async throws -> (URL, String) {
      if let url = Self.request?.url, let method = Self.request?.httpMethod {
        return (url, method)
      } else {
        throw NSError(domain: "No request", code: 0)
      }
    }

    static func stub(with result: StubbedResult) {
      stubs.append(result)
    }

    static func startInterceptingRequests() {
      URLProtocol.registerClass(Self.self)
    }

    static func stopInterceptingRequests() {
      URLProtocol.unregisterClass(Self.self)
      stubs = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
      Self.request = request
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      guard let stub = Self.stubs.first else { return }

      switch stub {
      case let .success ((data, response)):
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      case let .failure(error):
        client?.urlProtocol(self, didFailWithError: error)
      }

      client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
  }
}
