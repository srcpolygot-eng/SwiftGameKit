import Foundation
import SGKCore
import SGKECS
import SGKMath

public protocol Scene: AnyObject {
    var name: String { get }
    var world: World { get }
    func onEnter()
    func onExit()
    func update(deltaTime: Double)
    func fixedUpdate(fixedDeltaTime: Double)
    func render()
}

public extension Scene {
    func onEnter() {}
    func onExit() {}
    func update(deltaTime: Double) {}
    func fixedUpdate(fixedDeltaTime: Double) {}
    func render() {}
}

open class BaseScene: Scene {
    public let name: String
    public let world: World

    public init(name: String = "Scene", initialCapacity: Int = 1024) {
        self.name = name
        self.world = World(initialCapacity: initialCapacity)
    }

    open func onEnter() {}
    open func onExit() {}
    open func update(deltaTime: Double) {
        world.updateSystems(deltaTime: deltaTime)
    }
    open func fixedUpdate(fixedDeltaTime: Double) {}
    open func render() {}
}

public enum SceneTransition: Sendable {
    case instant
    case fade(duration: Double)
    case crossfade(duration: Double)
    case custom(name: String)
}

public final class SceneManager {
    public private(set) var activeScene: (any Scene)?
    public private(set) var isTransitioning = false

    private var nextScene: (any Scene)?
    private var transition: SceneTransition = .instant
    private var transitionProgress: Double = 0
    private var transitionDuration: Double = 0

    public init() {}

    public func load(_ scene: any Scene, transition: SceneTransition = .instant) {
        if activeScene == nil {
            activeScene = scene
            scene.onEnter()
            Log.info("Scene loaded: \(scene.name)")
            return
        }

        nextScene = scene
        self.transition = transition
        isTransitioning = true
        transitionProgress = 0

        switch transition {
        case .instant:
            transitionDuration = 0
            completeTransition()
        case .fade(let d), .crossfade(let d):
            transitionDuration = d
        case .custom:
            transitionDuration = 0.5
        }
    }

    public func update(deltaTime: Double) {
        if isTransitioning {
            transitionProgress += deltaTime
            if transitionProgress >= transitionDuration {
                completeTransition()
            }
        } else {
            activeScene?.update(deltaTime: deltaTime)
        }
    }

    public func fixedUpdate(fixedDeltaTime: Double) {
        if !isTransitioning {
            activeScene?.fixedUpdate(fixedDeltaTime: fixedDeltaTime)
        }
    }

    public func render() {
        activeScene?.render()
    }

    private func completeTransition() {
        activeScene?.onExit()
        activeScene = nextScene
        nextScene = nil
        isTransitioning = false
        transitionProgress = 0
        activeScene?.onEnter()
        if let s = activeScene {
            Log.info("Scene transitioned to: \(s.name)")
        }
    }

    public var transitionAlpha: Float {
        guard isTransitioning, transitionDuration > 0 else { return 0 }
        return Float(min(1, transitionProgress / transitionDuration))
    }
}
