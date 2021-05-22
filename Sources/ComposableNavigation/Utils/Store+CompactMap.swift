import ComposableArchitecture

public extension Store where State: Equatable {
	func compactMap<NonOptionalState, Unwrapped>(
		_ transform: (Store<NonOptionalState, Action>) -> Unwrapped
	) -> Unwrapped? where State == NonOptionalState? {
		guard let state = ViewStore(self).state else {
			return nil
		}
		return transform(self.scope { $0 ?? state })
	}
}
