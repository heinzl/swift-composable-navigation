import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

struct CountrySort {
	enum SortKey: CaseIterable {
		case country
		case capital
	}
	
	enum SortOrder: CaseIterable {
		case ascending
		case descending
	}
	
	struct State: Equatable {
		var sortKey: SortKey = .country
		var sortOrder: SortOrder = .ascending
	}
	
	enum Action: Equatable {
		case selectSortKey(SortKey)
		case selectSortOrder(SortOrder)
		case done
		case showFilter
	}
	
	struct Environment {}
	
	static let reducer = Reducer<State, Action, Environment> { state, action, environment in
		switch action {
		case .selectSortKey(let sortKey):
			state.sortKey = sortKey
		case .selectSortOrder(let sortOrder):
			state.sortOrder = sortOrder
		default:
			break
		}
		return .none
	}
}

struct CountrySortView: View, Presentable {
	let store: Store<CountrySort.State, CountrySort.Action>
	
	var body: some View {
		WithViewStore(store) { viewStore in
			NavigationView {
				Form {
					Section {
						ForEach(CountrySort.SortKey.allCases, id: \.self) { sortKey in
							Cell(
								name: text(for: sortKey),
								isSelected: viewStore.sortKey == sortKey,
								onSelect: { viewStore.send(.selectSortKey(sortKey)) }
							)
						}
					}
					Section {
						ForEach(CountrySort.SortOrder.allCases, id: \.self) { sortOrder in
							Cell(
								name: text(for: sortOrder),
								isSelected: viewStore.sortOrder == sortOrder,
								onSelect: { viewStore.send(.selectSortOrder(sortOrder)) }
							)
						}
					}
				}
				.listStyle(InsetGroupedListStyle())
				.navigationTitle("Select sort order")
				.navigationBarItems(
					trailing: Button(action: {
						viewStore.send(.done)
					}, label: {
						Text("Close")
					})
				)
				.toolbar {
					ToolbarItem(placement: .bottomBar) {
						Button("Show filter options") {
							viewStore.send(.showFilter)
						}
					}
				}
			}
		}
	}
	
	func text(for sortKey: CountrySort.SortKey) -> String {
		switch sortKey {
		case .country:
			return "Country"
		case .capital:
			return "Capital"
		}
	}
	
	func text(for sortOrder: CountrySort.SortOrder) -> String {
		switch sortOrder {
		case .ascending:
			return "Ascending"
		case .descending:
			return "Descending"
		}
	}
	
	struct Cell: View {
		let name: String
		let isSelected: Bool
		let onSelect: () -> Void
		
		var body: some View {
			Button(action: {
				onSelect()
			}, label: {
				HStack {
					Text(name)
					Spacer()
					if isSelected {
						Image(systemName: "checkmark")
					}
				}
			})
		}
	}
}
