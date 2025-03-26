import SwiftUI
import ViewInspector
import XCTest

struct FeedView: View {
  @State var loader: LoaderSpy
  var didAppear: ((Self) -> Void)?

  init(loader: LoaderSpy) {
    self.loader = loader
  }

  var body: some View {
    Text("FeedView")
      .onAppear {
        loader.load()
        self.didAppear?(self)
      }
  }
}

class EssentialFeediOSXCTests: XCTestCase {
  func test_init_doesNotLoadFeed() {
    let loader = LoaderSpy()
    var _ = FeedView(loader: loader)
    XCTAssertEqual(loader.loadCallCount, 0)
  }
  
  func test_onAppear_loadsFeed() throws {
    let loader = LoaderSpy()
    var sut = FeedView(loader: loader)

    let exp = expectation(description: "Wait for didAppear to be called")
    sut.didAppear = { view in
      XCTAssertEqual(view.loader.loadCallCount, 1)
      exp.fulfill()
    }

    ViewHosting.host(view: sut)
    defer { ViewHosting.expel() }
    wait(for: [exp], timeout: 0.01)
  }
}

//MARK: - Helpers

class LoaderSpy {
  private(set) var loadCallCount = 0

  func load() {
    loadCallCount += 1
  }
}
