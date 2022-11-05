import Foundation
import UIKit

internal extension UIViewController {
	@MainActor
	func waitForWindow(maxWindowWaitingDelay: TimeInterval) async {
		var accumulatedDelay = 0.0
		let delay = 0.01
		while view.window == nil && accumulatedDelay < maxWindowWaitingDelay {
			try? await Task.sleep(nanoseconds: UInt64(Double(NSEC_PER_SEC) * delay))
			accumulatedDelay += delay
		}
		#if DEBUG
		if accumulatedDelay >= maxWindowWaitingDelay {
			print("""
			ComposableNavigation WARNING: \(self) is not in the window hierarchy after waiting \(maxWindowWaitingDelay) seconds. Navigation could not be completed.
			""")
		}
		#endif
	}
}
