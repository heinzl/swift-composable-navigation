import XCTest
import SwiftUI
import ComposableArchitecture
import OrderedCollections
@testable import ComposableNavigation

class StackNavigationViewControllerTests: XCTestCase {
	
	// MARK: Push
	
	func testPushOnEmptyStack() {
		let state = State(items: [])
		
		whenActionIsSend(.pushItem(1), state)
		
		thenAssertItems([1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1], state)
	}
	
	func testPushOnStack() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.pushItem(3), state)
		
		thenAssertItems([1, 2, 3], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3], state)
	}
	
	func testConsecutivePushsOnStack() {
		let state = State(items: [1])
		
		whenActionIsSend(.pushItem(2), state)
		whenActionIsSend(.pushItem(3), state)
		
		thenAssertItems([1, 2, 3], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3], state)
	}
	
	func testPushMultipleItemsOnStack() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.pushItems([3, 4]), state)
		
		thenAssertItems([1, 2, 3, 4], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3, 4], state)
	}
	
	// MARK: Pop
	
	func testPopFromEmptyStack() {
		let state = State(items: [])
		
		whenActionIsSend(.popItem(), state)
		
		thenAssertItems([], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [], state)
	}
	
	func testPopFromStack() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.popItem(), state)
		
		thenAssertItems([1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testConsecutivePopsFromStack() {
		let state = State(items: [1, 2, 3])
		
		whenActionIsSend(.popItem(), state)
		whenActionIsSend(.popItem(), state)
		
		thenAssertItems([1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3], state)
	}
	
	func testPopToRoot() {
		let state = State(items: [1, 2, 3, 4])
		
		whenActionIsSend(.popToRoot(), state)
		
		thenAssertItems([1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3, 4], state)
	}
	
	// MARK: Set stack
	
	func testSetStackFromEmpty() {
		let state = State(items: [])
		
		whenActionIsSend(.setItems([1, 2]), state)
		
		thenAssertItems([1, 2], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackToEmpty() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([]), state)
		
		thenAssertItems([], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackAddItemsOnTop() {
		let state = State(items: [1])
		
		whenActionIsSend(.setItems([1, 2]), state)
		
		thenAssertItems([1, 2], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackRemoveItemsFromTop() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([1]), state)
		
		thenAssertItems([1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackSwitchItems() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([2, 1]), state)
		
		thenAssertItems([2, 1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackSwitchAndAddItems() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([3, 2, 4, 1]), state)
		
		thenAssertItems([3, 2, 4, 1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3, 4], state)
	}
	
	func testSetStackSwitchAndRemoveItems() {
		let state = State(items: [1, 2, 3, 4])
		
		whenActionIsSend(.setItems([3, 1]), state)
		
		thenAssertItems([3, 1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3, 4], state)
	}
}

private func whenActionIsSend(_ action: StackNavigation<Int>.Action, _ state: State) {
	UIView.performWithoutAnimation {
		state.viewStore.send(action)
	}
}

private func thenAssertItems(_ expectedItems: [Int], _ state: State) {
	XCTAssertEqual(state.sut.navigationHandler.viewStore.items, expectedItems)
	XCTAssertEqual(Array(state.sut.navigationHandler.currentViewControllerItems.keys), expectedItems)
}

private func thenAssertViewControllerStack(_ state: State) {
	XCTAssertEqual(state.sut.viewControllers, Array(state.sut.navigationHandler.currentViewControllerItems.values))
}

private func thenAssertCreatedViews(for items: [Int], _ state: State) {
	XCTAssertEqual(state.sut.navigationHandler.viewProvider.viewsCreatedFrom, items)
}

private class State {
	let sut: StackNavigationViewController<ItemViewProvider>
	let store: Store<StackNavigation<Int>.State, StackNavigation<Int>.Action>
	let viewStore: ViewStore<StackNavigation<Int>.State, StackNavigation<Int>.Action>
	
	init(items: [Int] = []) {
		self.store = Store(
			initialState: StackNavigation<Int>.State(items: items),
			reducer: StackNavigation<Int>.reducer(),
			environment: ()
		)
		self.viewStore = ViewStore(store)
		self.sut = StackNavigationViewController(
			store: store,
			viewProvider: ItemViewProvider()
		)
	}
}
