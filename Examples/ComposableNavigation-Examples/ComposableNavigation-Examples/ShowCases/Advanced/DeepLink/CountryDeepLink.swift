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
					Button("Show Austria") {
						viewStore.send(.showCountry("Austria"))
					}
					Button("Show sorting options") {
						viewStore.send(.showSorting)
					}
				}
				.navigationTitle("Deep link")
			}
		}
	}
}
