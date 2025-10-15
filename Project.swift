import ProjectDescription

let project = Project(
    name: "eyespeak",
    targets: [
        .target(
            name: "eyespeak",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.eyespeak",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "UISupportedInterfaceOrientations~ipad" : [
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight",
                    ]
                ]
            ),
            sources: ["eyespeak/Sources/**"],
            resources: ["eyespeak/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "eyespeakTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.eyespeakTests",
            infoPlist: .default,
            sources: ["eyespeak/Tests/**"],
            resources: [],
            dependencies: [.target(name: "eyespeak")]
        ),
    ]
)
