import SwiftUI
import ComposableNavigation
import ComposableArchitecture

/// This setup is used for a UI test
@Reducer
struct ChangingTabs {
	
	// MARK: TCA
	
	enum Screen: String {
		case one
		case two
	}
	
	@ObservableState
	struct State: Equatable {
		var tabNavigation = TabNavigation<Screen>.State(
			items: [.one, .two],
			activeItem: .one
		)
	}
	
	@CasePathable
	enum Action {
		case tabNavigation(TabNavigation<Screen>.Action)
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.tabNavigation, action: \.tabNavigation) {
			TabNavigation<Screen>()
		}
	}
	
	// MARK: View creation
	
	struct TabView: View, Presentable {
		let store: Store<State, Action>
		
		var body: some View {
			Text(store.tabNavigation.activeItem.rawValue)
				.accessibilityIdentifier("tabsState")
		}
	}
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			let tabBarItem: UITabBarItem
			switch navigationItem {
			case .one:
				tabBarItem = .init(title: "one", image: nil, tag: 1)
			case .two:
				tabBarItem = .init(title: "two", image: nil, tag: 2)
			}
			let viewController = UIHostingController(rootView: TabView(store: store))
			viewController.tabBarItem = tabBarItem
			return viewController
		}
	}
	
	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		TabNavigationViewController(
			store: store.scope(
				state: \.tabNavigation,
				action: \.tabNavigation
			),
			viewProvider: ChangingTabs.ViewProvider(store: store)
		)
	}
}

