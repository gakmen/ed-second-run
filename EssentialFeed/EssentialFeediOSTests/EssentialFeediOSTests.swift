import EssentialFeed
import SwiftUI
import ViewInspector
import XCTest

struct FeedView: View {
  @State var loader: FeedLoader
  var didAppear: ((Self) -> Void)?

  init(loader: FeedLoader) {
    self.loader = loader
  }

  var body: some View {
    Text("FeedView")
      .onAppear {
        Task {
          do {
            _ = try await loader.load()
            self.didAppear?(self)
          } catch {}
        }
      }
  }
}

class EssentialFeediOSXCTests: XCTestCase {
  func test_init_doesNotLoadFeed() {
    let loader = LoaderSpy()
    var _ = FeedView(loader: loader)
    XCTAssertEqual(loader.loadCallCount, 0)
  }

  @MainActor
  func test_onAppear_loadsFeed() async throws {
    let loader = LoaderSpy()
    var sut = FeedView(loader: loader)

    let exp = expectation(description: "Wait for didAppear to be called")
    sut.didAppear = { view in
      XCTAssertEqual(loader.loadCallCount, 1)
      exp.fulfill()
    }

    ViewHosting.host(view: sut)
    await fulfillment(of: [exp], timeout: 0.01)
    ViewHosting.expel()
  }
}

//MARK: - Helpers

class LoaderSpy: FeedLoader {

  private(set) var loadCallCount = 0

  func load() async throws -> [EssentialFeed.FeedItem] {
    loadCallCount += 1
    return [FeedItem(id: UUID(), imageURL: URL(string: "http://some-url.ru")!)]
  }
}
