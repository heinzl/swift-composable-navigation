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
		let afterContainer = LockContainer(after)
		let weakContainer = WeakLockContainer(value)
		addTeardownBlock {
			afterContainer.value()
			XCTAssert(weakContainer.isValueNil, "Expected subject to be nil after test! Retain cycle?", file: file, line: line)
		}
	}
	
	private class LockContainer<Value>: @unchecked Sendable {
		private let _value: Value
		private let lock = NSRecursiveLock()
		
		init(_ value: Value) {
			self._value = value
		}
		
		var value: Value {
			lock.lock()
			defer { lock.unlock() }
			return _value
		}
	}
	
	private class WeakLockContainer<Value: AnyObject>: @unchecked Sendable {
		private weak var value: Value?
		private let lock = NSRecursiveLock()
		
		init(_ value: Value) {
			self.value = value
		}
		
		var isValueNil: Bool {
			lock.lock()
			defer { lock.unlock() }
			return self.value == nil
		}
	}
}
