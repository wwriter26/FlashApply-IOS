// swift-tools-version: 5.9
// FlashApply iOS — Swift Package Manager Dependencies
// Add these via Xcode → File → Add Package Dependencies

import PackageDescription

let package = Package(
    name: "FlashApply",
    platforms: [.iOS(.v16)],
    dependencies: [
        // AWS Amplify iOS (Auth + Storage)
        .package(
            url: "https://github.com/aws-amplify/amplify-swift",
            from: "2.0.0"
        ),
        // Stripe iOS SDK
        .package(
            url: "https://github.com/stripe/stripe-ios",
            from: "23.0.0"
        ),
    ],
    targets: [
        .target(
            name: "FlashApply",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "AWSS3StoragePlugin", package: "amplify-swift"),
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
            ]
        ),
    ]
)
