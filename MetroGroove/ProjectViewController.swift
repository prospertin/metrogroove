//
//  ProjectViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 2/22/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//

import UIKit

class ProjectViewController: UIViewController, UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, PopoverMenuDelegate, PatternSectionDelegate {

    let reusedIdentifier = "patternCell"
    let patternCache = [String:[Array<Note>]]()
    var sections: Array<Section> = []
    var cursorPosition: Int = -1
    var currentProjectName: String?
    var sequencer = MidiSequencer.sharedInstance
    let tap = UITapGestureRecognizer()
    var hasChanges = false
    
  //  @IBOutlet weak var barNumberTextField: UITextField!
    @IBOutlet weak var tempoTextField: UITextField!
    @IBOutlet weak var projectNameTextField: UITextField!
//@IBOutlet var tableView: UITableView!
    @IBOutlet weak var projectCollectionView: UICollectionView!
    @IBOutlet weak var loadButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func onPlay(_ sender: AnyObject) {
        if sections.count == 0 {
            ToastFactory.makeCenterToast(NSLocalizedString("No data to load", comment: ""), onView: self.view, isDark: false)
            //showMessage(NSLocalizedString("No data to load", comment: ""), withTitle:"", onViewController:self)
            return
        }
        createSequenceFromProject()
        let projectSequencer = ProjectSequencer()
        sequencer.sequenceDuration = findBeatPositionAtSection(sections.count)
        projectSequencer.sequencer = sequencer
        projectSequencer.projectName = currentProjectName
        projectSequencer.beatPosition = findBeatPositionAtSection(cursorPosition)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PlayProjectNotification"), object: projectSequencer)
    }
    
    @IBAction func onNewProject(_ sender: AnyObject) {
        print("New Project clicked")
        if (hasChanges){
            UIHelper.showAlertMessageWithOptions(NSLocalizedString("There are unsaved changes. Discard changes?", comment: "Alert when create new project"), withTitle:NSLocalizedString("Alert", comment: ""), onController:self, okAction: { _ in
                self.clearProjecView()
            })
        } else {
            clearProjecView()
        }
        
    }
    
    func clearProjecView() {
        projectNameTextField.text = ""
        currentProjectName = ""
        sections = []
        projectCollectionView.reloadData()
        cursorPosition = -1
        hasChanges = false
    }
    
    @IBAction func onLoadPattern(_ sender: AnyObject) {
        
    }
    @IBAction func onSaveProject(_ sender: AnyObject) {
        saveProject()
    }
    
    func findBeatPositionAtSection(_ index: Int) -> Float{
        var beatPosition: Float = 0
        if index < 1 {
            return 0
        }
        for i in 0...index-1 {
            let beatsPerBar = SettingManager.sharedManager.beatCountPerBar(upperTimeSignature: sections[i].timeSignature.upper, lowerTimeSignature: sections[i].timeSignature.lower)
            beatPosition += beatsPerBar * Float(sections[i].count * sections[i].patternBarCount)
        }
        return beatPosition
    }
    
    @IBAction func dropDownMenu (_ sender: AnyObject) {
        self.performSegue(withIdentifier: "menuPopoverSegue", sender: self)
    }
    
    //MARK: - View Controller Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        tempoTextField.delegate = self
        projectNameTextField.delegate = self
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            setupKeyBoardForTempoTextField()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ProjectViewController.importProject(_:)),
            name: NSNotification.Name(rawValue: "OpenProjectNotification"),
            object: nil)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ProjectViewController.orientationChanged(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: UIDevice.current)
        
        tap.numberOfTapsRequired = 1
        projectCollectionView.addGestureRecognizer(tap)
        tap.addTarget(self, action: #selector(ProjectViewController.unfocusSection(_:)))

    }

    @objc dynamic func unfocusSection(_ recognizer: UITapGestureRecognizer) {
        if cursorPosition < 0 {
            return
        }
        let unfocusIndex = cursorPosition
        cursorPosition = -1
        projectCollectionView.reloadItems(at: [IndexPath(item: unfocusIndex, section: 0)])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: PopupPatternTableViewController.self){
            //segue.identifier == "menuPopoverSegue" || segue.identifier == "newPopoverSegue" {
            let popoverViewController = segue.destination
            (popoverViewController as! PopupPatternTableViewController).delegate = self
        }
    }

    // MARK: text field delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == projectNameTextField {
            saveProject()
        } else {
            textField.resignFirstResponder() //For the tempo field
        }
        return true;
    }
    
    func textField(_ textField:UITextField, shouldChangeCharactersIn range:NSRange, replacementString string:String ) -> Bool {
    
        if textField == tempoTextField {
            if range.location > 2 || (string.count > 0 && Int(string) == nil) {// 3 characters 0-2 and numerical
                return false;
            }
        }

        return true;
    }
    
    func setupKeyBoardForTempoTextField() {
        let numberToolbar: UIToolbar = UIToolbar()
        numberToolbar.barStyle = UIBarStyle.blackTranslucent
        
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target:self, action: #selector(ProjectViewController.dismissTempoKeyboard))
        done.tintColor = UIColor.white
        numberToolbar.items = [done]
        
        numberToolbar.sizeToFit()
        self.tempoTextField.inputAccessoryView = numberToolbar //do it for every relevant textfield if there are more than one
        
    }
    
    @objc func dismissTempoKeyboard() {
        self.tempoTextField.resignFirstResponder()
    }
    
    //Popup delegate Delegate
    func popupMenuSelectIndex(_ index: Int, title: String) {
        let patternName = MidiFileManager.patternsSharedInstance.getFileList()[index];
        
        guard let pat = sequencer.patternFileToNoteTable(patternName) else {
            debugPrint("Unexpected null pattern \(patternName)")
            return
        }
//        patternCache[patternName]
//        if pat == nil {
//            let sequencer = MidiSequencer() // Don't use the share one
//            pat = sequencer.patternFileToNoteTable(patternName)
//        }
        //MidiSequencer.sharedInstance.getTempoFromSequence()
        let tempoSignature = MidiSequencer.sharedInstance.getTempoAndSignature()
        let upperTimeSignature = tempoSignature.timeUpper
        let lowerTimeSignature = tempoSignature.timeLower
        let section = Section(patternName: patternName, count: 1,
            timeSignature: (upperTimeSignature, lowerTimeSignature), barCount: tempoSignature.barCount, pattern: pat)
        if cursorPosition >= 0 {
            sections.insert(section, at: cursorPosition)
            cursorPosition += 1
        } else {
            sections.append(section)
        }
       projectCollectionView.reloadData()
        hasChanges = true
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = projectCollectionView.frame.width / 4
        return CGSize(width: w, height: 30.0)
    }
   
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedIdentifier, for: indexPath) as! PatternCollectionViewCell
        cell.patternNameLabel.text = sections[indexPath.row].patternName
        cell.barCount.text = String(sections[indexPath.row].count)
        cell.index = indexPath.row
        cell.patternSectionDelegate = self // pattern section delegate
        if indexPath.item == cursorPosition {
            cell.backgroundColor = PatternCollectionViewCell.highlightColor
        } else {
            cell.backgroundColor = PatternCollectionViewCell.regularColor
        }
        return cell
    }
    
    @objc func orientationChanged(_ note: Notification) {
        projectCollectionView.reloadData()
    }

    @objc dynamic func importProject(_ notification: Notification) {
        
        let fname = notification.object as! String
        
        if (hasChanges){
            UIHelper.showAlertMessageWithOptions(NSLocalizedString("There are unsaved changes. Discard changes?", comment: "Alert when create new project"), withTitle:NSLocalizedString("Alert", comment: ""), onController:self, okAction: { _ in
                    self.clearProjecView()
                    self.doImportProject(fname)
            })
        } else {
            self.doImportProject(fname)
        }
    }
    
    func doImportProject(_ fname:String) {
        
        if let proj = MidiFileManager.projectsSharedInstance.loadProjectFile(fname) {
            sections = proj.sections
            tempoTextField.text = proj.tempo
            projectCollectionView.reloadData()
            projectNameTextField.text = fname
            currentProjectName = fname
            cursorPosition = -1
            hasChanges = false
        } else {
            MidiFileManager.projectsSharedInstance.showMessage(NSLocalizedString("Wrong file format", comment: "Wrong file format"), withTitle: nil, onViewController: self)
        }
        
    }
    
    func saveProject() {
        let checkDuplicate = currentProjectName == nil || projectNameTextField.text! != currentProjectName
        let proj = Project(tempo: tempoTextField.text!, sections: sections)
        if MidiFileManager.projectsSharedInstance.saveProjectFile(projectNameTextField.text!, project: proj, checkDuplicate: checkDuplicate, onViewController: self) {
            currentProjectName = projectNameTextField.text!
            projectNameTextField.resignFirstResponder()
            hasChanges = false
            //saveButton.enabled = false
            ToastFactory.makeCenterToast(NSLocalizedString("\"\(currentProjectName!)\" saved", comment: ""), onView: self.view, isDark: false)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveProjectNotification"), object: currentProjectName)
        }
    }
    
    //MARK: patternSectionDelegate
    func removeSection(_ atIndex: Int) {
        sections.remove(at: atIndex)
        if cursorPosition >= 0 {
            cursorPosition -= 1
        }
       // projectCollectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: atIndex, inSection: 0)])
        projectCollectionView.reloadData() // Must reload all to recalculate section indexes
        hasChanges = true
    }
    
    //MARK: patternSectionDelegate
    func highlightSection(_ atIndex: Int) {
        print("Highlight section \(atIndex)")
        if cursorPosition >= 0 && atIndex >= 0 {
            let previousCursor = cursorPosition
            cursorPosition = atIndex
            //INVESTIGATE THIS IS MORE EFFICIENT
//            [collectionView performBatchUpdates:^{
//                collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:x section:0]];
//                }];
            // Update old cells
            let indexPaths = [IndexPath(item: previousCursor, section: 0)]
            //let array = [indexPath]
            projectCollectionView.reloadItems(at: indexPaths);
        } else {
            cursorPosition = atIndex
        }
    }
    
    func updateBarCount(_ count: Int, atIndex: Int) {
        sections[atIndex].count = count
        hasChanges = true
    }
    
    func updateSectionName(_ name: String, atIndex: Int) {
        if atIndex < sections.count {
            sections[atIndex].patternName = name
            hasChanges = true
        }
    }
   
    func launchSectionEditor(_ atIndex: Int) {
        performSegue(withIdentifier: "patternSectionEditorSegue", sender: self)
    }
    
    //MARK: load to sequencer
    func createSequenceFromProject() {
        sequencer.initPercussionSequenceWithPatch(UInt8(0), trackCount: MAX_INSTRUMENT_COUNT)
        let tempo = Float64(tempoTextField.text!)
        let timeSignature = sections[0].timeSignature //TODO use 1st pattern for now
        sequencer.addTempoTrack(tempo!, timeSignature:timeSignature, barCount: SettingManager.sharedManager.barCount)
        let noteTable = expandSectionsToNoteTable()
        // Transform each note to midi message and add them to the corresponding track
        for line in 0...MAX_INSTRUMENT_COUNT - 1 {
            var currentBeat:Float = 0.0
            let track = UInt32(line)
            for note in noteTable[line] {
                sequencer.addNoteToPercussionTrack(track, note: note.pitch, beat: note.beatPosition,
                    velocity: note.velocity, releaseVelocity: UInt8(0), duration: note.endPosition - note.beatPosition)
                currentBeat += note.endPosition - note.beatPosition
            }
//   NO LOOP FOR PROJECT --- maybe later         sequencer.setLoopForTrack(line, withLen: Int(SettingManager.sharedManager.totalPatternBeats()))
        }
    }
    
    func expandSectionsToNoteTable() -> [Array<Note>] {
        var noteTable = [[Note]]()
        for _ in 0..<MAX_INSTRUMENT_COUNT  {
            noteTable.append([])
        }
        var offset: Float = 0.0
        for section in sections {
            var increment:Float = Float(section.timeSignature.upper)
            if section.timeSignature.lower == 8 {// Special case for 6/8
                increment = Float(3)
            }
            // Hack 
            if section.patternBarCount > 0 {
                increment *= Float(section.patternBarCount)
            }
            
            for _ in 0..<section.count {
                for i in 0...section.pattern.count - 1 {
                    let inLine = section.pattern[i]
                    //var outLine = noteTable[i]
                    for note in inLine {
                        // copy each note
                        let index = PatchManager.sharedManager.getTrackIndexForPatchValue(Int(note.pitch))
                        if index < 0 {
                            continue
                        }
                        noteTable[index].append(Note( pitch: note.pitch, velocity: note.velocity, beatPosition: note.beatPosition + offset, endPosition: note.endPosition + offset))
                    }
                }

                offset += increment
            }
            
        }
        // Add an empty section at the end to signal that this is the end of the song
        noteTable[0].append(Note(pitch:35, velocity: 0, beatPosition: offset, endPosition: offset + 1 ))
        return noteTable
    }
}


