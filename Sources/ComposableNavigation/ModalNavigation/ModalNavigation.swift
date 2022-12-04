import UIKit
import ComposableArchitecture

/// `ModalNavigation` models state and actions of a commonly used modal view presentation.
/// Views can be presented with a certain style and dismissed.
public struct ModalNavigation<Item: Equatable>: ReducerProtocol {
	public init() {}
	
	public struct State: Equatable {
		public var styledItem: StyledItem?
		public var areAnimationsEnabled: Bool
		
		public init(
			styledItem: StyledItem? = nil,
			areAnimationsEnabled: Bool = true
		) {
			self.styledItem = styledItem
			self.areAnimationsEnabled = areAnimationsEnabled
		}
	}
	
	public enum Action: Equatable {
		case set(StyledItem?, animated: Bool = true)
		case dismiss(animated: Bool = true)
		case presentFullScreen(Item, animated: Bool = true)
		case presentSheet(Item, animated: Bool = true)
	}
	
	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .set(styledItem, animated):
			setStyledItem(styledItem, on: &state, animated: animated)
		case let .dismiss(animated):
			setStyledItem(nil, on: &state, animated: animated)
		case let .presentFullScreen(item, animated):
			setStyledItem(StyledItem(item: item, style: .fullScreen), on: &state, animated: animated)
		case let .presentSheet(item, animated):
			setStyledItem(StyledItem(item: item, style: .pageSheet), on: &state, animated: animated)
		}
		return .none
	}
	
	private func setStyledItem(_ item: StyledItem?, on state: inout State, animated: Bool) {
		state.styledItem = item
		state.areAnimationsEnabled = animated
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

extension ModalNavigation.StyledItem: Codable where Item: Codable {}
extension ModalNavigation.State: Codable where Item: Codable {}
extension ModalNavigation.Action: Codable where Item: Codable {}
extension UIModalPresentationStyle: Codable {}
