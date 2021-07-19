//
//  Sound.swift
//  SurdusEncoder
//
//  Created by 朱睿 on 2020/12/11.
//

import Foundation
import AVFoundation

class Sound {
    static var audioPlayer : AVAudioPlayer?

    static func playSounds(path: URL) {
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer?.volume = 0.5
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        }catch {
            print("Error")
        }
    }
 }
