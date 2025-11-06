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
    // Headers (18pt)
    static let boldHeader = AppFont.Montserrat.bold(18, relativeTo: .title3)
    static let regularHeader = AppFont.Montserrat.regular(18, relativeTo: .title3)

    // Titles (14pt)
    static let boldTitle = AppFont.Montserrat.bold(14, relativeTo: .body)
    static let regularTitle = AppFont.Montserrat.regular(14, relativeTo: .body)

    // Body (9pt)
    static let boldBody = AppFont.Montserrat.bold(9, relativeTo: .caption2)
    static let regularBody = AppFont.Montserrat.regular(9, relativeTo: .caption2)
}
