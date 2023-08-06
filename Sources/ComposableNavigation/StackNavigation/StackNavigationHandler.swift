#if canImport(UIKit)
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
	
	/// This field can be set to `true` if `StackNavigationHandler` is used
	/// on top of an already existing `UINavigationController` containing view controllers
	/// which are not managed by `StackNavigationHandler`
	public let ignorePreviousViewControllers: Bool

	public init(
		store: Store<Navigation.State, Navigation.Action>,
		viewProvider: ViewProvider,
		ignorePreviousViewControllers: Bool = false
	) {
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.ignorePreviousViewControllers = ignorePreviousViewControllers
		self.currentViewControllerItems = [:]
	}
	
	public func setup(with navigationController: UINavigationController) {
		navigationController.delegate = self
		let numberOfViewControllersOnStackToIgnore = numberOfViewControllersOnStackToIgnore(for: navigationController)

		cancellable = viewStore.publisher
			.sink { [weak self, weak navigationController] state in
				guard let self, let navigationController else { return }
				self.checkNavigationControllerDelegate(navigationController)
				self.updateViewControllerStack(
					newState: state,
					for: navigationController,
					numberOfViewControllersOnStackToIgnore: numberOfViewControllersOnStackToIgnore
				)
			}
	}
	
	internal func updateViewControllerStack(
		newState: Navigation.State,
		for navigationController: UINavigationController,
		numberOfViewControllersOnStackToIgnore: Int
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
		
		let viewControllerToIgnore = Array(navigationController.viewControllers.prefix(
			upTo: numberOfViewControllersOnStackToIgnore
		))
		let updatedViewControllers = Array(currentViewControllerItems.values)

		navigationController.setViewControllers(
			viewControllerToIgnore + updatedViewControllers,
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
	
	internal func numberOfViewControllersOnStackToIgnore(
		for navigationController: UINavigationController
	) -> Int {
		guard ignorePreviousViewControllers else {
			return 0
		}
		return navigationController.viewControllers.count
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
			let toViewController = transition.viewController(forKey: .to)
		else {
			return
		}
		/// If `StackNavigationHandler` is used with un-managed view controllers
		/// (see `ignorePreviousViewControllers`) we want to be able to pop to these view controllers.
		/// Popping the the last managed view controller will result in a `toIndex` of -1 and a `fromIndex`
		/// of 0 which will result in a `popCount` of 1.
		let toIndex = currentViewControllerItems.values.firstIndex(of: toViewController) ?? -1
		guard
			let fromIndex = currentViewControllerItems.values.firstIndex(of: fromViewController),
			toIndex < fromIndex
		else {
			return
		}
		let popCount = max(fromIndex - toIndex, 0)
		currentViewControllerItems.removeLast(popCount)

		Task { @MainActor in
			await Task.yield()
			viewStore.send(.popItems(count: popCount))
		}
	}

	private func checkNavigationControllerDelegate(_ navigationController: UINavigationController) {
		#if DEBUG
		guard navigationController.delegate !== self else {
			return
		}
		let delegateString: String
		if let delegate = navigationController.delegate {
			delegateString = String(describing: delegate)
		} else {
			delegateString = "nil"
		}
		print("""
		WARNING: ComposableNavigation: StackNavigationHandler \(self) is not delegate of the UINavigationController \(navigationController).
		The delegate is now \(delegateString). Make sure that the delegate is not changed when the StackNavigationHandler is active.
		""")
		#endif
	}
}
#endif
