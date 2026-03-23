// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rumo",
    defaultLocalization: "pt-BR",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "RumoCore",
            targets: ["RumoCore"]
        ),
    ],
    dependencies: [
        // Supabase SDK for Auth, Database, Storage, and Realtime
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            from: "2.0.0"
        ),

        // Sentry for crash reporting
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            from: "8.0.0"
        ),

        // TelemetryDeck for privacy-focused analytics
        .package(
            url: "https://github.com/TelemetryDeck/SwiftClient.git",
            from: "1.5.0"
        ),

        // Markdown rendering for journal notes
        .package(
            url: "https://github.com/gonzalezreal/swift-markdown-ui.git",
            from: "2.0.0"
        ),

        // Keychain wrapper for secure storage
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            from: "4.2.0"
        ),
    ],
    targets: [
        // Core library shared between main app and extensions
        .target(
            name: "RumoCore",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Sentry", package: "sentry-cocoa"),
                .product(name: "TelemetryClient", package: "SwiftClient"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ],
            path: "Rumo/Core"
        ),
        .testTarget(
            name: "RumoCoreTests",
            dependencies: ["RumoCore"],
            path: "RumoTests/CoreTests"
        ),
    ]
)
