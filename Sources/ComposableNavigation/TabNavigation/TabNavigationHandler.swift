import UIKit
import Combine
import OrderedCollections
import ComposableArchitecture

/// The `TabNavigationHandler` listens to state changes and updates the selected view or tab order accordingly.
///
/// Additionally, it acts as the `UITabBarControllerDelegate` and automatically updates the state
/// when the active tab is changed by the user.
@MainActor
public class TabNavigationHandler<ViewProvider: ViewProviding>: NSObject, UITabBarControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias Navigation = TabNavigation<Item>
	
	internal let store: StoreOf<Navigation>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItems: OrderedDictionary<Item, UIViewController>
	
	private var cancellable: AnyCancellable?

	public init(
		store: StoreOf<Navigation>,
		viewProvider: ViewProvider
	) {
		self.store = store
		self.viewProvider = viewProvider
		self.currentViewControllerItems = [:]
	}
	
	public func setup(with tabBarController: UITabBarController) {
		tabBarController.delegate = self
		
		cancellable = store.publisher
			.sink { [weak self, weak tabBarController] state in
				guard let self, let tabBarController else { return }
				self.checkTabBarControllerDelegate(tabBarController)
				self.updateTabViewController(newState: state, for: tabBarController)
			}
	}

	internal func updateTabViewController(
		newState: Navigation.State,
		for tabBarController: UITabBarController
	) {
		updateViewControllers(newState: newState, for: tabBarController)
		updateSelectedItem(newState.activeItem, newItems: newState.items, for: tabBarController)
	}

	private func updateViewControllers(
		newState: Navigation.State,
		for tabBarController: UITabBarController
	) {
		let newItems = newState.items
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
			animated: shouldAnimateTabChanges(for: tabBarController, state: newState)
		)
	}
	
	private func shouldAnimateTabChanges(
		for tabBarController: UITabBarController,
		state: Navigation.State
	) -> Bool {
		if tabBarController.viewControllers?.isEmpty ?? true {
			return false
		} else if !UIView.areAnimationsEnabled {
			return false
		} else {
			return state.areAnimationsEnabled
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

		Task { @MainActor in
			await Task.yield()
			store.send(.setActiveIndex(index))
		}
	}

	private func checkTabBarControllerDelegate(_ tabBarController: UITabBarController) {
		#if DEBUG
		guard tabBarController.delegate !== self else {
			return
		}
		let delegateString: String
		if let delegate = tabBarController.delegate {
			delegateString = String(describing: delegate)
		} else {
			delegateString = "nil"
		}
		print("""
		WARNING: ComposableNavigation: TabNavigationHandler \(self) is not delegate of the UITabBarController \(tabBarController).
		The delegate is now \(delegateString). Make sure that the delegate is not changed when the TabNavigationHandler is active.
		""")
		#endif
	}
}
