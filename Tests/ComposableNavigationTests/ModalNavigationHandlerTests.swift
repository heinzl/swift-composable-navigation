import XCTest
import SwiftUI
import ComposableArchitecture
import OrderedCollections
@testable import ComposableNavigation

@MainActor
class ModalNavigationHandlerTests: XCTestCase {
	func testPresentSheet() async {
		let container = Container()
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 1, style: .pageSheet)
		), container)
		
		thenAssertItem(.init(item: 1, style: .pageSheet), container)
		thenAssertPresentedViewController(style: .pageSheet, container)
		thenAssertCreatedViews(for: [1], container)
	}
	
	func testPresentFullScreen() async {
		let container = Container()
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 1, style: .fullScreen)
		), container)
		
		thenAssertItem(.init(item: 1, style: .fullScreen), container)
		thenAssertPresentedViewController(style: .fullScreen, container)
		thenAssertCreatedViews(for: [1], container)
	}
	
	func testSetStyledItemToNil() async {
		let container = Container()
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 2, style: .pageSheet)
		), container)
		await whenNewStateIsReceived(.init(styledItem: nil), container)
		
		thenAssertItem(nil, container)
		thenAssertPresentedViewController(style: nil, container)
		thenAssertCreatedViews(for: [2], container)
	}
	
	func testDismissAfterPresent() async {
		let container = Container()
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 1, style: .fullScreen)
		), container)
		await whenNewStateIsReceived(.init(
			styledItem: nil
		), container)
		
		thenAssertItem(nil, container)
		thenAssertCreatedViews(for: [1], container)
	}
	
	func testPresentDifferentItemButSameStyle() async {
		let container = Container()
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 1, style: .fullScreen)
		), container)
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 2, style: .fullScreen)
		), container)
		
		thenAssertItem(.init(item: 2, style: .fullScreen), container)
		thenAssertPresentedViewController(style: .fullScreen, container)
		thenAssertCreatedViews(for: [1, 2], container)
	}
	
	func testPresentDifferentItemAndDifferentStyle() async {
		let container = Container()
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 1, style: .fullScreen)
		), container)
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 2, style: .pageSheet)
		), container)
		
		thenAssertItem(.init(item: 2, style: .pageSheet), container)
		thenAssertPresentedViewController(style: .pageSheet, container)
		thenAssertCreatedViews(for: [1, 2], container)
	}
	
	func testPresentSameItemButDifferentStyle() async {
		let container = Container()
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 1, style: .fullScreen)
		), container)
		await whenNewStateIsReceived(.init(
			styledItem: .init(item: 1, style: .pageSheet)
		), container)
		
		thenAssertItem(.init(item: 1, style: .pageSheet), container)
		thenAssertPresentedViewController(style: .pageSheet, container)
		thenAssertCreatedViews(for: [1], container)
	}
	
	func testMemoryLeak() {
		var container: Container! = Container()
		container.sut.setup(with: UIViewController())
		assertNil(container.sut) {
			container = nil
		}
	}
}

@MainActor
private func whenNewStateIsReceived(_ state: ModalNavigation<Int>.State, _ container: Container) async {
	await container.sut.updateModalViewController(
		newState: state,
		presentingViewController: container.baseViewController
	)
}

@MainActor
private func thenAssertItem(_ expectedItem: ModalNavigation<Int>.StyledItem?, _ container: Container) {
	XCTAssertEqual(container.sut.currentViewControllerItem?.styledItem, expectedItem)
}

@MainActor
private func thenAssertPresentedViewController(style: UIModalPresentationStyle?, _ container: Container) {
	XCTAssertEqual(container.baseViewController.presentedViewController, container.sut.currentViewControllerItem?.viewController)
	XCTAssertEqual(container.baseViewController.presentedViewController?.modalPresentationStyle, style)
}

@MainActor
private func thenAssertCreatedViews(for items: [Int], _ container: Container) {
	XCTAssertEqual(container.sut.viewProvider.viewsCreatedFrom, items)
}

@MainActor
private class Container {
	let sut: ModalNavigationHandler<ItemViewProvider>
	
	let window = UIWindow(frame: UIScreen.main.bounds)
	let baseViewController = MockViewController()
	
	init() {
		self.sut = ModalNavigationHandler(
			store: Store(
				initialState: ModalNavigation<Int>.State(),
				reducer: { ModalNavigation<Int>() }
			),
			viewProvider: ItemViewProvider()
		)

		window.makeKeyAndVisible()
		window.rootViewController = baseViewController
		_ = baseViewController.view
	}
}

class MockViewController: UIViewController {
	var _presentedViewController: UIViewController?
	
	override var presentedViewController: UIViewController? {
		get { _presentedViewController }
		set { _presentedViewController = newValue }
	}
	
	override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
		presentedViewController = viewControllerToPresent
		completion?()
	}
	
	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		presentedViewController = nil
		completion?()
	}
}
