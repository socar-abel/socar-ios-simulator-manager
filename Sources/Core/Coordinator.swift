import SwiftUI

// MARK: - Coordinator Protocol

public protocol Coordinator: AnyObject, Observable {
    var childCoordinators: [any Coordinator] { get set }
    func childDidFinish(_ child: any Coordinator)
}

public extension Coordinator {
    func childDidFinish(_ child: any Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }

    func addChild(_ child: any Coordinator) {
        childCoordinators.append(child)
    }

    func find<T: Coordinator>(childType: T.Type) -> T? {
        childCoordinators.first { $0 is T } as? T
    }
}

// MARK: - Route Coordinator

public protocol RouteCoordinator: Coordinator {
    associatedtype Route: Hashable
    func navigate(to route: Route)
}

// MARK: - Non-Route Coordinator

public protocol NonRouteCoordinator: Coordinator {
    func start()
}
