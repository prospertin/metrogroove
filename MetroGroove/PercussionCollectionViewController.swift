//
//  PercussionCollectionViewController.swift
//  XGroove
//
//  Created by Thinh Nguyen on 12/27/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//

import UIKit
import AudioToolbox

internal let reuseIdentifier = "DrumPadCell"

class PercussionCollectionViewController:  UICollectionViewController, UICollectionViewDelegateFlowLayout, DrumCellDelegate {
    
    let numberOfPads = 9
    var sequencer:MidiSequencer!
    let drumset1:UInt8 = 1
    var pageViewController:PercussionPageViewController!
    //var mainViewController:MainViewController!
    // var velocity:UInt8 = 80
    var patchManager:PatchManager!
    var orientation:UIInterfaceOrientation?
    var pageIndex = 0
    var labels: Array<String>?
    //   var duration:Float = 0.5 // 1/2 second 120/mn
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        sequencer = MidiSequencer.sharedInstance
        sequencer.loadSoundToSamplerUnitWithPreset(UInt8(SettingManager.sharedManager.drumset))
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PercussionCollectionViewController.orientationChanged(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: UIDevice.current)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! DrumCollectionViewCell
        cell.lineNumber = indexPath.row + numberOfPads * pageIndex
        cell.noteValue = PatchManager.sharedManager.getPatchValueForTrackIndex(cell.lineNumber)
        
        // Configure the cell
        cell.delegate = self
        cell.initSettingButton()
        
        if labels != nil && labels!.count > indexPath.row {
            cell.padButton.setTitle(labels![indexPath.row], for: UIControl.State())
        }
        return cell
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPads
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if(UIDevice.current.orientation.isLandscape) {
                return CGSize(width: 208, height: 126.2)
            } else { //if(UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
                return CGSize(width: 229, height: 202)
            }
        } else {
            let edgeWidth = collectionView.bounds.size.width > 0 ? collectionView.bounds.size.width/3 - 20 : 0
            let edgeHeight = collectionView.bounds.size.height > 0 ? collectionView.bounds.size.height/3 - 16.8 : 0
            return CGSize(width: edgeWidth, height: edgeHeight)
        }
    }
    
    @objc func orientationChanged(_ note: Notification) {
        
        let newOrientation = UIApplication.shared.statusBarOrientation
        if newOrientation != orientation {
            orientation = newOrientation
            self.collectionView!.reloadData()
        }
    }
    
    // DrumCellDelegate
    func addNote(noteValue note:UInt8, withVelocity velocity:UInt8, toLine line:Int) {
        if SettingManager.sharedManager.isRest  {
            PatchManager.sharedManager.playPopSound()
        } else {
            self.sequencer.playNote(note, velocity: velocity, channel: 9)// channel number doesnt' matter here ????
        }
        _ = self.pageViewController.mainViewController.patternPageViewController.addNoteWithPitch(note, velocity: velocity, toLine: line, completion: { currentBeat in
            self.pageViewController.mainViewController.scrollToRow(line)
            self.pageViewController.mainViewController.moveCursorToBeat(currentBeat)
        } )
        // self.mainViewController.patternTableViewController.padAllTracksWithRest()
        
    }
}
