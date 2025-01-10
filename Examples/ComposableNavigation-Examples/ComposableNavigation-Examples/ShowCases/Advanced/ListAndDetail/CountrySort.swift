import Foundation
import SwiftUI
import ComposableNavigation
import ComposableArchitecture

@Reducer
struct CountrySort {
	enum SortKey: CaseIterable {
		case country
		case capital
	}
	
	enum SortOrder: CaseIterable {
		case ascending
		case descending
	}
	
	enum ModalScreen {
		case resetAlert
	}
	
	@ObservableState
	struct State: Equatable {
		var sortKey: SortKey = .country
		var sortOrder: SortOrder = .ascending
		var alertNavigation = ModalNavigation<ModalScreen>.State()
		
		var isResetDisabled: Bool {
			sortKey == .country && sortOrder == .ascending
		}
	}
	
	@CasePathable
	enum Action {
		case selectSortKey(SortKey)
		case selectSortOrder(SortOrder)
		case done
		case showFilter
		case resetTapped
		case resetConfirmed
		case alertNavigation(ModalNavigation<ModalScreen>.Action)
	}
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .selectSortKey(let sortKey):
			state.sortKey = sortKey
		case .selectSortOrder(let sortOrder):
			state.sortOrder = sortOrder
		case .resetTapped:
			return .send(.alertNavigation(.presentFullScreen(.resetAlert)))
		case .resetConfirmed:
			state.sortKey = .country
			state.sortOrder = .ascending
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.alertNavigation, action: \.alertNavigation) {
			ModalNavigation<ModalScreen>()
		}
		Reduce(privateReducer)
	}
	
	// MARK: View creation
	
	struct ViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: ModalScreen) -> Presentable {
			switch navigationItem {
			case .resetAlert:
				let alert = UIAlertController(
					title: "Confirmation",
					message: "Reset sort settings?",
					preferredStyle: .alert
				)
				alert.addAction(UIAlertAction(
					title: "Cancel",
					style: .cancel,
					store: store,
					toNavigationCasePath: \.alertNavigation
				))
				alert.addAction(UIAlertAction(
					title: "Reset",
					style: .destructive,
					action: .resetConfirmed,
					store: store,
					toNavigationCasePath: \.alertNavigation
				))
				return alert
			}
		}
	}
	
	@MainActor
	static func makeView(_ store: Store<State, Action>) -> UIViewController {
		return CountrySortView(store: store)
			.viewController.withModal(
				store: store.scope(
					state: \.alertNavigation,
					action: \.alertNavigation
				),
				viewProvider: ViewProvider(store: store)
			)
	}
}

struct CountrySortView: View, Presentable {
	let store: StoreOf<CountrySort>
	
	var body: some View {
		NavigationView {
			Form {
				Section {
					ForEach(CountrySort.SortKey.allCases, id: \.self) { sortKey in
						Cell(
							name: text(for: sortKey),
							isSelected: store.sortKey == sortKey,
							onSelect: { store.send(.selectSortKey(sortKey)) }
						)
					}
				}
				Section {
					ForEach(CountrySort.SortOrder.allCases, id: \.self) { sortOrder in
						Cell(
							name: text(for: sortOrder),
							isSelected: store.sortOrder == sortOrder,
							onSelect: { store.send(.selectSortOrder(sortOrder)) }
						)
					}
				}
			}
			.listStyle(InsetGroupedListStyle())
			.navigationTitle("Select sort order")
			.toolbar {
				ToolbarItemGroup(placement: .bottomBar) {
					Button("Show filter options") {
						store.send(.showFilter)
					}
					Spacer()
					Button(action: {
						store.send(.resetTapped)
					}, label: {
						Text("Reset")
							.foregroundColor(.red)
							.bold()
					})
					.disabled(store.isResetDisabled)
				}
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: {
						store.send(.done)
					}, label: {
						Text("Close")
					})
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
