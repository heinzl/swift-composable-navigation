import Foundation

struct Country: Decodable, Identifiable, Equatable {
	let name: String
	let capital: String
	let continent: String
	
	var id: String { name }
}
