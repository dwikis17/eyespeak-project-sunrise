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
                    ],
                    "NSCameraUsageDescription": "This app uses the camera for eye tracking and face detection to provide accessibility features for communication.",
                    "UIAppFonts": [
                        "Montserrat-Regular.ttf",
                        "Montserrat-Medium.ttf",
                        "Montserrat-SemiBold.ttf",
                        "Montserrat-Bold.ttf",
                    ]
                ]
            ),
            sources: ["eyespeak/Sources/**"],
            resources: ["eyespeak/Resources/**",],
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
