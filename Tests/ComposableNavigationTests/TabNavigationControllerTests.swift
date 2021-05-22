import XCTest
import SwiftUI
import ComposableArchitecture
import OrderedCollections
@testable import ComposableNavigation

class TabNavigationControllerTests: XCTestCase {
	// MARK: Set tab items
	
	func testSetStackFromEmpty() {
		let state = State(items: [])
		
		whenActionIsSend(.setItems([1, 2]), state)
		
		thenAssert(expectedItems: [1, 2], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackToEmpty() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([]), state)
		
		thenAssert(expectedItems: [], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackAddItemsOnTop() {
		let state = State(items: [1])
		
		whenActionIsSend(.setItems([1, 2]), state)
		
		thenAssert(expectedItems: [1, 2], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackRemoveItemsFromTop() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([1]), state)
		
		thenAssert(expectedItems: [1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackSwitchItems() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([2, 1]), state)
		
		thenAssert(expectedItems: [2, 1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2], state)
	}
	
	func testSetStackSwitchAndAddItems() {
		let state = State(items: [1, 2])
		
		whenActionIsSend(.setItems([3, 2, 4, 1]), state)
		
		thenAssert(expectedItems: [3, 2, 4, 1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3, 4], state)
	}
	
	func testSetStackSwitchAndRemoveItems() {
		let state = State(items: [1, 2, 3, 4])
		
		whenActionIsSend(.setItems([3, 1]), state)
		
		thenAssert(expectedItems: [3, 1], state)
		thenAssertViewControllerStack(state)
		thenAssertCreatedViews(for: [1, 2, 3, 4], state)
	}
	
	// MARK: Set active item
	
	func testChangeActiveItem() {
		let state = State(items: [1, 2], activeItem: 1)
		
		whenActionIsSend(.setActiveItem(2), state)
		
		thenAssertSelectedIndex(1, state)
		thenAssertActiveItem(2, state)
	}
	
	func testChangeActiveIndex() {
		let state = State(items: [1, 2], activeItem: 1)
		
		whenActionIsSend(.setActiveIndex(1), state)
		
		thenAssertSelectedIndex(1, state)
		thenAssertActiveItem(2, state)
	}
	
	func testChangeActiveItemOutOfBounds() {
		let state = State(items: [1, 2], activeItem: 1)
		
		whenActionIsSend(.setActiveItem(99), state)
		
		thenAssertSelectedIndex(0, state)
		thenAssertActiveItem(1, state)
	}
	
	func testChangeActiveIndexOutOfBounds() {
		let state = State(items: [1, 2], activeItem: 1)
		
		whenActionIsSend(.setActiveIndex(99), state)
		
		thenAssertSelectedIndex(0, state)
		thenAssertActiveItem(1, state)
	}
	
	func testChangingItemsKeepsActiveIndex() {
		let state = State(items: [1, 2], activeItem: 1)
		thenAssertSelectedIndex(0, state)
		thenAssertActiveItem(1, state)
		
		whenActionIsSend(.setItems([2, 1]), state)
		
		thenAssertSelectedIndex(1, state)
		thenAssertActiveItem(1, state)
	}
	
	func testRemoveItemsSetsActiveIndexTo0() {
		let state = State(items: [1, 2, 3], activeItem: 3)
		thenAssertSelectedIndex(2, state)
		thenAssertActiveItem(3, state)
		
		whenActionIsSend(.setItems([1, 2]), state)
		
		thenAssertSelectedIndex(0, state)
		thenAssertActiveItem(1, state)
	}
}

private func whenActionIsSend(_ action: TabNavigation<Int>.Action, _ state: State) {
	UIView.performWithoutAnimation {
		state.viewStore.send(action)
	}
}

private func thenAssert(expectedItems: [Int], _ state: State) {
	XCTAssertEqual(state.sut.viewStore.items, expectedItems)
	XCTAssertEqual(Array(state.sut.currentViewControllerItems.keys), expectedItems)
}

private func thenAssertViewControllerStack(_ state: State) {
	XCTAssertEqual(state.sut.viewControllers, Array(state.sut.currentViewControllerItems.values))
}

private func thenAssertCreatedViews(for items: [Int], _ state: State) {
	XCTAssertEqual(state.sut.viewProvider.viewsCreatedFrom, items)
}

private func thenAssertSelectedIndex(_ index: Int, _ state: State) {
	XCTAssertEqual(state.sut.selectedIndex, index)
}

private func thenAssertActiveItem(_ item: Int, _ state: State) {
	XCTAssertEqual(state.sut.viewStore.activeItem, item)
}

private class State {
	let sut: TabNavigationController<ItemViewProvider>
	let store: Store<TabNavigation<Int>.State, TabNavigation<Int>.Action>
	let viewStore: ViewStore<TabNavigation<Int>.State, TabNavigation<Int>.Action>
	
	init(items: [Int] = [], activeItem: Int? = nil) {
		self.store = Store(
			initialState: TabNavigation<Int>.State(
				items: items,
				activeItem: activeItem ?? items.first ?? -1
			),
			reducer: TabNavigation<Int>.reducer(),
			environment: ()
		)
		self.viewStore = ViewStore(store)
		self.sut = TabNavigationController(
			store: store,
			viewProvider: ItemViewProvider()
		)
	}
}
