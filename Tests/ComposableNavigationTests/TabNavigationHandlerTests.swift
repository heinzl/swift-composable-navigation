import XCTest
import SwiftUI
import ComposableArchitecture
import OrderedCollections
@testable import ComposableNavigation

@MainActor
class TabNavigationHandlerTests: XCTestCase {
	// MARK: Set tab items
	
	func testSetStackFromEmpty() {
		let container = Container()
		
		whenNewStateIsReceived(.init(items: [1, 2], activeItem: -1), container)
		
		thenAssert(expectedItems: [1, 2], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2], container)
	}
	
	func testSetStackToEmpty() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2], activeItem: -1), container)
		whenNewStateIsReceived(.init(items: [], activeItem: -1), container)

		thenAssert(expectedItems: [], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2], container)
	}

	func testSetStackAddItemsOnTop() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1], activeItem: -1), container)
		whenNewStateIsReceived(.init(items: [1, 2], activeItem: -1), container)

		thenAssert(expectedItems: [1, 2], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2], container)
	}

	func testSetStackRemoveItemsFromTop() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2], activeItem: -1), container)
		whenNewStateIsReceived(.init(items: [1], activeItem: -1), container)

		thenAssert(expectedItems: [1], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2], container)
	}

	func testSetStackSwitchItems() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2], activeItem: -1), container)
		whenNewStateIsReceived(.init(items: [2, 1], activeItem: -1), container)

		thenAssert(expectedItems: [2, 1], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2], container)
	}

	func testSetStackSwitchAndAddItems() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2], activeItem: -1), container)
		whenNewStateIsReceived(.init(items: [3, 2, 4, 1], activeItem: -1), container)

		thenAssert(expectedItems: [3, 2, 4, 1], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3, 4], container)
	}

	func testSetStackSwitchAndRemoveItems() {
		let container = Container()
		
		whenNewStateIsReceived(.init(items: [1, 2, 3, 4], activeItem: -1), container)
		whenNewStateIsReceived(.init(items: [3, 1], activeItem: -1), container)

		thenAssert(expectedItems: [3, 1], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3, 4], container)
	}

	// MARK: Set active item

	func testChangeActiveItem() {
		let container = Container()
		
		whenNewStateIsReceived(.init(items: [1, 2], activeItem: -1), container)
		whenNewStateIsReceived(.init(items: [1, 2], activeItem: 2), container)

		thenAssertSelectedIndex(1, container)
	}

	func testChangeActiveItemOutOfBounds() {
		let container = Container()
		
		whenNewStateIsReceived(.init(items: [1, 2], activeItem: 1), container)
		whenNewStateIsReceived(.init(items: [1, 2], activeItem: 99), container)

		thenAssertSelectedIndex(0, container)
	}

	func testRemoveItemsSetsActiveIndexTo0() {
		let container = Container()
		
		whenNewStateIsReceived(.init(items: [1, 2, 3], activeItem: 3), container)
		thenAssertSelectedIndex(2, container)

		whenNewStateIsReceived(.init(items: [1, 2], activeItem: 3), container)

		thenAssertSelectedIndex(0, container)
	}


	func testMemoryLeak() {
		var container: Container! = Container()
		container.sut.setup(with: container.tabBarController)
		assertNil(container.sut) {
			container = nil
		}
	}
}

@MainActor
private func whenNewStateIsReceived(_ state: TabNavigation<Int>.State, _ container: Container) {
	container.sut.updateTabViewController(
		newState: state,
		for: container.tabBarController
	)
}

@MainActor
private func thenAssert(expectedItems: [Int], _ container: Container) {
	XCTAssertEqual(Array(container.sut.currentViewControllerItems.keys), expectedItems)
}

@MainActor
private func thenAssertViewControllerStack(_ container: Container) {
	XCTAssertEqual(container.tabBarController.viewControllers, Array(container.sut.currentViewControllerItems.values))
}

@MainActor
private func thenAssertCreatedViews(for items: [Int], _ container: Container) {
	XCTAssertEqual(container.sut.viewProvider.viewsCreatedFrom, items)
}

@MainActor
private func thenAssertSelectedIndex(_ index: Int, _ container: Container) {
	XCTAssertEqual(container.tabBarController.selectedIndex, index)
}

@MainActor
private class Container {
	let sut: TabNavigationHandler<ItemViewProvider>
	let tabBarController = UITabBarController()
	
	init() {
		self.sut = TabNavigationHandler(
			store: Store(
				initialState: .init(
					items: [],
					activeItem: -1
				),
				reducer: TabNavigation<Int>()
			),
			viewProvider: ItemViewProvider()
		)
	}
}
