//
//  InterfaceController.swift
//  MetroGroove WatchKit Extension
//
//  Created by Thinh Nguyen on 7/12/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //TODO
    }

    
    @IBOutlet var bpmLabel: WKInterfaceLabel!
    @IBOutlet var timeSigLabel: WKInterfaceLabel!
    @IBOutlet var beatButton: WKInterfaceButton!
    
    var brightRedColor : UIColor!
    var timer: Timer!
    var timeSignature: TimeSignature!
    var currentBeatFraction = 0
    var session : WCSession!
    
    @IBAction func toggle() {
        if timer == nil {
            //sendMessageToParent("start")
            startMetronome()
        } else {
            //sendMessageToParent("stop")
            stopMetronome()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        brightRedColor = UIColor.init(hue: 0.05, saturation:1.0, brightness:1.0, alpha:1.0)
        timeSignature = TimeSignature()
        timeSignature.upperNumber = 4
        timeSignature.lowerNumber = 4
        timeSignature.beatsPerMinute = 120
        timeSignature.shuffle = false
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if (timer != nil) {
            setInfoLabels(timer.userInfo as! TimeSignature)
        } else {
            setInfoLabels(timeSignature)
        }
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func setInfoLabels(_ ts : TimeSignature) {
        timeSigLabel.setText("\(ts.upperNumber ?? 4)/\(ts.lowerNumber ?? 4)")
        bpmLabel.setText("\(Int(ts.beatsPerMinute)) bpm")
    }
    
    func startMetronome() {
        var interval : TimeInterval!
        if timeSignature.shuffle {
            interval = (TimeInterval)(60.0/timeSignature.beatsPerMinute/3.0)
            currentBeatFraction = -3
        } else {
            interval = (TimeInterval)(60.0/timeSignature.beatsPerMinute/2.0)
            currentBeatFraction = -2
        }
        let newGroove = timeSignature.clone()
        timer = Timer.scheduledTimer(timeInterval: interval, target:self, selector: #selector(InterfaceController.updateBeat), userInfo: newGroove, repeats: true)
        //sendMessageToParent("start")
    }
    
    func stopMetronome() {
        beatButton.setBackgroundColor(UIColor.green)
        beatButton.setTitle("Go")
        timer.invalidate()
        timer = nil
        setInfoLabels(timeSignature)
       // sendMessageToParent("stop")
    }
    @objc func updateBeat() {
        let ts = timer.userInfo as! TimeSignature
        if (currentBeatFraction < 0){
            if (!ts.shuffle || currentBeatFraction == -2){
                beatButton.setBackgroundColor(UIColor.black)
            }
            currentBeatFraction += 1
            return
        }
        let beatNumber = ts.shuffle ? 3 : 2
        beatButton.setTitle("\(currentBeatFraction / beatNumber + 1)" )
        if currentBeatFraction == 0 {
            beatButton.setBackgroundColor(UIColor.red)
            currentBeatFraction += 1
            
        } else if ts.shuffle {
            switch currentBeatFraction % 3 {
            case 0:
               beatButton.setBackgroundColor(UIColor.yellow)
                break
            case 2:
                beatButton.setBackgroundColor(UIColor.black)
                break
            default:
                break
            }
            currentBeatFraction += 1
            currentBeatFraction %= ts.upperNumber * 3
        } else {
            if (currentBeatFraction % 2 == 1) {
                beatButton.setBackgroundColor(UIColor.black)
            } else{
                beatButton.setBackgroundColor(UIColor.yellow)
            }
            currentBeatFraction += 1
            currentBeatFraction %= ts.upperNumber * 2
        }
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        return timeSignature
    }
    
    func sendMessageToParent(_ action:String) {
        let applicationData = ["tempo":String(Int(timeSignature.beatsPerMinute)), "action":action]
        
        session.sendMessage(applicationData, replyHandler: {(reply: [String : Any]) -> Void in
            // handle reply from iPhone app here
            print("Reply: \(reply)")
            DispatchQueue.main.async(execute: {
                if self.timer == nil {
                    self.startMetronome()
                } else  {
                    self.stopMetronome()
                }
            });
            
            }, errorHandler: {(error ) -> Void in
                // catch any errors here
                print("Error communicating to parent")
        })
    }
}

class TimeSignature {
    var upperNumber: Int!
    var lowerNumber: Int!
    var beatsPerMinute: Float!
    var shuffle = false
    
    func clone() -> TimeSignature {
        let cloneTS = TimeSignature()
        cloneTS.upperNumber = self.upperNumber
        cloneTS.lowerNumber = self.lowerNumber
        cloneTS.shuffle = self.shuffle
        cloneTS.beatsPerMinute = self.beatsPerMinute
        return cloneTS
    }
}

