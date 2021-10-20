import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryTabBar {
	
	// MARK: TCA
	
	enum Screen: CaseIterable {
		case deepLink
		case listAndDetail
	}
	
	struct State: Equatable {
		var deepLink = CountryDeepLink.State()
		var listAndDetail = CountryListAndDetail.State()
		
		var tabNavigation = TabNavigation<Screen>.State(
			items: Screen.allCases,
			activeItem: .listAndDetail
		)
	}
	
	enum Action: Equatable {
		case deepLink(CountryDeepLink.Action)
		case listAndDetail(CountryListAndDetail.Action)
		case tabNavigation(TabNavigation<Screen>.Action)
	}
	
	struct Environment {
		let countryProvider: CountryProvider
	}
	
	private static let privateReducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .deepLink(.showSorting):
			return .concatenate([
				.init(value: .tabNavigation(.setActiveItem(.listAndDetail))),
				.init(value: .listAndDetail(.stackNavigation(.setItems([.list])))),
				.init(value: .listAndDetail(.modalNavigation(.presentSheet(.sort))))
			])
		case .deepLink(.showCountry(let countryId)):
			return .concatenate([
				.init(value: .tabNavigation(.setActiveItem(.listAndDetail))),
				.init(value: .listAndDetail(.stackNavigation(.setItems([.list, .detail(id: countryId)]))))
			])
		default:
			break
		}
		return .none
	}
	
	static let reducer: Reducer<State, Action, Environment> = Reducer.combine([
		CountryDeepLink.reducer
			.pullback(
				state: \.deepLink,
				action: /Action.deepLink,
				environment: { _ in .init() }
			),
		CountryListAndDetail.reducer
			.pullback(
				state: \.listAndDetail,
				action: /Action.listAndDetail,
				environment: { .init(countryProvider: $0.countryProvider) }
			),
		TabNavigation<Screen>.reducer()
			.pullback(
				state: \.tabNavigation,
				action: /Action.tabNavigation,
				environment: { _ in () }
			),
		privateReducer
	])
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: Screen) -> Presentable {
			switch navigationItem {
			case .deepLink:
				let view = CountryDeepLinkView(
					store: store.scope(
						state: \.deepLink,
						action: CountryTabBar.Action.deepLink
					)
				)
				let viewController = UIHostingController(rootView: view)
				viewController.tabBarItem = UITabBarItem(
					title: "Deep link",
					image: UIImage(systemName: "link"),
					tag: 0
				)
				return viewController

			case .listAndDetail:
				let listAndDetailStore = store.scope(
					state: \.listAndDetail,
					action: CountryTabBar.Action.listAndDetail
				)
				ViewStore(listAndDetailStore).send(.loadCountries)
				let stackNavigationController = StackNavigationViewController(
					store: listAndDetailStore.scope(
						state: \.stackNavigation,
						action: CountryListAndDetail.Action.stackNavigation
					),
					viewProvider: CountryListAndDetail.StackViewProvider(store: listAndDetailStore)
				)
				stackNavigationController.navigationBar.prefersLargeTitles = true
				let viewController = stackNavigationController
					.withModal(
						store: listAndDetailStore.scope(
							state: \.modalNavigation,
							action: CountryListAndDetail.Action.modalNavigation
						),
						viewProvider: CountryListAndDetail.ModalViewProvider(store: listAndDetailStore)
					)
				viewController.tabBarItem = UITabBarItem(
					title: "List",
					image: UIImage(systemName: "list.dash"),
					tag: 1
				)
				return viewController
			}
		}
	}
	
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		return TabNavigationViewController(
			store: store.scope(
				state: \.tabNavigation,
				action: CountryTabBar.Action.tabNavigation
			),
			viewProvider: CountryTabBar.ViewProvider(store: store)
		)
	}
}
