import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

@Reducer
struct ContinentFilter {
	@ObservableState
	struct State: Equatable {
		var continents = [String]()
		var selectedContinent: String?
	}
	
	@CasePathable
	enum Action {
		case selectContinent(String?)
		case done
		case showSorting
	}

	func reduce(into state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .selectContinent(let continent):
			state.selectedContinent = continent
		default:
			break
		}
		return .none
	}
}

struct ContinentFilterView: View, Presentable {
	let store: StoreOf<ContinentFilter>
	
	var body: some View {
		NavigationView {
			List {
				Cell(
					continent: nil,
					isSelected: store.selectedContinent == nil,
					onSelect: {
						store.send(.selectContinent(nil))
					}
				)
				ForEach(store.continents, id: \.self) { continent in
					Cell(
						continent: continent,
						isSelected: continent == store.selectedContinent,
						onSelect: {
							store.send(.selectContinent(continent))
						}
					)
				}
			}
			.listStyle(InsetGroupedListStyle())
			.navigationTitle("Select continent")
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: {
						store.send(.done)
					}, label: {
						Text("Close")
					})
				}
				ToolbarItem(placement: .bottomBar) {
					Button("Show sorting options") {
						store.send(.showSorting)
					}
				}
			}
		}
	}
	
	struct Cell: View {
		let continent: String?
		let isSelected: Bool
		let onSelect: () -> Void
		
		var body: some View {
			Button(action: {
				onSelect()
			}, label: {
				HStack {
					Text(continent ?? "None")
					Spacer()
					if isSelected {
						Image(systemName: "checkmark")
					}
				}
			})
		}
	}
}
