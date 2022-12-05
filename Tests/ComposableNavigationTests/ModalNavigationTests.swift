import Foundation
import XCTest
import ComposableArchitecture
@testable import ComposableNavigation

@MainActor
class ModalNavigationTests: XCTestCase {
	func testPresentingFullScreenItem() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.presentFullScreen(1)) {
			$0.styledItem = .init(item: 1, style: .fullScreen)
		}
	}
	
	func testPresentingSheetItem() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.presentSheet(1)) {
			$0.styledItem = .init(item: 1, style: .pageSheet)
		}
	}
	
	func testSettingModalItem() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.set(.init(item: 1, style: .currentContext))) {
			$0.styledItem = .init(item: 1, style: .currentContext)
		}
	}
	
	func testDismissingItem() async {
		let store = makeStore(.init(styledItem: .init(item: 1, style: .pageSheet)))
		
		await store.send(.dismiss()) {
			$0.styledItem = nil
		}
	}
	
	func testDismissingWithoutItem() async {
		let store = makeStore(.init(styledItem: nil))
		store.exhaustivity = .off
		
		await store.send(.dismiss()) {
			$0.styledItem = nil
		}
	}
	
	func testChangingStyle() async {
		let store = makeStore(.init(styledItem: .init(item: 1, style: .pageSheet)))
		
		await store.send(.set(.init(item: 1, style: .overFullScreen))) {
			$0.styledItem = .init(item: 1, style: .overFullScreen)
		}
	}
	
	func testChangingItem() async {
		let store = makeStore(.init(styledItem: .init(item: 1, style: .pageSheet)))
		
		await store.send(.set(.init(item: 2, style: .pageSheet))) {
			$0.styledItem = .init(item: 2, style: .pageSheet)
		}
	}
	
	func testDisablingAnimation() async {
		let store = makeStore(.init(styledItem: nil))
		
		await store.send(.set(.init(item: 1, style: .pageSheet), animated: false)) {
			$0.styledItem = .init(item: 1, style: .pageSheet)
			$0.areAnimationsEnabled = false
		}
	}
	
	// MARK: Helper
	
	private typealias TestFeature = ModalNavigation<Int>
	
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
