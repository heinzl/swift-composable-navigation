import Foundation
import UIKit
import ComposableNavigation
import ComposableArchitecture

/// This example showcases a combination of navigation patterns including:
/// - tab navigation
/// - statck navigation (list/detail)
/// - modal navigation (incl. alerts)
/// - deep linking
struct AdvancedShowcase {
	static func makeView(_ store: Store<AdvancedTabBar.State, AdvancedTabBar.Action>) -> UIViewController {
		AdvancedTabBar.makeView(store)
	}
}
