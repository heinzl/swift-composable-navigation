import UIKit
import Combine
import OrderedCollections
import ComposableArchitecture

public class TabNavigationHandler<ViewProvider: ViewProviding>: NSObject, UITabBarControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias ItemTabs = TabNavigation<Item>
	
	internal weak var tabBarController: UITabBarController?
	internal let store: Store<ItemTabs.State, ItemTabs.Action>
	internal let viewStore: ViewStore<ItemTabs.State, ItemTabs.Action>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItems: OrderedDictionary<Item, UIViewController>
	
	private var cancellables = Set<AnyCancellable>()
	
	public init(
		store: Store<ItemTabs.State, ItemTabs.Action>,
		viewProvider: ViewProvider
	) {
		
		self.store = store
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.currentViewControllerItems = [:]
	}
	
	public func setup(with tabBarController: UITabBarController) {
		self.tabBarController = tabBarController
		
		tabBarController.delegate = self
		
		viewStore.publisher
			.sink { [weak self] in
				guard let self = self else { return }
				self.updateViewControllers(newItems: $0.items)
				self.updateSelectedItem($0.activeItem, newItems: $0.items)
			}
			.store(in: &cancellables)
	}
	
	private func updateViewControllers(newItems: [Item]) {
		guard let tabBarController = tabBarController else {
			return
		}
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
			animated: shouldAnimateStackChanges
		)
	}
	
	private var shouldAnimateStackChanges: Bool {
		if tabBarController?.viewControllers?.isEmpty ?? true {
			return false
		} else {
			return UIView.areAnimationsEnabled
		}
	}
	
	private func updateSelectedItem(_ item: Item, newItems: [Item]) {
		guard
			let tabBarController = tabBarController,
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
