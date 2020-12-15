//
//  ColorPicker.swift
//  Recyclone
//
//  Created by Evan Huang on 12/15/20.
//

import Foundation
import UIKit

extension UIViewController {
    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        }
        else {
            return false
        }
    }

}

struct ColorScheme {
    var gameBackground: UIColor = .white
    var menuBackground: UIColor = .systemBlue
    var unpressedButton: UIColor = .lightGray
    var pressedButton: UIColor = .darkGray
    var buttonText: UIColor = .black
    var defaultText: UIColor = .black
    var missedItemsText: UIColor = .red
    var scoredItemsText: UIColor = .green
}

struct FontScheme {
    var defaultFontName: String = "HelveticaNeue-UltraLight"
    var buttonFontName: String = "HelveticaNeue-UltraLight"
    var headingFontName: String = "HelveticaNeue-UltraLightItalic"
    var scoreFontName: String = "HelveticaNeue-Light"
    var defaultFontSize: CGFloat = 30
    var buttonFontSize: CGFloat = 32
    var headingTextSize: CGFloat = 40
}

class LookAndFeel {
    static var buttonFeedback = UIImpactFeedbackGenerator(style: .medium)
    static var gameplayFeedback = UINotificationFeedbackGenerator()
    static var fontScheme = FontScheme()
    static var isDarkMode = UIViewController().isDarkMode
    static var currentColorScheme: ColorScheme {
        if isDarkMode {
            return dark
        } else {
            return light
        }
    }
    static var light = ColorScheme()
    static var dark = ColorScheme( gameBackground: .black,
                                   menuBackground: .systemBlue,
                                   unpressedButton: .darkGray,
                                   pressedButton: .lightGray,
                                   buttonText: .white,
                                   defaultText: .white,
                                   missedItemsText: .red,
                                   scoredItemsText: .green)
    
}
