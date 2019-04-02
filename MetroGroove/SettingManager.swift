//
//  SettingManager.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 12/25/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import UIKit

class SettingManager: NSObject {

    var duration = Float(0.5) // 1/2 beat
    var tempo = 120.0
    var isRest = false
    var upperTimeSignature = 4
    var lowerTimeSignature = 4
    var barCount = 1
    var quantizeValue:Float = 2.0 //8th 1/2 of a black 16th 1/4
    var triplet = false
    var drumset = 0
    
    static var sharedManager:SettingManager = SettingManager()
    
    func totalPatternBeats() -> Float {
        return beatCountPerBar() *  Float(self.barCount)
       // return Float(self.upperTimeSignature * self.barCount * 4 / self.lowerTimeSignature)
    }
    
    func beatCountPerBar() -> Float {
     //   return Float(self.upperTimeSignature) // 4 for 4/4 2 for 2/4 6 for 6/8
        return beatCountPerBar(upperTimeSignature:self.upperTimeSignature, lowerTimeSignature:self.lowerTimeSignature)
    }
    
    func beatCountPerBar(upperTimeSignature upper:Int, lowerTimeSignature lower:Int) -> Float {
        //   return Float(self.upperTimeSignature) // 4 for 4/4 2 for 2/4 6 for 6/8
        let coefficient = Float(4.0)/Float(lower)
        return Float(upper) * coefficient
    }
}
