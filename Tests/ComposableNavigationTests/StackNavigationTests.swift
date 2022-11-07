import Foundation
import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

@MainActor
class StackNavigationTests: XCTestCase {
	func testPushItem() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.pushItem(1)) {
			$0.items = [1]
		}
	}
	
	func testPushItemOnExistingStack() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.pushItem(3)) {
			$0.items = [1, 2, 3]
		}
	}
	
	func testPushItems() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.pushItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	func testPushItemsOnExistingStack() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.pushItems([3, 4])) {
			$0.items = [1, 2, 3, 4]
		}
	}
	
	func testPopItem() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.popItem()) {
			$0.items = [1]
		}
	}
	
	func testPopItemsCount() async {
		let store = makeStore(.init(items: [1, 2, 3]))
		
		await store.send(.popItems(count: 2)) {
			$0.items = [1]
		}
	}
	
	func testPopItemFromEmptyStack() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.popItem())
	}
	
	func testPopTooManyItems() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.popItems(count: 5))
	}
	
	func testPopToRoot() async {
		let store = makeStore(.init(items: [1, 2, 3]))
		
		await store.send(.popToRoot()) {
			$0.items = [1]
		}
	}
	
	func testPopToRootOnEmptyStack() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.popToRoot())
	}
	
	func testPopToRootWithOnlyRoot() async {
		let store = makeStore(.init(items: [1]))
		
		await store.send(.popToRoot())
	}
	
	func testSetItems() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	func testSetItemsFromEmpty() async {
		let store = makeStore(.init(items: []))
		
		await store.send(.setItems([1, 2, 3])) {
			$0.items = [1, 2, 3]
		}
	}
	
	func testSetSameItemsDifferentOrder() async {
		let store = makeStore(.init(items: [1, 2, 3]))
		
		await store.send(.setItems([3, 2, 1])) {
			$0.items = [3, 2, 1]
		}
	}
	
	func testDisablingAnimation() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.setItems([1, 2], animated: false)) {
			$0.areAnimationsEnabled = false
		}
	}
	
	func testDisablingAnimationAndSettingsItems() async {
		let store = makeStore(.init(items: [1, 2]))
		
		await store.send(.setItems([3, 4], animated: false)) {
			$0.items = [3, 4]
			$0.areAnimationsEnabled = false
		}
	}
	
	// MARK: Helper
	
	private typealias TestFeature = StackNavigation<Int>
	
	private func makeStore(
		_ state: TestFeature.State
	) -> TestStore<
		TestFeature.State,
		TestFeature.Action,
		TestFeature.State,
		TestFeature.Action,
		()
	> {
		TestStore(initialState: state, reducer: TestFeature())
	}
}
