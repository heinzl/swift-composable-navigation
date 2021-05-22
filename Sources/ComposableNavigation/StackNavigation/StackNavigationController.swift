import UIKit
import Combine
import ComposableArchitecture
import OrderedCollections

open class StackNavigationController<ViewProvider: ViewProviding>: UINavigationController, UINavigationControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias ItemStack = StackNavigation<Item>
	
	internal let store: Store<ItemStack.State, ItemStack.Action>
	internal let viewStore: ViewStore<ItemStack.State, ItemStack.Action>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItems: OrderedDictionary<Item, UIViewController>
	
	private var cancellables = Set<AnyCancellable>()
	
	public init(
		store: Store<ItemStack.State, ItemStack.Action>,
		viewProvider: ViewProvider
	) {
		self.store = store
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.currentViewControllerItems = [:]
		
		super.init(nibName: nil, bundle: nil)
		
		self.delegate = self
		
		viewStore.publisher.items
			.sink { [weak self] in
				self?.updateViewControllerStack(newItems: $0)
			}
			.store(in: &cancellables)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func updateViewControllerStack(newItems: [Item]) {
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
		if viewControllers.isEmpty {
			return false
		} else {
			return UIView.areAnimationsEnabled
		}
	}
	
	// MARK: UINavigationControllerDelegate

	open func navigationController(
		_ navigationController: UINavigationController,
		didShow viewController: UIViewController,
		animated: Bool
	) {
		guard
			let transition = navigationController.transitionCoordinator,
			let fromViewController = transition.viewController(forKey: .from),
			let toViewController = transition.viewController(forKey: .to),
			let fromIndex = currentViewControllerItems.values.firstIndex(of: fromViewController),
			let toIndex = currentViewControllerItems.values.firstIndex(of: toViewController),
			toIndex < fromIndex
		else {
			return
		}
		let popCount = fromIndex - toIndex
		currentViewControllerItems.removeLast(popCount)
		viewStore.send(.popItems(count: popCount))
	}
}
