import Foundation

enum XCTUnwrapItemError: Error {
	case outOfBounds
}

func XCTUnwrapItem<Item>(_ array: Array<Item>, at index: Int) throws -> Item {
	guard array.indices.contains(index) else {
		throw XCTUnwrapItemError.outOfBounds
	}
	return array[index]
}
