import UIKit
import Combine
import ComposableArchitecture
import OrderedCollections

public class StackNavigationHandler<ViewProvider: ViewProviding>: NSObject, UINavigationControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias ItemStack = StackNavigation<Item>
	
	internal weak var navigationController: UINavigationController?
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
	}
	public func setup(with navigationController: UINavigationController) {
		self.navigationController = navigationController
		
		navigationController.delegate = self
		
		viewStore.publisher.items
			.sink { [weak self] in
				self?.updateViewControllerStack(newItems: $0)
			}
			.store(in: &cancellables)
	}
	
	private func updateViewControllerStack(newItems: [Item]) {
		guard let navigationController = navigationController else {
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
		
		navigationController.setViewControllers(
			Array(currentViewControllerItems.values),
			animated: shouldAnimateStackChanges
		)
	}
	
	private var shouldAnimateStackChanges: Bool {
		if navigationController?.viewControllers.isEmpty ?? true {
			return false
		} else {
			return UIView.areAnimationsEnabled
		}
	}
	
	// MARK: UINavigationControllerDelegate

	public func navigationController(
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
