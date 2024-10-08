import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryDeepLink: Reducer {
	
	// MARK: TCA
	
	struct State: Equatable {}
	
	enum Action: Equatable {
		case showCountry(Country.ID)
		case showSorting
		case showSortingReset
		case showAlertOptions
		case showNestedNavigation
	}
	
	func reduce(into state: inout State, action: Action) -> Effect<Action> {
		.none
	}
	
	@MainActor
	static func makeView(store: Store<State, Action>) -> UIViewController {
		CountryDeepLinkView(store: store).viewController
	}
}

struct CountryDeepLinkView: View, Presentable {
	let store: Store<CountryDeepLink.State, CountryDeepLink.Action>
	
	var body: some View {
		NavigationView {
			Form {
				Button {
					store.send(.showCountry("Austria"))
				} label: {
					Label("Show Austria", systemImage: "list.dash")
				}
				Button {
					store.send(.showSorting)
				} label: {
					Label("Show sorting options", systemImage: "arrow.up.arrow.down.circle")
				}
				Button {
					store.send(.showSortingReset)
				} label: {
					Label("Show sorting options reset", systemImage: "arrow.up.arrow.down.circle")
				}
				Button {
					store.send(.showAlertOptions)
				} label: {
					Label("Show alert options", systemImage: "exclamationmark.bubble")
				}
				Button {
					store.send(.showNestedNavigation)
				} label: {
					Label("Nest multiple layers of stack and modal navigation", systemImage: "square.3.layers.3d.down.left")
				}
			}
			.navigationTitle("Deep link")
		}
	}
}
