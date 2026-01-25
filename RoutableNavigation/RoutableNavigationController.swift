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

import UIKit

import RxSwift

public enum RoutingAction<Element: RouteElement> {
  case push(element: Element)
  case pop
  case replaceRoot(element: Element)
}

open class RoutableNavigationController<Element: RouteElement>: UINavigationController {

  private var disposeBag = DisposeBag()

  public let coordinator: NavigationRouteCoordinator<Element>

  public init(coordinator: NavigationRouteCoordinator<Element>) {
    self.coordinator = coordinator
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  // swiftlint:disable:next unavailable_function
  open func viewController(forRouteElement element: Element) -> UIViewController? {
    fatalError("viewController(forRouteElement:) is meant be implemented by subclass")
  }

  open override func viewDidLoad() {
    super.viewDidLoad()

    rx.willShow.map { $0.viewController }
      .withLatestFrom(coordinator.currentRoute) { topViewController, currentHashes in
        return (topViewController, currentHashes.elements.map { $0.routeHash })
      }
      .subscribe(with: self) { owner, val in
        let (willShowController, currentHashes) = val

        let controllerHashes = owner.viewControllers.map { $0.routeHash }
        print("[RoutableNav]: Did received controller change, State hashes: \(currentHashes),  Controller hashes: \(controllerHashes)")

        if controllerHashes != currentHashes {
          print("[RoutableNav]: Route not match, performing adjustment")
          if
            Array(currentHashes[0..<(currentHashes.endIndex - 1)]) == controllerHashes,
            willShowController.routeHash == controllerHashes.last
          {
            // Adjustment type 1: the user popped the topmost controller
            print("[RoutableNav]: Topmost controller popped by user, syncing state change")
            owner.coordinator.pop(performsSideEffect: false)
          } else {
            // Other cases that cannot be handled
            assertionFailure("Cannot perform route adjustment, route state can be corrupted")
          }
        }
      }
      .disposed(by: disposeBag)

    coordinator.routingActions
      .emit(with: self) { owner, actions  in
        let destViewControllers = actions.reduce(owner.viewControllers) { viewControllers, action in
          var viewControllers = viewControllers
          switch action {
          case .pop:
            viewControllers.removeLast()
          case .push(let element):
            if let destViewController = owner.viewController(forRouteElement: element) {
              assert(destViewController.routeHash != nil)
              viewControllers.append(destViewController)
            }
          case .replaceRoot(let element):
            if let destViewController = owner.viewController(forRouteElement: element) {
              assert(destViewController.routeHash != nil)
              viewControllers = [destViewController]
            }
          }
          return viewControllers
        }
        // Disable animation to prevent random ordered controllers on delegate calls
        owner.setViewControllers(destViewControllers, animated: false)
      }
      .disposed(by: disposeBag)
  }

}
