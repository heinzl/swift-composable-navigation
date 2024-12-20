import UIKit
import ComposableNavigation
import ComposableArchitecture

@Reducer
struct CountryListAndDetail {
	
	// MARK: TCA
	
	enum StackScreen: Hashable {
		case list
		case detail(id: Country.ID)
	}
	
	enum ModalScreen: Hashable {
		case filter
		case sort
	}
	
	@ObservableState
	struct State: Equatable {
		var countries = [Country]()
		
		var list: CountryList.State = .init(countries: [])
		
		var detail: CountryDetail.State?
		var continentFilter = ContinentFilter.State()
		var countrySort = CountrySort.State()
		
		var stackNavigation: StackNavigation<StackScreen>.State {
			get {
				let screens: [StackScreen]
				if let detailId = detail?.country.id {
					screens = [.list, .detail(id: detailId)]
				} else {
					screens = [.list]
				}
				return .init(items: screens)
			}
			set {
				switch newValue.topItem {
				case let .detail(id):
					detail = countries
						.first(where: { $0.id == id })
						.map {
							CountryDetail.State(country: $0)
						}
				case .list:
					detail = nil
				default:
					break
				}
			}
		}
		
		var modalNavigation = ModalNavigation<ModalScreen>.State()
		
		func filter(_ country: Country) -> Bool {
			if let filter = continentFilter.selectedContinent {
				return country.continent == filter
			} else {
				return true
			}
		}
		
		func sort(_ lhs: Country, _ rhs: Country) -> Bool {
			let comperator: (String, String) -> Bool
			switch countrySort.sortOrder {
			case .ascending:
				comperator = (<)
			case .descending:
				comperator = (>)
			}
			let sortKeyPath: KeyPath<Country, String>
			switch countrySort.sortKey {
			case .country:
				sortKeyPath = \.name
			case .capital:
				sortKeyPath = \.capital
			}
			return comperator(lhs[keyPath: sortKeyPath], rhs[keyPath: sortKeyPath])
		}
	}
	
	@CasePathable
	enum Action: BindableAction {
		case loadCountries
		
		case list(CountryList.Action)
		case detail(CountryDetail.Action)
		case continentFilter(ContinentFilter.Action)
		case countrySort(CountrySort.Action)
		
		case stackNavigation(StackNavigation<StackScreen>.Action)
		case modalNavigation(ModalNavigation<ModalScreen>.Action)
		
		case binding(BindingAction<State>)
	}
	
	@Dependency(\.countryProvider) var countryProvider
	
	private func privateReducer(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .loadCountries:
			let countries = self.countryProvider.getCountryList()
			state.countries = countries
			state.continentFilter.continents = Set(countries.map(\.continent)).sorted()
			updateList(&state)
			
		case .list(.selectCountry(let id)):
			return .send(.stackNavigation(.pushItem(.detail(id: id))))
			
		case .list(.selectFilter), .countrySort(.showFilter):
			return .send(.modalNavigation(.presentSheet(.filter)))
			
		case .list(.selectSorting), .continentFilter(.showSorting):
			return .send(.modalNavigation(.presentSheet(.sort)))
			
		case .continentFilter(.done), .countrySort(.done):
			return .send(.modalNavigation(.dismiss()))
			
		default:
			break
		}
		return .none
	}
	
	private func updateList(_ state: inout State) {
		state.list = .init(
			countries: state.countries
				.filter(state.filter)
				.sorted(by: state.sort)
		)
	}
	
	var body: some ReducerOf<Self> {
		BindingReducer()
		Scope(state: \.continentFilter, action: \.continentFilter) {
			ContinentFilter()
		}
		.onChange(of: { $0.continentFilter }){ oldValue, newValue in
			Reduce { state, action in
				updateList(&state)
				return .none
			}
		}
		
		Scope(state: \.countrySort, action: \.countrySort) {
			CountrySort()
		}
		.onChange(of: { $0.countrySort }){ oldValue, newValue in
			Reduce { state, action in
				updateList(&state)
				return .none
			}
		}

		Scope(state: \.list, action: \.list) {
			CountryList()
		}
		Scope(state: \.stackNavigation, action: \.stackNavigation) {
			StackNavigation<StackScreen>()
		}
		Scope(state: \.modalNavigation, action: \.modalNavigation) {
			ModalNavigation<ModalScreen>()
		}
		Reduce(privateReducer)
			.ifLet(\.detail, action: \.detail) {
				CountryDetail()
			}
	}
	
	// MARK: View creation
	
	struct StackViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: StackScreen) -> Presentable {
			switch navigationItem {
			case .list:
				return CountryListView(
					store: store.scope(
						state: \.list,
						action: \.list
					)
				)
			case .detail:
				let presentable: Presentable = store.scope(
					state: \.detail,
					action: \.detail
				)
				.compactMap(CountryDetailView.init(store:)) ?? UIViewController()
				let viewController = presentable.viewController
				viewController.navigationItem.title = "Detail"
				return viewController
			}
		}
	}
	
	struct ModalViewProvider: ViewProviding {
		let store: Store<State, Action>
		
		func makePresentable(for navigationItem: ModalScreen) -> Presentable {
			switch navigationItem {
			case .filter:
				return ContinentFilterView(
					store: store.scope(
						state: \.continentFilter,
						action: \.continentFilter
					)
				)
			case .sort:
				return CountrySort.makeView(store.scope(
					state: \.countrySort,
					action: \.countrySort
				))
			}
		}
	}
	
	@MainActor
	static func makeView(store: Store<State, Action>) -> UIViewController {
		let stackNavigationController = StackNavigationViewController(
			store: store.scope(
				state: \.stackNavigation,
				action: \.stackNavigation
			),
			viewProvider: CountryListAndDetail.StackViewProvider(store: store)
		)
		stackNavigationController.navigationBar.prefersLargeTitles = true
		return stackNavigationController
			.withModal(
				store: store.scope(
					state: \.modalNavigation,
					action: \.modalNavigation
				),
				viewProvider: CountryListAndDetail.ModalViewProvider(store: store)
			)
	}
}

private enum CountryProviderKey: DependencyKey, Sendable {
	static let liveValue: CountryProviderProtocol = CountryProvider()
}

extension DependencyValues {
	var countryProvider: CountryProviderProtocol {
		get { self[CountryProviderKey.self] }
		set { self[CountryProviderKey.self] = newValue }
	}
}
