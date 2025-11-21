import SwiftUI

enum AppFont {
    enum Montserrat {
        static func regular(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
            .custom("Montserrat-Regular", size: size, relativeTo: textStyle)
        }
        static func medium(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
            .custom("Montserrat-Medium", size: size, relativeTo: textStyle)
        }
        static func semibold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
            .custom("Montserrat-SemiBold", size: size, relativeTo: textStyle)
        }
        static func bold(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
            .custom("Montserrat-Bold", size: size, relativeTo: textStyle)
        }
    }
}

enum Typography {
    private static func scale() -> CGFloat {
        let fontScaleRaw = UserDefaults.standard.string(forKey: "fontScale") ?? "medium"
        let fontScale = FontScale(rawValue: fontScaleRaw) ?? .medium
        return fontScale.multiplier
    }
    
    //Title
    static var boldHeaderLarge: Font {
        AppFont.Montserrat.bold(38 * scale(), relativeTo: .largeTitle)
    }
    static var boldHeaderJumbo: Font {
        AppFont.Montserrat.bold(64 * scale(), relativeTo: .largeTitle)
    }
    
    // Headers (18pt)
    static var boldHeader: Font {
        AppFont.Montserrat.bold(18 * scale(), relativeTo: .title3)
    }
    
    static var regularHeader: Font {
        AppFont.Montserrat.regular(18 * scale(), relativeTo: .title3)
    }

    // Titles (14pt)
    static var boldTitle: Font {
        AppFont.Montserrat.bold(14 * scale(), relativeTo: .body)
    }
    static var regularTitle: Font {
        AppFont.Montserrat.regular(14 * scale(), relativeTo: .body)
    }

    // Body (9pt)
    static var boldBody: Font {
        AppFont.Montserrat.bold(9 * scale(), relativeTo: .caption2)
    }
    static var regularBody: Font {
        AppFont.Montserrat.regular(9 * scale(), relativeTo: .caption2)
    }

    // Keyboard
    static var keyboardMedium: Font {
        AppFont.Montserrat.medium(28 * scale(), relativeTo: .title)
    }
    
    // Card title font (scaled headline)
    // Testing
    static var cardTitle: Font {
        AppFont.Montserrat.semibold(17 * scale(), relativeTo: .headline)
    }
}
