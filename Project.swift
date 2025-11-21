import ProjectDescription

// Scheme wiring so OPENAI_API_KEY survives `tuist generate`.
// Replace the empty string with your key locally (or set it as a user override in Xcode).
private let openAIRunArguments = Arguments.arguments(
    environmentVariables: [
        "OPENAI_API_KEY": EnvironmentVariable.environmentVariable(value: "", isEnabled: true)
    ]
)

private let openAISecretsSettings = Settings(
    base: [:],
    configurations: [
        .debug(name: "Debug", settings: [:], xcconfig: "Config/OpenAISecrets.xcconfig"),
        .release(name: "Release", settings: [:], xcconfig: "Config/OpenAISecrets.xcconfig")
    ],
    defaultSettings: .recommended
)

let project = Project(
    name: "eyespeak",
    targets: [
        .target(
            name: "eyespeak",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.eyespeakapp",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    // iPhone orientations
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight",
                    ],
                    "UISupportedInterfaceOrientations~ipad" : [
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight",
                    ],
                    // Require full screen to avoid iPad multitasking orientation requirements
                    "UIRequiresFullScreen": true,
                    "NSCameraUsageDescription": "This app uses the camera for eye tracking and face detection to provide accessibility features for communication.",
                    "OPENAI_API_KEY": "$(OPENAI_API_KEY)",
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
            dependencies: [],
            settings: openAISecretsSettings
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
    ],
    schemes: [
        Scheme.scheme(
            name: "eyespeak-OpenAI",
            shared: true,
            buildAction: .buildAction(targets: ["eyespeak"]),
            testAction: .targets(["eyespeakTests"]),
            runAction: .runAction(
                configuration: .debug,
                arguments: openAIRunArguments
            )
        )
    ]
)
