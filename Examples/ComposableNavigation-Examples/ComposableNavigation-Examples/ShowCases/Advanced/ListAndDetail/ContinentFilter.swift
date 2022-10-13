import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct ContinentFilter: ReducerProtocol {
	struct State: Equatable {
		var continents = [String]()
		var selectedContinent: String?
	}
	
	enum Action: Equatable {
		case selectContinent(String?)
		case done
		case showSorting
	}

	func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
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
	let store: Store<ContinentFilter.State, ContinentFilter.Action>
	
	var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			NavigationView {
				List {
					Cell(
						continent: nil,
						isSelected: viewStore.selectedContinent == nil,
						onSelect: {
							viewStore.send(.selectContinent(nil))
						}
					)
					ForEach(viewStore.continents, id: \.self) { continent in
						Cell(
							continent: continent,
							isSelected: continent == viewStore.selectedContinent,
							onSelect: {
								viewStore.send(.selectContinent(continent))
							}
						)
					}
				}
				.listStyle(InsetGroupedListStyle())
				.navigationTitle("Select continent")
				.toolbar {
					ToolbarItem(placement: .navigationBarTrailing) {
						Button(action: {
							viewStore.send(.done)
						}, label: {
							Text("Close")
						})
					}
					ToolbarItem(placement: .bottomBar) {
						Button("Show sorting options") {
							viewStore.send(.showSorting)
						}
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
