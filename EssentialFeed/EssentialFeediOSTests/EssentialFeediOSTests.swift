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
    let (_, loader) = makeSUT()
    XCTAssertEqual(loader.loadCallCount, 0)
  }

  @MainActor
  func test_onAppear_loadsFeed() async throws {
    var (sut, loader) = makeSUT()

    let exp = expectation(description: "Wait for didAppear to be called")
    sut.didAppear = { _ in
      XCTAssertEqual(loader.loadCallCount, 1)
      exp.fulfill()
    }

    ViewHosting.host(view: sut)
    await fulfillment(of: [exp], timeout: 0.1)
    ViewHosting.expel()
  }
}

//MARK: - Helpers

private func makeSUT() -> (sut: FeedView, loader: LoaderSpy) {
  let loaderSpy = LoaderSpy()
  let sut = FeedView(loader: loaderSpy)
  return (sut, loaderSpy)
}

class LoaderSpy: FeedLoader {

  private(set) var loadCallCount = 0

  func load() async throws -> [EssentialFeed.FeedItem] {
    loadCallCount += 1
    return [FeedItem(id: UUID(), imageURL: URL(string: "http://some-url.ru")!)]
  }
}
