import Foundation
import XCTest

public extension XCTestCase {
	func assertNil(_ subject: AnyObject?, after: @escaping () -> Void, file: StaticString = #file, line: UInt = #line) {
		guard let value = subject else {
			return XCTFail("Argument must not be nil", file: file, line: line)
		}

		addTeardownBlock { [weak value] in
			after()
			XCTAssert(value == nil, "Expected subject to be nil after test! Retain cycle?", file: file, line: line)
		}
	}
}
