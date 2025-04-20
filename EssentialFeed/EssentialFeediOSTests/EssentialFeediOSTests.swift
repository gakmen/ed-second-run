import EssentialFeed
import SwiftUI
import ViewInspector
import XCTest

struct FeedView: View {
  @State public var loader: FeedLoader
  @State public var feed: [FeedItem]?
  @State private var loadingIndicatorOpacity: CGFloat = 1
  var onDidAppear: ((Self) -> Void)?
  var onDidRefresh: ((Self) -> Void)?
  var onFeedChange: ((Self) -> Void)?

  init(loader: FeedLoader) {
    self.loader = loader
  }

  var body: some View {
    NavigationView {
      List {}
        .refreshable(action: refresh)
        .overlay {
          ProgressView()
            .id("loading indicator")
            .opacity(loadingIndicatorOpacity)
        }
    }
    .onAppear {
      Task {
        do {
          self.onDidAppear?(self)
          feed = try await loader.load()
        } catch {}
      }
    }
    .onChange(of: feed) { _, newValue in
      if newValue != nil { withAnimation { loadingIndicatorOpacity = 0 } }
      onFeedChange?(self)
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
  func test_onAppear_loadsFeed() async {
    var (sut, loader) = makeSUT()

    let exp = sut.on(\.onDidAppear) { _ in XCTAssertEqual(loader.loadCallCount, 1) }

    ViewHosting.host(view: sut)
    await fulfillment(of: [exp], timeout: 0.1)
  }

  @MainActor
  func test_pullToRefresh_loadsFeed() async {
    var (sut, loader) = makeSUT()

    let appear = sut.on(\.onDidAppear) { _ in }
    let pullToRefresh = sut.on(\.onDidRefresh) { _ in XCTAssertEqual(loader.loadCallCount, 2) }

    ViewHosting.host(view: sut)
    await sut.refresh()
    await fulfillment(of: [appear, pullToRefresh], timeout: 0.1)
  }

  @MainActor
  func test_pullToRefreshTwice_loadsFeedTwice() async {
    var (sut, loader) = makeSUT()

    let appear = sut.on(\.onDidAppear) { _ in }
    let pullToRefreshTwice = sut.on(\.onDidRefresh) { _ in XCTAssertEqual(loader.loadCallCount, 3) }

    ViewHosting.host(view: sut)
    await sut.refresh()
    await sut.refresh()
    await fulfillment(of: [appear, pullToRefreshTwice], timeout: 0.1)
  }

  @MainActor
  func test_onAppear_showsLoadingIndicator() async throws {
    var (sut, _) = makeSUT()

    let appear = sut.on(\.onDidAppear) { view in
      let indicator = try view.find(viewWithId: "loading indicator")
      XCTAssertTrue(try indicator.opacity() != 0)
    }
    ViewHosting.host(view: sut)
    await fulfillment(of: [appear], timeout: 0.1)
  }

  @MainActor
  func test_onChange_hidesLoadingIndicatorOnLoaderCompletion() async throws {
    var (sut, _) = makeSUT()

    let appear = sut.on(\.onFeedChange) { view in
      let indicator = try view.find(viewWithId: "loading indicator")
      XCTAssertTrue(try indicator.opacity() == 0)
    }
    ViewHosting.host(view: sut)
    await fulfillment(of: [appear], timeout: 0.1)
  }
}

//MARK: - Helpers

private func makeSUT() -> (sut: FeedView, loader: LoaderSpy) {
  let loaderSpy = LoaderSpy()
  let sut = FeedView(loader: loaderSpy)
  return (sut, loaderSpy)
}

final class LoaderSpy: FeedLoader, @unchecked Sendable {
  private(set) var loadCallCount = 0

  func load() async throws -> [EssentialFeed.FeedItem] {
    loadCallCount += 1
    return [FeedItem(id: UUID(), imageURL: URL(string: "http://some-url.ru")!)]
  }
}
