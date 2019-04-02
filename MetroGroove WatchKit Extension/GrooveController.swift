//
//  GrooveController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 7/15/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import WatchKit
import Foundation

class GrooveController: WKInterfaceController {
    var timeSignature : TimeSignature!
    var cursorPosition : Int!
    
    @IBAction func moveLeft() {
        if cursorPosition < 3 {
            cursorPosition! += 1
            setSlider(cursorPosition)
        }
    }
    @IBAction func moveRight() {
        if cursorPosition > 1 {
            cursorPosition! -= 1
            setSlider(cursorPosition)
        }
    }
    @IBOutlet var digit1: WKInterfaceLabel!
    @IBOutlet var digit2: WKInterfaceLabel!
    @IBOutlet var digit3: WKInterfaceLabel!
    @IBOutlet var fourBeatButton: WKInterfaceButton!
    @IBOutlet var threeBeatButton: WKInterfaceButton!
    @IBOutlet var twoBeatButton: WKInterfaceButton!
    @IBOutlet var tempoSlider: WKInterfaceSlider!
    @IBOutlet var shuffleSwitch: WKInterfaceSwitch!
    
    @IBAction func setTempo(_ value: Float) {
        timeSignature.beatsPerMinute = value
        setTempoDisplay(value)
    }
    
    @IBAction func setShuffle(_ value: Bool) {
        timeSignature.shuffle = value
    }

    
    @IBAction func set2Beats() {
        setBeats(2)
    }
    
    @IBAction func set3Beats() {
        setBeats(3)
    }

    @IBAction func set4Beats() {
        setBeats(4)
    }

    func setSlider(_ digit : Int) {
        switch( digit ) {
        case 1:
            
            tempoSlider.setNumberOfSteps(160)
            digit1.setTextColor(UIColor.red)
            digit2.setTextColor(UIColor.white)
            digit3.setTextColor(UIColor.white)
            break;
        case 2:
            tempoSlider.setNumberOfSteps(16)
            digit1.setTextColor(UIColor.white)
            digit2.setTextColor(UIColor.red)
            digit3.setTextColor(UIColor.white)
            break;
        case 3:
            tempoSlider.setNumberOfSteps(2)
            digit1.setTextColor(UIColor.white)
            digit2.setTextColor(UIColor.white)
            digit3.setTextColor(UIColor.red)
            break;
        default:
            break;
        }
    }
    
    func setBeats(_ n : Int) {
        twoBeatButton.setEnabled(true)
        threeBeatButton.setEnabled(true)
        fourBeatButton.setEnabled(true)
        
        switch( n ) {
        case 2:
            twoBeatButton.setEnabled(false)
            break
        case 3:
            threeBeatButton.setEnabled(false)
            break
        default:
            fourBeatButton.setEnabled(false)
            break
        }
        
        timeSignature.upperNumber = n;
    }
    

    func setTempoDisplay(_ tempo: Float) {
        digit1.setText(String(Int(tempo.truncatingRemainder(dividingBy: 10))))
        digit2.setText(String(Int((tempo/10).truncatingRemainder(dividingBy: 10))))
        digit3.setText(String(Int((tempo/100).truncatingRemainder(dividingBy: 10))))
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        timeSignature = context as? TimeSignature
        shuffleSwitch.setOn(timeSignature.shuffle)
        setBeats(timeSignature.upperNumber)
        setTempoDisplay(timeSignature.beatsPerMinute)
        cursorPosition = 1;
        setSlider(cursorPosition)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
}
