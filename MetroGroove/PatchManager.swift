//
//  PatchManager.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 12/23/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import Foundation
import AVFoundation

enum DrumSoundEnum: UInt8 {
    case kick2 = 35
    case kick1, rimshot, snare1, handClap, snare2, lowTom2, closedHihat, lowTom1, pedalHihat
    case midTom2, openHihat, midTom1, highTom2, crashCymbal, highTom1, rideCymbal1, chineseCymbal
    case rideBell, tambourine, splashCymbal, cowbell, crashCymbal2, vibraSlap, rideCymbal2, hiBongo, lowBongo, muteHiConga, hiConga, lowConga, highTimbale, lowTimbale
}

enum PercussionSoundEnum: UInt8 {
    case conga1
    case conga2
}

class PatchManager: NSObject {
    var patchList = [DrumSoundEnum.openHihat,
                     DrumSoundEnum.closedHihat,
                     DrumSoundEnum.rideCymbal1,
                     DrumSoundEnum.crashCymbal,
                     DrumSoundEnum.highTom1,
                     DrumSoundEnum.midTom1,
                     DrumSoundEnum.snare1,
                     DrumSoundEnum.kick1,
                     DrumSoundEnum.lowTom1,
                     DrumSoundEnum.rimshot,
                     DrumSoundEnum.hiBongo,
                     DrumSoundEnum.lowBongo,
                     DrumSoundEnum.muteHiConga,
                     DrumSoundEnum.hiConga,
                     DrumSoundEnum.lowConga,
                     DrumSoundEnum.highTimbale,
                     DrumSoundEnum.lowTimbale,
                     DrumSoundEnum.cowbell]
    
    var restSound = URL(fileURLWithPath: Bundle.main.path(forResource: "rest", ofType: "mp3")!)
    var audioPlayer = AVAudioPlayer()
    
    override init() {
        super.init()
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: self.restSound, fileTypeHint: nil)
            audioPlayer.prepareToPlay()
        } catch {
            print( "Error loading sound file" )
        }
    }
    static var sharedManager:PatchManager = PatchManager()
    
    func getPatchValueForTrackIndex(_ index:Int) -> UInt8 {
        if index > -1 && index < patchList.count {
            return patchList[index].rawValue
        }
        return 0
    }
    
    func getTrackIndexForPatchValue(_ patch:Int) -> Int {
        if let soundEnum = DrumSoundEnum(rawValue: UInt8(patch)){
            if let index = patchList.firstIndex(of: soundEnum) {
                return index
            }
        }
        return -1
    }
    
    func playPopSound() {
        audioPlayer.play()
    }
}
