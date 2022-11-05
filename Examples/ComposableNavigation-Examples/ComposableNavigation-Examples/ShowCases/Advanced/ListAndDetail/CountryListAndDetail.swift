import UIKit
import ComposableNavigation
import ComposableArchitecture

struct CountryListAndDetail: ReducerProtocol {
	
	// MARK: TCA
	
	enum StackScreen: Hashable {
		case list
		case detail(id: Country.ID)
	}
	
	enum ModalScreen: Hashable {
		case filter
		case sort
	}
	
	struct State: Equatable {
		var countries = [Country]()
		
		var list: CountryList.State {
			get {
				.init(countries: countries
					.filter(filter)
					.sorted(by: sort)
				)
			}
			set {
				// No op
			}
		}
		
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
						.map(CountryDetail.State.init(country:))
				case .list:
					detail = nil
				default:
					break
				}
			}
		}
		
		var modalNavigation = ModalNavigation<ModalScreen>.State()
		
		private func filter(_ country: Country) -> Bool {
			if let filter = continentFilter.selectedContinent {
				return country.continent == filter
			} else {
				return true
			}
		}
		
		private func sort(_ lhs: Country, _ rhs: Country) -> Bool {
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
	
	enum Action: Equatable {
		case loadCountries
		
		case list(CountryList.Action)
		case detail(CountryDetail.Action)
		case continentFilter(ContinentFilter.Action)
		case countrySort(CountrySort.Action)
		
		case stackNavigation(StackNavigation<StackScreen>.Action)
		case modalNavigation(ModalNavigation<ModalScreen>.Action)
	}
	
	@Dependency(\.countryProvider) var countryProvider
	
	private func privateReducer(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .loadCountries:
			let countries = self.countryProvider.getCountryList()
			state.countries = countries
			state.continentFilter.continents = Set(countries.map(\.continent)).sorted()
		case .list(.selectCountry(let id)):
			return .task { .stackNavigation(.pushItem(.detail(id: id))) }
		case .list(.selectFilter),
				.countrySort(.showFilter):
			return .task { .modalNavigation(.presentSheet(.filter)) }
		case .list(.selectSorting),
				.continentFilter(.showSorting):
			return .task { .modalNavigation(.presentSheet(.sort)) }
		case .continentFilter(.done),
				.countrySort(.done):
			return .task { .modalNavigation(.dismiss()) }
		default:
			break
		}
		return .none
	}
	
	var body: some ReducerProtocol<State, Action> {
		Scope(state: \.continentFilter, action: /Action.continentFilter) {
			ContinentFilter()
		}
		Scope(state: \.countrySort, action: /Action.countrySort) {
			CountrySort()
		}
		Scope(state: \.list, action: /Action.list) {
			CountryList()
		}
		Scope(state: \.stackNavigation, action: /Action.stackNavigation) {
			StackNavigation<StackScreen>()
		}
		Scope(state: \.modalNavigation, action: /Action.modalNavigation) {
			ModalNavigation<ModalScreen>()
		}
		Reduce(privateReducer)
			.ifLet(\.detail, action: /Action.detail) {
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
						action: Action.list
					)
				)
			case .detail:
				let presentable: Presentable = store.scope(
					state: \.detail,
					action: Action.detail
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
						action: Action.continentFilter
					)
				)
			case .sort:
				return CountrySort.makeView(store.scope(
					state: \.countrySort,
					action: Action.countrySort
				))
			}
		}
	}
}

private enum CountryProviderKey: DependencyKey {
	static var liveValue: CountryProviderProtocol = CountryProvider()
}

extension DependencyValues {
	var countryProvider: CountryProviderProtocol {
		get { self[CountryProviderKey.self] }
		set { self[CountryProviderKey.self] = newValue }
	}
}
