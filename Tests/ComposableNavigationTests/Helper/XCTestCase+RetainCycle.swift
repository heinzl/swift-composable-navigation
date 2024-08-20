import Foundation
import XCTest
import ComposableArchitecture

public extension XCTestCase {
	func assertNil(
		_ subject: AnyObject?,
		after: @escaping () -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		guard let value = subject else {
			return XCTFail("Argument must not be nil", file: file, line: line)
		}
		let closureContainer = LockClosureContainer(after)
		let weakContainer = WeakLockContainer(value)
		addTeardownBlock {
			closureContainer.perform()
			XCTAssert(weakContainer.isDeallocated, "Expected subject to be nil after test! Retain cycle?", file: file, line: line)
		}
	}
	
	private class LockClosureContainer: @unchecked Sendable {
		private var closure: () -> Void
		private let lock = NSRecursiveLock()
		
		init(_ closure: @escaping () -> Void) {
			self.closure = closure
		}
		
		func perform() {
			lock.lock()
			defer { lock.unlock() }
			closure()
		}
	}
	
	private class WeakLockContainer<Value: AnyObject>: @unchecked Sendable {
		private weak var value: Value?
		private let lock = NSRecursiveLock()
		
		init(_ value: Value) {
			self.value = value
		}
		
		var isDeallocated: Bool {
			lock.lock()
			defer { lock.unlock() }
			return self.value == nil
		}
	}
}
