import Foundation

struct CountryProvider {
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
