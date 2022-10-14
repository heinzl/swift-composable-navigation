import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}
		
		// 👉 Choose showcase 👈
		let showcase: Showcase = .advanced
		
		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = makeRootViewController(
			with: readShowcaseForUITest() ?? showcase
		)
		self.window = window
		window.makeKeyAndVisible()
	}
	
	// MARK: - Showcases
	
	enum Showcase {
		case modal
		case stack
		case tabs
		case alert
		case existingView
		case advanced
		case multipleOptionalModalStates
		case uiTest(UITest)
		
		enum UITest: String {
			case swipeDownModalSheet
			case swipeBackOnStackNavigation
			case changingTabs
		}
	}
	
	func makeRootViewController(with showcase: Showcase) -> UIViewController {
		switch showcase {
		case .modal:
			return ModalShowcase.makeView(Store(
				initialState: .init(),
				reducer: ModalShowcase()
			))
		case .stack:
			return StackShowcase.makeView(Store(
				initialState: .init(),
				reducer: StackShowcase()
			))
		case .tabs:
			return TabsShowcase.makeView(Store(
				initialState: .init(),
				reducer: TabsShowcase()
			))
		case .alert:
			return AlertShowcase.makeView(Store(
				initialState: .init(),
				reducer: AlertShowcase()
			))
		case .existingView:
			return ExistingViewShowcase.makeView(Store(
				initialState: .init(),
				reducer: ExistingViewShowcase()
			))
		case .multipleOptionalModalStates:
			return MultipleOptionalModalStatesShowcase.makeView(Store(
				initialState: .init(),
				reducer: MultipleOptionalModalStatesShowcase()
			))
		case .advanced:
			return AdvancedShowcase.makeView(Store(
				initialState: AdvancedTabBar.State(),
				reducer: AdvancedTabBar()
			))
		
		case .uiTest(let uiTestCase):
			switch uiTestCase {
			case .swipeDownModalSheet:
				return SwipeDownModalSheet.makeView(Store(
					initialState: .init(),
					reducer: SwipeDownModalSheet()
				))
			case .swipeBackOnStackNavigation:
				return SwipeBackOnStackNavigation.makeView(Store(
					initialState: .init(),
					reducer: SwipeBackOnStackNavigation()
				))
			case .changingTabs:
				return ChangingTabs.makeView(Store(
					initialState: .init(),
					reducer: ChangingTabs()
				))
			}
		}
	}
	
	// MARK: - Helper
	
	func readShowcaseForUITest() -> Showcase? {
		guard
			CommandLine.arguments.contains("-uiTest"),
			let showcaseString = CommandLine.arguments.last
		else {
			return nil
		}
		guard let showcase = Showcase.UITest(rawValue: showcaseString) else {
			fatalError("Can not parse showcase for UITest")
		}
		return .uiTest(showcase)
	}
}
