// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "RoutableNavigation",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "RoutableNavigation",
      targets: ["RoutableNavigation"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0")),
    .package(url: "https://github.com/BoltDocs/ObjectAssociationHelper.git", .exact("1.0.0")),
  ],
  targets: [
    .target(
      name: "RoutableNavigation",
      dependencies: [
        .product(name: "RxSwift", package: "RxSwift"),
        .product(name: "RxCocoa", package: "RxSwift"),
        "ObjectAssociationHelper",
      ],
      path: "./RoutableNavigation"
    ),
    .testTarget(
      name: "RoutableNavigationTests",
      dependencies: ["RoutableNavigation"],
      path: "./RoutableNavigationTests"
    ),
  ]
)
