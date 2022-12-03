import XCTest
import SwiftUI
import UIKit
import ComposableArchitecture
import OrderedCollections
@testable import ComposableNavigation

@MainActor
class StackNavigationHandlerTests: XCTestCase {
	
	// MARK: Push
	
	func testPushOnEmptyStack() {
		let container = Container()
		
		whenNewStateIsReceived(.init(items: [1]), container)
		
		thenAssertItems([1], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1], container)
	}
	
	func testPushOnStack() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2]), container)
		whenNewStateIsReceived(.init(items: [1, 2, 3]), container)

		thenAssertItems([1, 2, 3], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3], container)
	}

	func testConsecutivePushsOnStack() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1]), container)
		whenNewStateIsReceived(.init(items: [1, 2]), container)
		whenNewStateIsReceived(.init(items: [1, 2, 3]), container)

		thenAssertItems([1, 2, 3], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3], container)
	}

	func testPushMultipleItemsOnStack() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2]), container)
		whenNewStateIsReceived(.init(items: [1, 2, 3, 4]), container)

		thenAssertItems([1, 2, 3, 4], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3, 4], container)
	}

	// MARK: Pop

	func testPopFromEmptyStack() {
		let container = Container()

		whenNewStateIsReceived(.init(items: []), container)
		whenNewStateIsReceived(.init(items: []), container)

		thenAssertItems([], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [], container)
	}

	func testPopFromStack() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2]), container)
		whenNewStateIsReceived(.init(items: [1]), container)

		thenAssertItems([1], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2], container)
	}

	func testConsecutivePopsFromStack() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2, 3]), container)
		whenNewStateIsReceived(.init(items: [1, 2]), container)
		whenNewStateIsReceived(.init(items: [1]), container)

		thenAssertItems([1], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3], container)
	}

	func testPopMultipleItems() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2, 3, 4]), container)
		whenNewStateIsReceived(.init(items: [1, 2]), container)

		thenAssertItems([1, 2], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3, 4], container)
	}

	func testPopAllItems() {
		let container = Container()

		whenNewStateIsReceived(.init(items: [1, 2, 3, 4]), container)
		whenNewStateIsReceived(.init(items: []), container)

		thenAssertItems([], container)
		thenAssertViewControllerStack(container)
		thenAssertCreatedViews(for: [1, 2, 3, 4], container)
	}

	func testMemoryLeak() {
		var container: Container! = Container()
		container.sut.setup(with: container.navigationController)
		assertNil(container.sut) {
			container = nil
		}
	}
}

@MainActor
private func whenNewStateIsReceived(_ state: StackNavigation<Int>.State, _ container: Container) {
	container.sut.updateViewControllerStack(
		newState: state,
		for: container.navigationController,
		numberOfViewControllersOnStackToIgnore: 0
	)
}

@MainActor
private func thenAssertItems(_ expectedItems: [Int], _ container: Container) {
	XCTAssertEqual(Array(container.sut.currentViewControllerItems.keys), expectedItems)
}

@MainActor
private func thenAssertViewControllerStack(_ container: Container) {
	XCTAssertEqual(container.navigationController.viewControllers, Array(container.sut.currentViewControllerItems.values))
}

@MainActor
private func thenAssertCreatedViews(for items: [Int], _ container: Container) {
	XCTAssertEqual(container.sut.viewProvider.viewsCreatedFrom, items)
}

@MainActor
private class Container {
	let sut: StackNavigationHandler<ItemViewProvider>
	let navigationController = MockNavigationController()
	
	init() {
		self.sut = StackNavigationHandler(
			store: Store(
				initialState: .init(items: []),
				reducer: StackNavigation<Int>()
			),
			viewProvider: ItemViewProvider()
		)
	}
}

class MockNavigationController: UINavigationController {
	var _viewControllers: [UIViewController] = []
	
	override var viewControllers: [UIViewController] {
		get { _viewControllers }
		set { _viewControllers = newValue }
	}
	
	override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
		self.viewControllers = viewControllers
	}
}
