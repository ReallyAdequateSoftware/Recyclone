//
//  ColorPicker.swift
//  Recyclone
//
//  Created by Evan Huang on 12/15/20.
//

import Foundation
import AVFoundation
import UIKit
import SpriteKit

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

struct ColorClass {
    var gameBackground: UIColor = .white
    var menuBackground: UIColor = .systemBlue
    var unpressedButton: UIColor = .lightGray
    var pressedButton: UIColor = .darkGray
    var buttonText: UIColor = .black
    var defaultText: UIColor = .black
    var missedItemsText: UIColor = .red
    var scoredItemsText: UIColor = .green
}
//TODO: figure out how to add extensibility for app specific colors
struct ColorScheme {
    static var light = ColorClass()
    static var dark = ColorClass( gameBackground: .black,
                                   menuBackground: .systemBlue,
                                   unpressedButton: .darkGray,
                                   pressedButton: .lightGray,
                                   buttonText: .white,
                                   defaultText: .white,
                                   missedItemsText: .red,
                                   scoredItemsText: .green)
    static var isDarkMode = UIViewController().isDarkMode
    static var currentColorClass: ColorClass {
        if isDarkMode {
            return dark
        } else {
            return light
        }
    }

}

//decide on whether to use enum or class
//class FontScheme {
//
//    enum FontClass {
//        case `default`
//        case button
//        case title
//        case heading
//        case score
//    }
//
//    struct FontAttributes {
//        var name: String
//        var size: CGFloat
//    }
//
//    let attributesFor: (_ fontClass: FontClass) -> FontAttributes
//
//    init(attributesFor: @escaping (_ fontClass: FontClass) -> FontAttributes) {
//        self.attributesFor = attributesFor
//    }
//}

class FontScheme {
    
    struct FontClass {
        var name: String
        var size: CGFloat
    }

    static var `default`: FontClass = FontClass(name: "HelveticaNeue-UltraLight", size: 30)
    static var button: FontClass = FontClass(name: "HelveticaNeue-UltraLight", size: 32)
    static var title: FontClass = FontClass(name: "HelveticaNeue-UltraLightItalic", size: 40)
    static var heading: FontClass = FontClass(name: "PingFangSC-Regular", size: 100)
}

class AudioWrangler: NSObject, AVAudioPlayerDelegate {
    let name: String
    let fileType: String
    private var ready = Set<AVAudioPlayer>()
    private var busy = Set<AVAudioPlayer>()
    
    init(with name: String, as fileType: String) {
        self.name = name
        self.fileType = fileType
        super.init()
        print("init")
        self.primeAudioPlayers()
    }
    
    func play() {
        if let player = ready.popFirst() {
            //need to keep a reference so that the player isnt deallocated while in the background thread
            busy.insert(player)
            primeAudioPlayers()
            dispatchAudio(player: player)
        }
    }
    
    private func primeAudioPlayers() {
        if ready.isEmpty {
            DispatchQueue.dispatchTask(to: .userInitiated,
                                       task: {
                                        if let player = AudioWrangler.createAudioPlayer(with: self.name, as: self.fileType) {
                                            print("created")
                                            player.delegate = self
                                            player.prepareToPlay()
                                            self.ready.insert(player)
                                        }
                                       })
        }
    }
    
    private func dispatchAudio(player: AVAudioPlayer) {
        DispatchQueue.dispatchTask( to: .userInitiated,
                                    task: {
                                        player.play()
                                    })
    }
    
    static func createAudioPlayer(with name: String, as fileType: String) -> AVAudioPlayer? {
        var player: AVAudioPlayer?
        guard let url = Bundle.main.url(forResource: name, withExtension: fileType) else {
            print("audio file not found")
            return player
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly */
            player = try AVAudioPlayer(contentsOf: url)
        } catch let error {
            print(error.localizedDescription)
        }
        return player
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.ready.insert(player)
    }
}

//TODO: lazy initialization problems when all properties are made static
struct AudioScheme {
    var buttonPress: AudioWrangler = AudioWrangler(with: "buttonpress", as: "wav")
    var buttonRelease: AudioWrangler = AudioWrangler(with: "buttonrelease", as: "wav")
    var success: AudioWrangler = AudioWrangler(with: "success", as: "wav")
    var missed: AudioWrangler = AudioWrangler(with: "missed", as: "wav")
}

struct HapticFeedbackScheme {
    static var buttonFeedback = UIImpactFeedbackGenerator(style: .medium)
}

class LookAndFeel {
    
//    used for enum implementation
//    static var fontScheme = FontScheme(attributesFor: { fontClass in
//        switch fontClass {
//        case .default: return FontScheme.FontAttributes(name: "HelveticaNeue-UltraLight", size: 30)
//        case .button: return FontScheme.FontAttributes(name: "HelveticaNeue-UltraLight", size: 32)
//        case .title: return FontScheme.FontAttributes(name: "HelveticaNeue-UltraLightItalic", size: 40)
//        case .heading: return FontScheme.FontAttributes(name: "PingFangSC-Regular", size: 100)
//        case .score: return FontScheme.FontAttributes(name: "HelveticaNeue-Light", size: 30)
//        }
//    })
    
    static let audioScheme = AudioScheme()
    
    static func textNode(text: String, at position: CGPoint? = nil, as fontClass: FontScheme.FontClass = FontScheme.default, color: UIColor = ColorScheme.currentColorClass.defaultText) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.name = text
        label.fontName = fontClass.name
        label.fontSize = fontClass.size
        label.fontColor = color
        if let position = position {
            label.position = position
        }
        return label
    }
    
}
