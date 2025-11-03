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
    static let largeTitle = AppFont.Montserrat.semibold(34, relativeTo: .largeTitle)
    static let title      = AppFont.Montserrat.semibold(28, relativeTo: .title)
    static let headline   = AppFont.Montserrat.semibold(17, relativeTo: .headline)
    static let body       = AppFont.Montserrat.regular(17, relativeTo: .body)
    static let caption    = AppFont.Montserrat.regular(12, relativeTo: .caption)

    // Common aliases used in views
    static let montserratMediumBody = AppFont.Montserrat.medium(17, relativeTo: .body)
    static let montserratBoldBody   = AppFont.Montserrat.bold(17, relativeTo: .body)

    // Helvetica Neue preset as requested
    static let helveticaCaption = Font.custom("HelveticaNeue", size: 16.5549, relativeTo: .caption)

    // Legends small label preset
    static let legendLabel = AppFont.Montserrat.bold(9, relativeTo: .caption2)
}
