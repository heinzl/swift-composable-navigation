import UIKit
import ComposableArchitecture

/// A convenience UITabBarController implementation containing a `TabNavigationHandler`.
public class TabNavigationViewController<ViewProvider: ViewProviding>: UITabBarController {
	internal let navigationHandler: TabNavigationHandler<ViewProvider>
	
	public convenience init(
		store: StoreOf<TabNavigation<ViewProvider.Item>>,
		viewProvider: ViewProvider
	) {
		self.init(navigationHandler: TabNavigationHandler(store: store, viewProvider: viewProvider))
	}
	
	public init(navigationHandler: TabNavigationHandler<ViewProvider>) {
		self.navigationHandler = navigationHandler
		super.init(nibName: nil, bundle: nil)
		self.navigationHandler.setup(with: self)
	}
	
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
