//
//  MidiPlayerViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 2/12/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//

import UIKit
import AudioToolbox
import CoreMIDI
import CoreAudio
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


protocol MidiPlayerDelegate {
    func playerClose()
}

class MidiPlayerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    //
//    var midiClientRef = MIDIClientRef()
//    
//    var destEndpointRef = MIDIEndpointRef()
//    
//    var midiInputPortref = MIDIPortRef()
//    
//    typealias MIDIReader = (ts:MIDITimeStamp, data: UnsafePointer<UInt8>, length: UInt16) -> ()
//    typealias MIDINotifier = (message:UnsafePointer<MIDINotification>) -> ()
//    var midiReader: MIDIReader?
//    var midiNotifier: MIDINotifier?
//
//    
    //
    var sequencer:MidiSequencer?
    var displayName:String = NSLocalizedString("Unnamed", comment: "")
    var midiPlayerDelegate:MidiPlayerDelegate?
    
    @IBOutlet weak var counterPicker: UIPickerView!
    
    @IBOutlet weak var fileNameLabel: UILabel!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    @IBAction func onShare(_ sender: AnyObject) {
        let exportedFile = "\(displayName)_export"
        if (MidiFileManager.midiSharedInstance.checkAndSaveMidiFile(exportedFile, sequencer:sequencer!, onViewController:self, checkDuplicate:false) == false) {
            return //With error
        }
        
        let fileUrl = MidiFileManager.midiSharedInstance.getUrlForFile(exportedFile)
        //let projectData:NSData = (self.sequencer?.seqToData((self.sequencer?.musicSequence)!))!
        let sharingItems = [fileUrl!]
        // let applicationActivities = [UIActivity.]
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: [])
        activityViewController.excludedActivityTypes = nil
        activityViewController.popoverPresentationController!.sourceView = fileNameLabel
        activityViewController.setValue("\(NSLocalizedString("Sharing", comment: "")) \(displayName)", forKey: "subject")
        activityViewController.completionWithItemsHandler = {(activityType, completed, returnedItems, activityError) in
            if completed {
                print("Exported with \(activityType)")
            } else if activityType == nil {
                print("User dismiss without making a selection")
            } else {
                print("Activity not performed")
            }
            
            _ = MidiFileManager.midiSharedInstance.deleteFile(exportedFile)
        }
        self.view.window!.rootViewController!.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func onClose( _ sender: AnyObject) {
        UIView.transition(with: view.superview!,
                                  duration:1.0,
                                  options:UIViewAnimationOptions.transitionCrossDissolve,
                                  animations: {
                                    self.view.removeFromSuperview()
            }, completion: { _ in
                self.resetPlayer()
        })

    }
    
    @IBAction func onPlayerSegmentControlChange(_ sender: AnyObject) {
        guard let seq = sequencer else {
            return
        }
        let segmentControl:UISegmentedControl = sender as! UISegmentedControl
        let index:MidiPlayerControlEnum = MidiPlayerControlEnum(rawValue: segmentControl.selectedSegmentIndex)!
        
        switch(index) {
        case .play:
            seq.musicPlayerPlay()
            break
        case .pause:
            seq.musicPlayerStop()
            break
        case .restart:
            self.resetPlayer()
            break
        case .rewind:
            seq.musicPlayerStop()
            Timer.scheduledTimer(timeInterval: 0.2, target:self, selector:#selector(MidiPlayerViewController.rewindSequence(_:)), userInfo: nil, repeats: true);
            break
        case .forward:
            seq.musicPlayerStop()
            Timer.scheduledTimer(timeInterval: 0.2, target:self, selector:#selector(MidiPlayerViewController.forwardSequence(_:)), userInfo: nil, repeats: true);
            break
        }
    }
    
    func forwardSequence(_ timer:Timer){
        if MidiPlayerControlEnum(rawValue:segmentControl.selectedSegmentIndex) == .forward {
            if sequencer!.forward() == false {
                timer.invalidate()
                segmentControl.selectedSegmentIndex = MidiPlayerControlEnum.pause.rawValue
            }
        } else {
            timer.invalidate()
        }
    }
    
    func rewindSequence(_ timer:Timer){
        if MidiPlayerControlEnum(rawValue:segmentControl.selectedSegmentIndex) == .rewind {
            if sequencer!.rewind() == false {
                timer.invalidate()
                segmentControl.selectedSegmentIndex = MidiPlayerControlEnum.pause.rawValue
            }
        } else {
            timer.invalidate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fileNameLabel.text = displayName
       
        counterPicker.delegate = self
        counterPicker.dataSource = self
    }
   
    override func viewDidDisappear(_ animated: Bool) {
        segmentControl.selectedSegmentIndex = MidiPlayerControlEnum.pause.rawValue
        sequencer?.musicPlayerStop()
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(rawValue: "PlayBackCount"),
            object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MidiPlayerViewController.setCounter(_:)),
            name: NSNotification.Name(rawValue: "PlayBackCount"),
            object: nil)
    }
    
    @IBAction func playSequence(_ sender: AnyObject) {
        // playTestSequence();
    }
  
    func toggleSegmentedControl(_ doPlay:Bool) {
        segmentControl.isEnabled = doPlay;
        segmentControl.isUserInteractionEnabled = doPlay;
        if doPlay {
            segmentControl.selectedSegmentIndex = MidiPlayerControlEnum.play.rawValue
        }
    }
    
    func loadMidiFileFromUrl(_ fileUrl: URL?, displayName: String?) {
        
        if sequencer == nil {
            sequencer = MidiSequencer()
            MusicSequenceSetUserCallback((sequencer?.musicSequence)!, sequencerCallback, nil)
        }
        self.displayName = displayName!
        fileNameLabel.text = displayName
        
        sequencer!.initPercussionSequenceWithPatch(UInt8(0), trackCount:16)
       // sequencer!.addTempoTrack(SettingManager.sharedManager.tempo, timeSignature: )
        _ = sequencer!.loadMidiFile(fileUrl, toSequence: sequencer!.musicSequence!)
    }
    
    //MARK: pickerview delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let beats = Float(row) * self.sequencer!.beatPerBar
        self.sequencer!.setStartMusicPlayerAtBeat(Float(beats))
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let info = sequencer!.getTempoAndSignature()
        if info.timeUpper > 0 {
            return Int(Int(sequencer!.sequenceDuration / SettingManager.sharedManager.beatCountPerBar(upperTimeSignature: info.timeUpper, lowerTimeSignature: info.timeLower)))
        }
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
    
    //MARK: notifications
    dynamic func setCounter(_ notification: Notification){
        DispatchQueue.main.async(execute: {
            let count = notification.object as! String
            if Int(count) < self.counterPicker.numberOfRows(inComponent: 0) {
                debugPrint("COUNT \(count)")
                self.counterPicker.selectRow(Int(count)!, inComponent: 0, animated: true)
            } else {
                debugPrint("COUNT RESET \(count)")
                self.resetPlayer()
            }
            
        });
    }
    
    func resetPlayer() {
        self.sequencer!.musicPlayerStop()
        self.sequencer!.setStartMusicPlayerAtBeat(0)
        self.counterPicker.selectRow(0, inComponent: 0, animated: true)
        self.segmentControl.selectedSegmentIndex = MidiPlayerControlEnum.pause.rawValue
        self.segmentControl.isEnabled = true
        self.displayName = NSLocalizedString("Unnamed", comment: "")

    }
    
    // Sharing
    
    func launchShareActivity(){
        let projectData:Data = (self.sequencer?.seqToData((self.sequencer?.musicSequence)!))!
        let sharingItems = ["Export", projectData] as [Any]
       // let applicationActivities = [UIActivity.]
        let activityController = UIActivityViewController(activityItems: sharingItems, applicationActivities: [])
        activityController.excludedActivityTypes = nil
        if let ctrl = midiPlayerDelegate as? UIViewController {
            ctrl.present(activityController, animated: true, completion: {})
        }
        
    }
    
    // Sequence Callback
    let sequencerCallback: MusicSequenceUserCallback =  {
        (clientData:UnsafeMutableRawPointer?,
        sequence:MusicSequence,
        track:MusicTrack,
        eventTime:MusicTimeStamp,
        eventData:UnsafePointer<MusicEventUserData>,
        startSliceBeat:MusicTimeStamp,
        endSliceBeat:MusicTimeStamp)
        -> Void in
        
        let userData = eventData.pointee
        if userData.data == 0xAA {
            print("got user event AA of length \(userData.length)")
        }
    }
}

enum MidiPlayerControlEnum: Int {
    case restart = 0
    case rewind, pause, play, forward
    
}
