import UIKit
import SwiftUI

@MainActor
public protocol ViewProviding {
	associatedtype Item: Hashable
	func makePresentable(for navigationItem: Item) -> Presentable
}

public extension ViewProviding {
	func makeViewController(for navigationItem: Item) -> UIViewController {
		makePresentable(for: navigationItem).viewController
	}
}

@MainActor
public protocol Presentable {
	var viewController: UIViewController { get }
}

extension UIViewController: Presentable {
	public var viewController: UIViewController {
		self
	}
}

extension View where Self: Presentable {
	public var viewController: UIViewController {
		UIHostingController(rootView: self)
	}
}
