import Foundation
import OrderedCollections
import UIKit
import ComposableArchitecture

internal struct ReorderUtil {
	/// Re-orders items and view controllers based on `newItems`.
	/// View controllers for existing items are reused.
	internal static func rearrangingItems<ViewProvider: ViewProviding>(
		newItems: [ViewProvider.Item],
		currentViewControllerItems: OrderedDictionary<ViewProvider.Item, UIViewController>,
		viewProvider: ViewProvider
	) -> OrderedDictionary<ViewProvider.Item, UIViewController> {
		var newViewControllerItems = OrderedDictionary<ViewProvider.Item, UIViewController>()
		for newItem in newItems {
			let viewController: UIViewController
			if let existingViewController = currentViewControllerItems[newItem] {
				viewController = existingViewController.viewController
			} else {
				viewController = viewProvider.makeViewController(for: newItem)
			}
			newViewControllerItems[newItem] = viewController
		}
		return newViewControllerItems
	}
}
