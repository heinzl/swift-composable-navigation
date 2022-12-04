import Foundation

struct Country: Codable, Identifiable, Equatable {
	let name: String
	let capital: String
	let continent: String
	
	var id: String { name }
}
