import EssentialFeed
import SwiftUI
import ViewInspector
import XCTest

struct FeedView: View {
  @State public var loader: FeedLoader
  @State public var feed: [FeedItem]?
  @State private var loadingIndicatorOpacity: CGFloat = 1
  var onDidAppear: ((Self) -> Void)?
  var onFeedChange: ((Self) -> Void)?
  var onFinishRefreshing: ((Self) -> Void)?

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
        self.onDidAppear?(self)
        await refresh()
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
      feed = try await loader.load()
      self.onFinishRefreshing?(self)
    } catch {}
  }
}

@MainActor
class EssentialFeediOSXCTests: XCTestCase {
  func test_init_doesNotLoadFeed() {
    let (_, loader) = makeSUT()
    XCTAssertEqual(loader.loadCallCount, 0)
  }


  func test_onAppear_loadsFeed() async {
    var (sut, loader) = makeSUT()

    let exp = sut.on(\.onDidAppear) { _ in XCTAssertEqual(loader.loadCallCount, 1) }

    ViewHosting.host(view: sut)
    await fulfillment(of: [exp], timeout: 0.1)
  }

  func test_userInitiatedFeedReload_loadsFeed() async {
    var (sut, loader) = makeSUT()

    let pullToRefresh = sut.on(\.onFinishRefreshing) { _ in XCTAssertEqual(loader.loadCallCount, 2) }

    ViewHosting.host(view: sut)
    await sut.refresh()
    await fulfillment(of: [pullToRefresh], timeout: 0.1)
  }

  func test_userInitiatedFeedReloadTwice_loadsFeedTwice() async {
    var (sut, loader) = makeSUT()

    let pullToRefreshTwice = sut.on(\.onFinishRefreshing) { _ in XCTAssertEqual(loader.loadCallCount, 3) }

    ViewHosting.host(view: sut)
    await sut.refresh()
    await sut.refresh()
    await fulfillment(of: [pullToRefreshTwice], timeout: 0.1)
  }

  func test_onAppear_showsLoadingIndicator() async throws {
    var (sut, _) = makeSUT()

    let appear = sut.on(\.onDidAppear) { view in
      XCTAssertTrue(try isShowingLoadingIndicator(for: view))
    }
    ViewHosting.host(view: sut)
    await fulfillment(of: [appear], timeout: 0.1)
  }

  func test_onChange_hidesLoadingIndicatorOnLoaderCompletion() async throws {
    var (sut, _) = makeSUT()

    let appear = sut.on(\.onFeedChange) { view in
      XCTAssertFalse(try isShowingLoadingIndicator(for: view))
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

private func isShowingLoadingIndicator(for view: InspectableView<ViewType.View<FeedView>>) throws -> Bool {
  let indicator = try view.find(viewWithId: "loading indicator")
  return try indicator.opacity() != 0
}

final class LoaderSpy: FeedLoader, @unchecked Sendable {
  private(set) var loadCallCount = 0

  func load() async throws -> [EssentialFeed.FeedItem] {
    loadCallCount += 1
    return [FeedItem(id: UUID(), imageURL: URL(string: "http://some-url.ru")!)]
  }
}
