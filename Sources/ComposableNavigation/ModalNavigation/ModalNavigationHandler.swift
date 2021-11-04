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
		cancellable = viewStore.publisher.styledItem
			.sink { [weak self] in
				self?.updateModalViewController(
					newStyledItem: $0,
					presentingViewController: presentingViewController
				)
			}
	}
	
	private func updateModalViewController(
		newStyledItem: ModalItemNavigation.StyledItem?,
		presentingViewController: UIViewController
	) {
		let oldStyledItem = currentViewControllerItem?.styledItem
		guard oldStyledItem != newStyledItem else {
			return
		}
		switch (oldStyledItem, newStyledItem) {
		case (.some, .none):
			// Dismiss old
			dimissModal(from: presentingViewController)
		case (.none, .some(let newStyledItem)):
			// Present new
			presentModal(newStyledItem, on: presentingViewController)
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
			dimissModal(from: presentingViewController)
			presentModal(viewController, newStyledItem, on: presentingViewController)
		default:
			break
		}
	}
	
	private func presentModal(
		_ newStyledItem: ModalItemNavigation.StyledItem,
		on presentingViewController: UIViewController
	) {
		let viewController = makeViewController(for: newStyledItem)
		presentModal(viewController, newStyledItem, on: presentingViewController)
	}
	
	private func presentModal(
		_ viewController: UIViewController,
		_ styledItem: ModalItemNavigation.StyledItem,
		on presentingViewController: UIViewController
	) {
		presentingViewController.present(viewController, animated: shouldAnimateModalChanges, completion: nil)
		
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
	
	private func dimissModal(from presentingViewController: UIViewController) {
		// Prevent dismissal of unrelated view controller
		if presentingViewController.presentedViewController == currentViewControllerItem?.viewController {
			presentingViewController.dismiss(animated: shouldAnimateModalChanges, completion: nil)
		}
		currentViewControllerItem = nil
	}
	
	private var shouldAnimateModalChanges: Bool {
		UIView.areAnimationsEnabled
	}
	
	// MARK: UIAdaptivePresentationControllerDelegate
	
	public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		currentViewControllerItem = nil
		viewStore.send(.dismiss)
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
			ViewStore(statelessNavigationState).send(.dismiss)
			if let action = action {
				ViewStore(store).send(action)
			}
		}
	}
}
