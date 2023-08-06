#if canImport(ComposableArchitecture)
import ComposableArchitecture

public extension Store where State: Equatable {
	func compactMap<NonOptionalState, Unwrapped>(
		_ transform: (Store<NonOptionalState, Action>) -> Unwrapped
	) -> Unwrapped? where State == NonOptionalState? {
		if var state = ViewStore(self).state {
			return transform(self.scope {
				state = $0 ?? state
				return state
			})
		} else {
			return nil
		}
	}
}
#endif
