import SwiftUI
import Bow
import BowEffects
import BowOptics

public struct EffectStoreComponent<Eff: Async & UnsafeRun, E, S, I, V: View>: View {
    private let componentView: EffectComponentView<Eff, StorePartial<S>, StatePartial<S>, I, V>
    private let initialState: S
    private let environment: E
    private let dispatcher: EffectStateDispatcher<Eff, E, S, I>
    private let viewBuilder: (S, @escaping (I) -> Void) -> V
    
    public init(
        initialState: S,
        environment: E,
        dispatcher: EffectStateDispatcher<Eff, E, S, I>  = .empty(),
        render: @escaping (S, @escaping (I) -> Void) -> V
    ) {
        self.initialState = initialState
        self.environment = environment
        self.dispatcher = dispatcher
        self.viewBuilder = render
        self.componentView = EffectComponentView(
            EffectComponent(
                Store(initialState) { state in
                    UI { handler in
                        render(state, dispatcher.dispatch(to: handler, environment: environment))
                    }
                },
                Pairing.pairStateStore())
        )
    }
    
    public var body: some View {
        self.componentView
    }
    
    public func lift<E2, S2, I2>(
        initialState: S2,
        environment: E2,
        transformEnvironment f: @escaping (E2) -> E,
        transformState lens: Lens<S2, S>,
        transformInput prism: Prism<I2, I>
    ) -> EffectStoreComponent<Eff, E2, S2, I2, V> {
        EffectStoreComponent<Eff, E2, S2, I2, V>(
            initialState: initialState,
            environment: environment,
            dispatcher: self.dispatcher.widen(
                transformEnvironment: f,
                transformState: lens,
                transformInput: prism),
            render: { state, handle in
                self.viewBuilder(
                    lens.get(state),
                    (prism.reverseGet >>> handle))
            })
    }
    
    public func lift<E2>(
        environment: E2,
        transformEnvironment f: @escaping (E2) -> E
    ) -> EffectStoreComponent<Eff, E2, S, I, V> {
        self.lift(
            initialState: self.initialState,
            environment: environment,
            transformEnvironment: f,
            transformState: Lens.identity,
            transformInput: Prism.identity)
    }
    
    public func lift<S2>(
        initialState: S2,
        transformState lens: Lens<S2, S>
    ) -> EffectStoreComponent<Eff, E, S2, I, V> {
        self.lift(
            initialState: initialState,
            environment: self.environment,
            transformEnvironment: { $0 },
            transformState: lens,
            transformInput: Prism.identity)
    }
    
    public func lift<I2>(
        transformInput prism: Prism<I2, I>
    ) -> EffectStoreComponent<Eff, E, S, I2, V> {
        self.lift(
            initialState: self.initialState,
            environment: self.environment,
            transformEnvironment: { $0 },
            transformState: Lens.identity,
            transformInput: prism)
    }
    
    public func lift<E2, S2>(
        initialState: S2,
        environment: E2,
        transformEnvironment f: @escaping (E2) -> E,
        transformState lens: Lens<S2, S>
    ) -> EffectStoreComponent<Eff, E2, S2, I, V> {
        self.lift(
            initialState: initialState,
            environment: environment,
            transformEnvironment: f,
            transformState: lens,
            transformInput: Prism.identity)
    }
    
    public func lift<E2, I2>(
        environment: E2,
        transformEnvironment f: @escaping (E2) -> E,
        transformInput prism: Prism<I2, I>
    ) -> EffectStoreComponent<Eff, E2, S, I2, V> {
        self.lift(
            initialState: self.initialState,
            environment: environment,
            transformEnvironment: f,
            transformState: Lens.identity,
            transformInput: prism)
    }
    
    public func lift<S2, I2>(
        initialState: S2,
        transformState lens: Lens<S2, S>,
        transformInput prism: Prism<I2, I>
    ) -> EffectStoreComponent<Eff, E, S2, I2, V> {
        self.lift(
            initialState: initialState,
            environment: self.environment,
            transformEnvironment: { $0 },
            transformState: lens,
            transformInput: prism)
    }
    
    public func using(
        _ handle: @escaping (I) -> Void
    ) -> EffectStoreComponent<Eff, E, S, I, V> {
        EffectStoreComponent(
            initialState: self.initialState,
            environment: self.environment,
            dispatcher: self.dispatcher,
            render: { state, _ in
                self.viewBuilder(
                    state,
                    handle)
            })
    }
}

public extension EffectStoreComponent {
    func store() -> Store<S, UI<Eff, StatePartial<S>, V>>{
        self.componentView.component.wui^
    }
}

public extension EffectStoreComponent where E == Any {
    init(
        initialState: S,
        dispatcher: EffectStateDispatcher<Eff, Any, S, I> = .empty(),
        render: @escaping (S, @escaping (I) -> Void) -> V
    ) {
        self.init(
            initialState: initialState,
            environment: (),
            dispatcher: dispatcher,
            render: render)
    }
}
