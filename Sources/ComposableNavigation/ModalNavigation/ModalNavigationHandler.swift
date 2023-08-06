#if canImport(UIKit)
import Foundation
import UIKit
import Combine
import ComposableArchitecture

/// The `ModalNavigationHandler` listens to state changes and presents the provided views accordingly.
///
/// Additionally, it acts as the `UIAdaptivePresentationControllerDelegate` and automatically updates the state
/// for pull-to-dismiss for views presented as a sheet.
@MainActor
public class ModalNavigationHandler<ViewProvider: ViewProviding>: NSObject, UIAdaptivePresentationControllerDelegate {
	public typealias Item = ViewProvider.Item
	public typealias Navigation = ModalNavigation<Item>
	
	internal let viewStore: ViewStore<Navigation.State, Navigation.Action>
	internal let viewProvider: ViewProvider
	internal var currentViewControllerItem: ViewControllerItem?
	internal let maxWindowWaitingDelay: TimeInterval
	
	private var cancellable: AnyCancellable?
	
	internal struct ViewControllerItem {
		let styledItem: Navigation.StyledItem
		let viewController: UIViewController
	}
	
	public init(
		store: Store<Navigation.State, Navigation.Action>,
		viewProvider: ViewProvider,
		maxWindowWaitingDelay: TimeInterval = 4
	) {
		self.viewStore = ViewStore(store)
		self.viewProvider = viewProvider
		self.maxWindowWaitingDelay = maxWindowWaitingDelay
		self.currentViewControllerItem = nil
	}
	
	public func setup(with presentingViewController: UIViewController) {
		cancellable = viewStore.publisher
			.sink { [weak self, weak presentingViewController] state in
				guard let presentingViewController else { return }
				Task { [weak self] in
					await self?.updateModalViewController(
						newState: state,
						presentingViewController: presentingViewController
					)
				}
			}
	}
	
	internal func updateModalViewController(
		newState: Navigation.State,
		presentingViewController: UIViewController
	) async {
		let newStyledItem = newState.styledItem
		let oldStyledItem = currentViewControllerItem?.styledItem
		guard oldStyledItem != newStyledItem else {
			return
		}
		let animated = shouldAnimateChanges(state: newState)
		switch (oldStyledItem, newStyledItem) {
		case (.some, .none):
			// Dismiss old
			await dismissModal(from: presentingViewController, animated: animated)
		case (.none, .some(let newStyledItem)):
			// Present new
			await presentModal(newStyledItem, on: presentingViewController, animated: animated)
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
			await dismissModal(from: presentingViewController, animated: animated)
			await presentModal(viewController, newStyledItem, on: presentingViewController, animated: animated)
		default:
			break
		}
	}
	
	private func presentModal(
		_ newStyledItem: Navigation.StyledItem,
		on presentingViewController: UIViewController,
		animated: Bool
	) async {
		let viewController = makeViewController(for: newStyledItem)
		await presentModal(viewController, newStyledItem, on: presentingViewController, animated: animated)
	}
	
	private func presentModal(
		_ viewController: UIViewController,
		_ styledItem: Navigation.StyledItem,
		on presentingViewController: UIViewController,
		animated: Bool
	) async {
		await presentingViewController.waitForWindow(
			maxWindowWaitingDelay: maxWindowWaitingDelay
		)
		self.currentViewControllerItem = ViewControllerItem(
			styledItem: styledItem,
			viewController: viewController
		)
		await presentingViewController.present(viewController, animated: animated)
	}
	
	private func makeViewController(for styledItem: Navigation.StyledItem) -> UIViewController {
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
	) async {
		// Prevent dismissal of unrelated view controller
		if presentingViewController.presentedViewController == currentViewControllerItem?.viewController {
			await presentingViewController.dismiss(animated: animated)
		}
		currentViewControllerItem = nil
	}
	
	private func shouldAnimateChanges(state: Navigation.State) -> Bool {
		if !UIView.areAnimationsEnabled {
			return false
		} else {
			return state.areAnimationsEnabled
		}
	}
	
	// MARK: UIAdaptivePresentationControllerDelegate
	
	public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		currentViewControllerItem = nil
		
		Task { @MainActor in
			await Task.yield()
			viewStore.send(.dismiss())
		}
	}
}

internal extension UIViewController {
	func present(_ viewControllerToPresent: UIViewController, animated flag: Bool) async {
		await withCheckedContinuation { continuation in
			present(viewControllerToPresent, animated: flag) {
				continuation.resume()
			}
		}
	}
	
	func dismiss(animated flag: Bool) async {
		await withCheckedContinuation { continuation in
			dismiss(animated: flag) {
				continuation.resume()
			}
		}
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
			if let action {
				ViewStore(store).send(action)
			}
		}
	}
}
#endif
