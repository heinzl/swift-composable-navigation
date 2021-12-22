import UIKit
import Combine
import ComposableArchitecture

/// The `ModalNavigationHandler` listens to state changes and presents the provided views accordingly.
///
/// Additionally, it acts as the `UIAdaptivePresentationControllerDelegate` and automatically updates the state
/// for pull-to-dismiss for views presented as a sheet.
public class ModalNavigationHandler<ViewProvider: ViewProviding>: NSObject, UIAdaptivePresentationControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias ModalItemNavigation = ModalNavigation<Item>
	
	internal let viewStore: ViewStore<ModalItemNavigation.State, ModalItemNavigation.Action>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItem: ViewControllerItem?
	
	private var cancellable: AnyCancellable?
	
	internal struct ViewControllerItem {
		let styledItem: ModalItemNavigation.StyledItem
		let viewController: UIViewController
	}
	
	public init(
		store: Store<ModalItemNavigation.State, ModalItemNavigation.Action>,
		viewProvider: ViewProvider
	) {
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.currentViewControllerItem = nil
	}
	
	public func setup(with presentingViewController: UIViewController) {
		cancellable = viewStore.publisher
			.sink { [weak self, weak presentingViewController] in
				guard let self = self, let presentingViewController = presentingViewController else { return }
				self.updateModalViewController(
					newState: $0,
					presentingViewController: presentingViewController
				)
			}
	}
	
	private func updateModalViewController(
		newState: ModalItemNavigation.State,
		presentingViewController: UIViewController
	) {
		let newStyledItem = newState.styledItem
		let oldStyledItem = currentViewControllerItem?.styledItem
		guard oldStyledItem != newStyledItem else {
			return
		}
		let animated = shouldAnimateChanges(state: newState)
		switch (oldStyledItem, newStyledItem) {
		case (.some, .none):
			// Dismiss old
			dismissModal(from: presentingViewController, animated: animated)
		case (.none, .some(let newStyledItem)):
			// Present new
			presentModal(newStyledItem, on: presentingViewController, animated: animated)
		case (.some(let oldStyledItem), .some(let newStyledItem)):
			// Dismiss old, present new
			let viewController: UIViewController
			if oldStyledItem.item == newStyledItem.item {
				// Same item use -> use same viewController
				// Only presentation style changed
				viewController = currentViewControllerItem!.viewController
				viewController.modalPresentationStyle = newStyledItem.style
			} else {
				viewController = makeViewController(for: newStyledItem)
			}
			dismissModal(from: presentingViewController, animated: animated)
			presentModal(viewController, newStyledItem, on: presentingViewController, animated: animated)
		default:
			break
		}
	}
	
	private func presentModal(
		_ newStyledItem: ModalItemNavigation.StyledItem,
		on presentingViewController: UIViewController,
		animated: Bool
	) {
		let viewController = makeViewController(for: newStyledItem)
		presentModal(viewController, newStyledItem, on: presentingViewController, animated: animated)
	}
	
	private func presentModal(
		_ viewController: UIViewController,
		_ styledItem: ModalItemNavigation.StyledItem,
		on presentingViewController: UIViewController,
		animated: Bool
	) {
		presentingViewController.present(viewController, animated: animated, completion: nil)
		
		currentViewControllerItem = ViewControllerItem(
			styledItem: styledItem,
			viewController: viewController
		)
	}
	
	private func makeViewController(for styledItem: ModalItemNavigation.StyledItem) -> UIViewController {
		let viewController = viewProvider.makeViewController(for: styledItem.item)
		viewController.modalPresentationStyle = styledItem.style
		if !(viewController is UIAlertController) {
			// UIAlertController won't allow changes to the delegate (app crashes)
			viewController.presentationController?.delegate = self
		}
		return viewController
	}
	
	private func dismissModal(
		from presentingViewController: UIViewController,
		animated: Bool
	) {
		// Prevent dismissal of unrelated view controller
		if presentingViewController.presentedViewController == currentViewControllerItem?.viewController {
			presentingViewController.dismiss(animated: animated, completion: nil)
		}
		currentViewControllerItem = nil
	}
	
	private func shouldAnimateChanges(state: ModalItemNavigation.State) -> Bool {
		if !UIView.areAnimationsEnabled {
			return false
		} else {
			return state.areAnimationsEnabled
		}
	}
	
	// MARK: UIAdaptivePresentationControllerDelegate
	
	public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		currentViewControllerItem = nil
		viewStore.send(.dismiss())
	}
}

public extension UIAlertAction {
	
	/// Create and return an action with the specified title and action.
	///
	/// This convenience initializer sends the provided action to the view store and
	/// updates the modal navigation state (sends `.dismiss`). This is necessary because
	/// `UIAlertController` dismisses itself automatically.
	convenience init<State: Equatable, Action, Item: Hashable>(
		title: String?,
		style: UIAlertAction.Style,
		action: Action? = nil,
		store: Store<State, Action>,
		toNavigationAction: @escaping (ModalNavigation<Item>.Action) -> Action
	) {
		self.init(title: title, style: style) { _ in
			let statelessNavigationState = store.stateless.scope(
				state: { _ in () },
				action: toNavigationAction
			)
			ViewStore(statelessNavigationState).send(.dismiss())
			if let action = action {
				ViewStore(store).send(action)
			}
		}
	}
}
