import UIKit
import Combine
import ComposableArchitecture
import OrderedCollections

/// The `StackNavigationHandler` listens to state changes and updates the UINavigationController accordingly.
///
/// It also supports automatic state updates for popping items via the leading-edge swipe gesture or the long press back-button menu.
@MainActor
public class StackNavigationHandler<ViewProvider: ViewProviding>: NSObject, UINavigationControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias Navigation = StackNavigation<Item>
	
	internal let viewStore: ViewStore<Navigation.State, Navigation.Action>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItems: OrderedDictionary<Item, UIViewController>
	
	private var cancellable: AnyCancellable?
	
	public init(
		store: Store<Navigation.State, Navigation.Action>,
		viewProvider: ViewProvider
	) {
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.currentViewControllerItems = [:]
	}
	
	public func setup(with navigationController: UINavigationController) {
		navigationController.delegate = self
		
		cancellable = viewStore.publisher
			.sink { [weak self, weak navigationController] state in
				guard let self, let navigationController else { return }
				self.updateViewControllerStack(
					newState: state,
					for: navigationController
				)
			}
	}
	
	private func updateViewControllerStack(
		newState: Navigation.State,
		for navigationController: UINavigationController
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
		
		navigationController.setViewControllers(
			Array(currentViewControllerItems.values),
			animated: shouldAnimateStackChanges(for: navigationController, state: newState)
		)
	}
	
	private func shouldAnimateStackChanges(
		for navigationController: UINavigationController,
		state: Navigation.State
	) -> Bool {
		if navigationController.viewControllers.isEmpty {
			return false
		} else if !UIView.areAnimationsEnabled {
			return false
		} else {
			return state.areAnimationsEnabled
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
		
		Task { @MainActor in
			await Task.yield()
			viewStore.send(.popItems(count: popCount))
		}
	}
}
