import XCTest
import SwiftUI
import ComposableArchitecture
import OrderedCollections
@testable import ComposableNavigation

class ModalNavigationViewControllerTests: XCTestCase {
	func testPresentSheet() {
		let state = State(styledItem: nil)
		
		whenActionIsSend(.presentSheet(1), state)
		
		thenAssertItem(.init(item: 1, style: .pageSheet), state)
		thenAssertPresentedViewController(style: .pageSheet, state)
		thenAssertCreatedViews(for: [1], state)
	}
	
	func testPresentFullScreen() {
		let state = State(styledItem: nil)
		
		whenActionIsSend(.presentFullScreen(1), state)
		
		thenAssertItem(.init(item: 1, style: .fullScreen), state)
		thenAssertPresentedViewController(style: .fullScreen, state)
		thenAssertCreatedViews(for: [1], state)
	}
	
	func testSetStyledItem() {
		let state = State(styledItem: nil)
		
		whenActionIsSend(.set(.init(item: 2, style: .pageSheet)), state)
		
		thenAssertItem(.init(item: 2, style: .pageSheet), state)
		thenAssertPresentedViewController(style: .pageSheet, state)
		thenAssertCreatedViews(for: [2], state)
	}
	
	func testSetStyledItemToNil() {
		let state = State(styledItem: .init(item: 2, style: .pageSheet))
		
		whenActionIsSend(.set(nil), state)
		
		thenAssertItem(nil, state)
		thenAssertPresentedViewController(style: nil, state)
		thenAssertCreatedViews(for: [2], state)
	}
	
	func testDismiss() {
		let state = State(styledItem: .init(item: 1, style: .pageSheet))
		
		whenActionIsSend(.dismiss(), state)
		
		thenAssertItem(nil, state)
		thenAssertPresentedViewController(style: nil, state)
		thenAssertCreatedViews(for: [1], state)
	}
	
	func testDismissAfterPresent() {
		let state = State(styledItem: nil)
		
		whenActionIsSend(.presentFullScreen(1), state)
		whenActionIsSend(.dismiss(), state)
		
		thenAssertItem(nil, state)
		thenAssertCreatedViews(for: [1], state)
	}
	
	func testPresentDifferentItemButSameStyle() {
		let state = State(styledItem: .init(item: 1, style: .fullScreen))
		
		whenActionIsSend(.presentFullScreen(2), state)
		
		thenAssertItem(.init(item: 2, style: .fullScreen), state)
		thenAssertPresentedViewController(style: .fullScreen, state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testPresentDifferentItemAndDifferentStyle() {
		let state = State(styledItem: .init(item: 1, style: .fullScreen))
		
		whenActionIsSend(.presentSheet(2), state)
		
		thenAssertItem(.init(item: 2, style: .pageSheet), state)
		thenAssertPresentedViewController(style: .pageSheet, state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testPresentSameItemButDifferentStyle() {
		let state = State(styledItem: .init(item: 1, style: .fullScreen))
		
		whenActionIsSend(.presentSheet(1), state)
		
		thenAssertItem(.init(item: 1, style: .pageSheet), state)
		thenAssertPresentedViewController(style: .pageSheet, state)
		thenAssertCreatedViews(for: [1], state)
	}
}

private func whenActionIsSend(_ action: ModalNavigation<Int>.Action, _ state: State) {
	UIView.performWithoutAnimation {
		state.viewStore.send(action)
	}
}

private func thenAssertItem(_ expectedItem: ModalNavigation<Int>.StyledItem?, _ state: State) {
	XCTAssertEqual(state.sut.navigationHandler.viewStore.styledItem, expectedItem)
	XCTAssertEqual(state.sut.navigationHandler.currentViewControllerItem?.styledItem, expectedItem)
}

private func thenAssertPresentedViewController(style: UIModalPresentationStyle?, _ state: State) {
	XCTAssertEqual(state.sut.presentedViewController, state.sut.navigationHandler.currentViewControllerItem?.viewController)
	XCTAssertEqual(state.sut.presentedViewController?.modalPresentationStyle, style)
}

private func thenAssertCreatedViews(for items: [Int], _ state: State) {
	XCTAssertEqual(state.sut.navigationHandler.viewProvider.viewsCreatedFrom, items)
}

private class State {
	let sut: ModalNavigationViewController<ItemViewProvider>
	let store: Store<ModalNavigation<Int>.State, ModalNavigation<Int>.Action>
	let viewStore: ViewStore<ModalNavigation<Int>.State, ModalNavigation<Int>.Action>
	
	let window = UIWindow(frame: UIScreen.main.bounds)
	let baseViewController = UIViewController()
	
	init(styledItem: ModalNavigation<Int>.StyledItem?) {
		self.store = Store(
			initialState: ModalNavigation<Int>.State(styledItem: styledItem),
			reducer: ModalNavigation<Int>.reducer(),
			environment: ()
		)
		self.viewStore = ViewStore(store)
		self.sut = ModalNavigationViewController(
			contentViewController: baseViewController,
			store: store,
			viewProvider: ItemViewProvider()
		)
		
		window.makeKeyAndVisible()
		window.rootViewController = sut
		_ = sut.view
	}
}
