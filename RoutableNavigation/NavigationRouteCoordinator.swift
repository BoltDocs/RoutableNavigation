/*
 * MIT License
 * 
 * Copyright (c) 2022 Ethan Wong
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import RxCocoa
import RxSwift

public final class NavigationRouteCoordinator<Element: RouteElement> {

  public var currentRoute: Driver<Route<Element>> {
    return _currentRoute
      .asDriver()
      .map { $0.0 }
  }

  var routingActions: Signal<[RoutingAction<Element>]> {
    return _routingActions.asSignal()
  }

  private lazy var _currentRoute = BehaviorRelay<(Route<Element>, Bool)>(value: (Route([]), false))

  private lazy var _routingActions = PublishRelay<[RoutingAction<Element>]>()

  private var disposeBag = DisposeBag()

  public init() {
    _currentRoute
      .withPrevious(startWith: nil)
      .map { previous, current in
        if current.1 == true {
          return Self.routingActionsForTransition(
            from: previous?.0.elements ?? [],
            to: current.0.elements
          )
        }
        return []
      }
      .bind(to: _routingActions)
      .disposed(by: disposeBag)
  }

  public func changeRoute(_ route: [Element], performsSideEffect: Bool = true) {
    _currentRoute.accept((Route(route), performsSideEffect))
  }

  public func push(_ element: Element, performsSideEffect: Bool = true) {
    var oldRoute = _currentRoute.value.0.elements
    oldRoute.append(element)
    changeRoute(oldRoute, performsSideEffect: performsSideEffect)
  }

  public func pop(performsSideEffect: Bool = true) {
    var oldRoute = _currentRoute.value.0.elements
    oldRoute.removeLast()
    changeRoute(oldRoute, performsSideEffect: performsSideEffect)
  }

  private static func routingActionsForTransition(
    from oldRoute: [Element],
    to newRoute: [Element]
  ) -> [RoutingAction<Element>] {
    func calcCommonSubrouteCount(oldRoute: [Element], newRoute: [Element]) -> Int {
      var commonSubrouteCount = 0
      while
        commonSubrouteCount < newRoute.count &&
        commonSubrouteCount < oldRoute.count &&
        newRoute[commonSubrouteCount] == oldRoute[commonSubrouteCount]
      {
        commonSubrouteCount += 1
      }
      return commonSubrouteCount
    }

    let commonSubrouteCount = calcCommonSubrouteCount(oldRoute: oldRoute, newRoute: newRoute)

    var routingActions = [RoutingAction<Element>]()

    if commonSubrouteCount == 0 && newRoute.isEmpty {
      routingActions.append(.replaceRoot(element: newRoute.first!))
      routingActions.append(
        contentsOf: newRoute[1...].map { RoutingAction.push(element: $0) }
      )
    } else {
      routingActions.append(
        contentsOf: [RoutingAction<Element>](
          repeating: .pop,
          count: oldRoute.count - commonSubrouteCount
        )
      )
      routingActions.append(
        contentsOf: newRoute[(commonSubrouteCount)...].map { RoutingAction.push(element: $0) }
      )
    }
    return routingActions
  }

}
