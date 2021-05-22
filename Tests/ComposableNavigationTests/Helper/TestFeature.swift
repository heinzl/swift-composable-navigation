import Foundation
import SwiftUI
@testable import ComposableNavigation

class ItemViewProvider: ViewProviding {
	var viewsCreatedFrom = [Int]()
	
	func makePresentable(for navigationItem: Int) -> Presentable {
		viewsCreatedFrom.append(navigationItem)
		return ItemView(item: navigationItem)
	}
}

struct ItemView: View, Presentable {
	let item: Int
	
	var body: some View {
		Text("\(item)")
	}
}
