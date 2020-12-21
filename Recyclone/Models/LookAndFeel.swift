//
//  ColorPicker.swift
//  Recyclone
//
//  Created by Evan Huang on 12/15/20.
//

import Foundation
import AVFoundation
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
    var defaultFontSize: CGFloat = 30

    var buttonFontName: String = "HelveticaNeue-UltraLight"
    var buttonFontSize: CGFloat = 32

    var titleFontName: String = "HelveticaNeue-UltraLightItalic"
    var titleTextSize: CGFloat = 40

    var headingFontName: String = "PingFangSC-Regular"
    var headingFontSize: CGFloat = 100
    
    var scoreFontName: String = "HelveticaNeue-Light"
    var scoreFontSize: CGFloat = 30
    
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

struct AudioScheme {
    
    var success: AudioWrangler = AudioWrangler(with: "success", as: "wav")
    var missed: AudioWrangler = AudioWrangler(with: "missed", as: "wav")
    var buttonPress: AudioWrangler = AudioWrangler(with: "buttonpress", as: "wav")
    var buttonRelease: AudioWrangler = AudioWrangler(with: "buttonrelease", as: "wav")
}

class LookAndFeel {
    
    //MARK: Audio scheme
    static let audioScheme = AudioScheme()
    
    //MARK: Haptic feedback
    static var buttonFeedback = UIImpactFeedbackGenerator(style: .medium)
    static var gameplayFeedback = UINotificationFeedbackGenerator()
    
    //MARK: Font scheme
    static var fontScheme = FontScheme()
    
    //MARK: Color schemes
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
