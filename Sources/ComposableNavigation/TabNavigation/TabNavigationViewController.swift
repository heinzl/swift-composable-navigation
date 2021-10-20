import UIKit
import ComposableArchitecture

public class TabNavigationViewController<ViewProvider: ViewProviding>: UITabBarController {
	internal let navigationHandler: TabNavigationHandler<ViewProvider>
	
	public convenience init(
		store: Store<TabNavigation<ViewProvider.Item>.State, TabNavigation<ViewProvider.Item>.Action>,
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
