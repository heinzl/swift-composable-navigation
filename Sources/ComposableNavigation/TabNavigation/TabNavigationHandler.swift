import UIKit
import Combine
import OrderedCollections
import ComposableArchitecture

/// The `TabNavigationHandler` listens to state changes and updates the selected view or tab order accordingly.
///
/// Additionally, it acts as the `UITabBarControllerDelegate` and automatically updates the state
/// when the active tab is changed by the user.
public class TabNavigationHandler<ViewProvider: ViewProviding>: NSObject, UITabBarControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias ItemTabs = TabNavigation<Item>
	
	internal let viewStore: ViewStore<ItemTabs.State, ItemTabs.Action>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItems: OrderedDictionary<Item, UIViewController>
	
	private var cancellable: AnyCancellable?
	
	public init(
		store: Store<ItemTabs.State, ItemTabs.Action>,
		viewProvider: ViewProvider
	) {
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.currentViewControllerItems = [:]
	}
	
	public func setup(with tabBarController: UITabBarController) {
		tabBarController.delegate = self
		
		cancellable = viewStore.publisher
			.sink { [weak self] in
				guard let self = self else { return }
				self.updateViewControllers(newItems: $0.items, for: tabBarController)
				self.updateSelectedItem($0.activeItem, newItems: $0.items, for: tabBarController)
			}
	}
	
	private func updateViewControllers(
		newItems: [Item],
		for tabBarController: UITabBarController
	) {
		let oldItems = Array(currentViewControllerItems.keys)
		
		guard oldItems != newItems else {
			return
		}
		
		currentViewControllerItems = ReorderUtil.rearrangingItems(
			newItems: newItems,
			currentViewControllerItems: currentViewControllerItems,
			viewProvider: viewProvider
		)
		
		tabBarController.setViewControllers(
			Array(currentViewControllerItems.values),
			animated: shouldAnimateStackChanges(for: tabBarController)
		)
	}
	
	private func shouldAnimateStackChanges(for tabBarController: UITabBarController) -> Bool {
		if tabBarController.viewControllers?.isEmpty ?? true {
			return false
		} else {
			return UIView.areAnimationsEnabled
		}
	}
	
	private func updateSelectedItem(
		_ item: Item,
		newItems: [Item],
		for tabBarController: UITabBarController
	) {
		guard
			let index = newItems.firstIndex(of: item),
			tabBarController.selectedIndex != index
		else {
			return
		}
		tabBarController.selectedIndex = index
	}
	
	// MARK: UITabBarControllerDelegate
	
	public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		guard let index = currentViewControllerItems.values.firstIndex(of: viewController) else {
			return
		}
		viewStore.send(.setActiveIndex(index))
	}
}
