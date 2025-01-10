import Foundation

protocol CountryProviderProtocol: Sendable {
	func getCountryList() -> [Country]
}

struct CountryProvider: CountryProviderProtocol {
	func getCountryList() -> [Country] {
		guard
			let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
			let data = try? Data(contentsOf: url),
			let countries = try? JSONDecoder().decode([Country].self, from: data)
		else {
			return []
		}
		return countries
	}
}
