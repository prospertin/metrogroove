//
//  PatternTableViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 9/10/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import UIKit
import AudioToolbox

class PatternTableViewController: UITableViewController, NoteViewDelegate {
    
    var pageIndex:Int!

    //var instrumentArray:NSMutableArray = NSMutableArray()
    var settingManager:SettingManager = SettingManager.sharedManager
    var patternLen:Int = 1
    let trackProperties = [
        TrackProperties(label: "Ho"), TrackProperties(label: "Hc"),
        TrackProperties(label: "Rd"), TrackProperties(label: "Cs"),
        TrackProperties(label: "T1"), TrackProperties(label: "T2"),
        TrackProperties(label: "Sn"), TrackProperties(label: "Kk"),
        TrackProperties(label: "T3"), TrackProperties(label: "Rs"),
        TrackProperties(label: "Hb"), TrackProperties(label: "Lb"),
        TrackProperties(label: "Mc"), TrackProperties(label: "Hc"),
        TrackProperties(label: "Lc"), TrackProperties(label: "Ht"),
        TrackProperties(label: "Lt"), TrackProperties(label: "Cb")]
    
    var cursorBeatPosition:Float = 0.0 // number of beats from the start of pattern.
    var patternWidth:CGFloat = 0.0
    var startX:CGFloat = 0
    var timer:Timer!
    
    var pageViewController:PatternPageViewController!
    
    //var swipeGestureRecognizer:UISwipeGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.pageViewController.instrumentList.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let height = tableView.bounds.height/CGFloat(self.pageViewController.instrumentList.count/2 + 1)
        debugPrint("Table cell height = \(height)")
        return height
//        if indexPath.row > 0 && UIDevice.current.userInterfaceIdiom != .pad {
//            return height
//        }
//        else {
//            return height
//        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "percussionCell", for: indexPath)
        let label = indexPath.section == 0 ? "" : trackProperties[indexPath.row].label
        self.startX = initCell(cell, withLabel:label!)
        
        var noteWidthUnit = Float(tableView.frame.width - startX)/Float(settingManager.upperTimeSignature)
        
        let rowHeight = tableView.bounds.height/CGFloat(self.pageViewController.instrumentList.count/2 + 1)
        if indexPath.section == 0 {
            let upper = self.settingManager.upperTimeSignature > 0 ? self.settingManager.upperTimeSignature : 4
            for beat in 0...upper - 1 {
                cell.contentView.addSubview(createHeaderView(noteWidthUnit, beat: beat, rowHeight: rowHeight))
            }
            self.patternWidth = cell.frame.size.width - self.startX;
        } else {
        // Configure the cell...
            if settingManager.lowerTimeSignature == 8 {
                noteWidthUnit *= 2 // Special for 6/8
            }
            let notes = self.pageViewController.instrumentList[indexPath.row]
            // let stackView = cell.viewWithTag(11) as! UIStackView
            var x:CGFloat = startX
            for note in notes {
                let firstBeat = Float(self.pageIndex) * SettingManager.sharedManager.beatCountPerBar()
                let nextBarBeat = firstBeat + SettingManager.sharedManager.beatCountPerBar() + 1.0
                if note.velocity == 0 || note.endPosition <= firstBeat || note.beatPosition >= nextBarBeat {
                    continue
                }
                // Show partial note if across bars
                let startPos = max(note.beatPosition, firstBeat)
                let endPos = min(note.endPosition, nextBarBeat)
                let duration = endPos - startPos
                let width = CGFloat(noteWidthUnit) * CGFloat(duration) - 1.0

               // x = startX + CGFloat(note.beatPosition % Float(SettingManager.sharedManager.upperTimeSignature) * noteWidthUnit)
                x = startX + CGFloat(note.beatPosition.truncatingRemainder(dividingBy: SettingManager.sharedManager.beatCountPerBar()) * noteWidthUnit)
                let frame = CGRect(x: x, y: 0.0, width: width, height: rowHeight*3/2)// tableView.bounds.height/CGFloat(self.pageViewController.instrumentList.count))
                let noteView = NoteView(frame: frame, forNote: note, atLine: indexPath.row)
                noteView.delegate = self
                noteView.backgroundColor = note.velocity == 0 ? UIColor.white : UIColor.red
//                noteView.addGestureRecognizer(UISwipeGestureRecognizer(target: noteView, action: "swipeNote:"))
                cell.contentView.addSubview(noteView)
                //x += CGFloat(noteWidthUnit * duration)
            }
        }
        return cell
    }

    func createHeaderView(_ noteWidthUnit:Float, beat:Int, rowHeight:CGFloat) -> UIView {
        let width = CGFloat(noteWidthUnit) - 1.0
        let frame = CGRect(x: self.startX + CGFloat(noteWidthUnit * Float(beat)), y: 0.0, width: width, height: rowHeight)
        let beatView = UIView(frame: frame)
        let labelFrame = CGRect(x: 0.0, y: 2.0, width: width, height: rowHeight - 4)
        let label = UILabel(frame: labelFrame)
        label.text = String(beat+1)
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont(name: "HelveticaNeue-Bold", size: 11)
        label.textColor = UIColor.white
        beatView.addSubview(label)
        beatView.backgroundColor = UIColor.init(red: 120/255, green: 40/255, blue: 14/255, alpha: 1)
        
        return beatView
    }
    
    func initCell(_ cell:UITableViewCell, withLabel label:String) -> CGFloat {
        var labelWidth = CGFloat(0)
        for view in cell.contentView.subviews {
            if view.isKind(of: UILabel.self) {
                let textLabel = view as! UILabel
                textLabel.text = label
                labelWidth = textLabel.frame.size.width
            }
            else {
                view.removeFromSuperview()
            }
        }
        
        return labelWidth
    }
    
    func setBeatPosition(_ beat:Float){
        self.cursorBeatPosition = beat;
    }
    
    func orientationChanged(_ note: Notification) {
        self.tableView.reloadData()
    }
    
    // Delegate
    func removeNote(_ note: Note, atLine: Int) {
        var notes = self.pageViewController.instrumentList[atLine]
        if notes.count < 1 {
            return;
        }
        for index in 0...notes.count - 1 {
            if note.beatPosition == notes[index].beatPosition {
                notes.remove(at: index)
                self.pageViewController.instrumentList[atLine] = notes
                PatchManager.sharedManager.playPopSound()
                self.pageViewController.hasChanges = true
                break
            }
        }
    }
}

struct TrackProperties {
    var label:String!
}
