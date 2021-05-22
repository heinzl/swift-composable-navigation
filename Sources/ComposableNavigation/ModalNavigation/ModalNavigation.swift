import UIKit
import ComposableArchitecture

public struct ModalNavigation<Item: Equatable> {
	public struct State: Equatable {
		public var styledItem: StyledItem?
		
		public init(styledItem: StyledItem? = nil) {
			self.styledItem = styledItem
		}
	}
	
	public enum Action: Equatable {
		case set(StyledItem?)
		case dismiss
		case presentFullScreen(Item)
		case presentSheet(Item)
	}
	
	public static func reducer() -> Reducer<State, Action, Void> {
		Reducer { state, action, _ in
			switch action {
			case .set(let styledItem):
				state.styledItem = styledItem
			case .dismiss:
				state.styledItem = nil
			case .presentFullScreen(let item):
				return .init(value: .set(StyledItem(item: item, style: .fullScreen)))
			case .presentSheet(let item):
				return .init(value: .set(StyledItem(item: item, style: .pageSheet)))
			}
			return .none
		}
	}
	
	public struct StyledItem: Equatable {
		public let item: Item
		public let style: UIModalPresentationStyle
		
		public init(item: Item, style: UIModalPresentationStyle) {
			self.item = item
			self.style = style
		}
	}
}
