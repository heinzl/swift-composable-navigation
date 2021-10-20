import UIKit
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountryDeepLink {
	
	// MARK: TCA
	
	struct State: Equatable {}
	
	enum Action: Equatable {
		case showCountry(Country.ID)
		case showSorting
		case showAlertOptions
	}
	
	struct Environment {}
	
	static let reducer: Reducer<State, Action, Environment> = .empty
}

struct CountryDeepLinkView: View, Presentable {
	let store: Store<CountryDeepLink.State, CountryDeepLink.Action>
	
	var body: some View {
		WithViewStore(store) { viewStore in
			NavigationView {
				Form {
					Button {
						viewStore.send(.showCountry("Austria"))
					} label: {
						Label("Show Austria", systemImage: "list.dash")
					}
					Button {
						viewStore.send(.showSorting)
					} label: {
						Label("Show sorting options", systemImage: "arrow.up.arrow.down.circle")
					}
					Button {
						viewStore.send(.showAlertOptions)
					} label: {
						Label("Show alert options", systemImage: "exclamationmark.bubble")
					}
				}
				.navigationTitle("Deep link")
			}
		}
	}
}
