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
		case combiningStacks(CombiningStacks)
		case uiTest(UITest)
		
		enum CombiningStacks {
			case individual
			case combined
		}
		
		enum UITest: String {
			case swipeDownModalSheet
			case swipeBackOnStackNavigation
			case changingTabs
			case nestedDeepLink
		}
	}
	
	func makeRootViewController(with showcase: Showcase) -> UIViewController {
		switch showcase {
		case .modal:
			return ModalShowcase.makeView(Store(
				initialState: ModalShowcase.State(),
				reducer: { ModalShowcase() }
			))
		case .stack:
			return StackShowcase.makeView(Store(
				initialState: StackShowcase.State(),
				reducer: { StackShowcase() }
			))
		case .tabs:
			return TabsShowcase.makeView(Store(
				initialState: TabsShowcase.State(),
				reducer: { TabsShowcase() }
			))
		case .alert:
			return AlertShowcase.makeView(Store(
				initialState: AlertShowcase.State(),
				reducer: { AlertShowcase() }
			))
		case .existingView:
			return ExistingViewShowcase.makeView(Store(
				initialState: ExistingViewShowcase.State(),
				reducer: { ExistingViewShowcase() }
			))
		case .multipleOptionalModalStates:
			return MultipleOptionalModalStatesShowcase.makeView(Store(
				initialState: MultipleOptionalModalStatesShowcase.State(),
				reducer: { MultipleOptionalModalStatesShowcase() }
			))
		case .advanced:
			return AdvancedShowcase.makeView(Store(
				initialState: AdvancedTabBar.State(),
				reducer: { AdvancedTabBar() }
			))
		case .combiningStacks(.individual):
			return CombiningStacksShowCase.IndividualStack.makeView(Store(
				initialState: CombiningStacksShowCase.IndividualStack.State(),
				reducer: { CombiningStacksShowCase.IndividualStack() }
			))
		case .combiningStacks(.combined):
			return CombiningStacksShowCase.makeView(Store(
				initialState: CombiningStacksShowCase.State(),
				reducer: { CombiningStacksShowCase() }
			))
		
		case .uiTest(let uiTestCase):
			switch uiTestCase {
			case .swipeDownModalSheet:
				return SwipeDownModalSheet.makeView(Store(
					initialState: SwipeDownModalSheet.State(),
					reducer: { SwipeDownModalSheet() }
				))
			case .swipeBackOnStackNavigation:
				return SwipeBackOnStackNavigation.makeView(Store(
					initialState: SwipeBackOnStackNavigation.State(),
					reducer: { SwipeBackOnStackNavigation() }
				))
			case .changingTabs:
				return ChangingTabs.makeView(Store(
					initialState: ChangingTabs.State(),
					reducer: { ChangingTabs() }
				))
			case .nestedDeepLink:
				return NestedStack.makeView(store: Store(
					initialState: .example,
					reducer: { NestedStack() }
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
