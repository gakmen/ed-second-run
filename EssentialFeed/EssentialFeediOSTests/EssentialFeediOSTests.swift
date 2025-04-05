import EssentialFeed
import SwiftUI
import ViewInspector
import XCTest

struct FeedView: View {
  @State var loader: FeedLoader
  var onDidAppear: ((Self) -> Void)?
  var onDidRefresh: ((Self) -> Void)?

  init(loader: FeedLoader) {
    self.loader = loader
  }

  var body: some View {
    NavigationView {
      List {}
        .id(1)
        .refreshable(action: refresh)
    }
      .onAppear {
        Task {
          do {
            _ = try await loader.load()
            self.onDidAppear?(self)
          } catch {}
        }
      }
  }

  @Sendable
  func refresh() async {
    do {
      _ = try await loader.load()
      self.onDidRefresh?(self)
    } catch {}
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

    let exp = sut.on(\.onDidAppear) { _ in XCTAssertEqual(loader.loadCallCount, 1) }

    ViewHosting.host(view: sut)
    await fulfillment(of: [exp], timeout: 0.1)
  }

  @MainActor
  func test_pullToRefresh_loadsFeed() async throws {
    var (sut, loader) = makeSUT()

    let appearExp = sut.on(\.onDidAppear) { _ in }
    let refreshExp = sut.on(\.onDidRefresh) { _ in XCTAssertEqual(loader.loadCallCount, 2) }

    ViewHosting.host(view: sut)
    await sut.refresh()
    await fulfillment(of: [appearExp, refreshExp], timeout: 0.1)
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
