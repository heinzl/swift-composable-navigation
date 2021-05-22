import UIKit
import Combine
import OrderedCollections
import ComposableArchitecture

open class TabNavigationController<ViewProvider: ViewProviding>: UITabBarController, UITabBarControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias ItemTabs = TabNavigation<Item>
	
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
		
		super.init(nibName: nil, bundle: nil)
		
		self.delegate = self
		
		viewStore.publisher
			.sink { [weak self] in
				guard let self = self else { return }
				self.updateViewControllers(newItems: $0.items)
				self.updateSelectedItem($0.activeItem, newItems: $0.items)
			}
			.store(in: &cancellables)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func updateViewControllers(newItems: [Item]) {
		let oldItems = Array(currentViewControllerItems.keys)
		
		guard oldItems != newItems else {
			return
		}
		
		currentViewControllerItems = ReorderUtil.rearrangingItems(
			newItems: newItems,
			currentViewControllerItems: currentViewControllerItems,
			viewProvider: viewProvider
		)
		
		setViewControllers(
			Array(currentViewControllerItems.values),
			animated: shouldAnimateStackChanges
		)
	}
	
	private var shouldAnimateStackChanges: Bool {
		if viewControllers?.isEmpty ?? true {
			return false
		} else {
			return UIView.areAnimationsEnabled
		}
	}
	
	private func updateSelectedItem(_ item: Item, newItems: [Item]) {
		guard let index = newItems.firstIndex(of: item), selectedIndex != index else {
			return
		}
		selectedIndex = index
	}
	
	// MARK: UITabBarControllerDelegate
	
	open func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		guard let index = currentViewControllerItems.values.firstIndex(of: viewController)
		else {
			return
		}
		viewStore.send(.setActiveIndex(index))
	}
}
