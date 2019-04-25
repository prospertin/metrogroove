//
//  ViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 7/12/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import UIKit
import AudioToolbox
import WatchConnectivity
import ReactiveSwift

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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MainViewController: UIViewController, UITextFieldDelegate, PopoverMenuDelegate,UIPopoverPresentationControllerDelegate, WCSessionDelegate {
    // MARK: iPad extra components
    @IBAction func onIpadSave(_ sender: AnyObject) {
       savePattern()
    }
    @IBAction func onIpadNew(_ sender: AnyObject) {
        createNew()
    }
    @IBOutlet weak var iPadPatternName: UITextField?
    // End iPad
    
    @IBOutlet weak var leftPageButton: UIBarButtonItem!
    @IBOutlet weak var rightPageButton: UIBarButtonItem!
    
    @IBAction func onPageLeft(_ sender: AnyObject) {
        percussionPageViewController!.slideToPage(0, animation: true)
    }
    
    @IBAction func onPageRight(_ sender: AnyObject) {
        percussionPageViewController!.slideToPage(1, animation: true)
    }

    @IBOutlet weak var barNumber: UILabel!
    
    @IBOutlet weak var playerSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tempoTextField: UITextField!
   
    @IBOutlet weak var cursorView: UIVisualEffectView!
   
    @IBOutlet weak var cursorTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var cursorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cursorLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var patternViewLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var patternSizeButton: UIButton!
    @IBOutlet weak var timeSignatureButton: UIButton!
    
    @IBOutlet weak var durationSegmentControl: UISegmentedControl!
    @IBOutlet weak var tripletSwitch: UISwitch!
   
    @IBOutlet weak var drumsetButton: UIBarButtonItem!
    
    var sequencer:MidiSequencer = MidiSequencer.sharedInstance
    var patternPageViewController:PatternPageViewController!
    var percussionPageViewController:PercussionPageViewController!
    var settingManager = SettingManager.sharedManager
    var savedLocation = CGPoint.zero
    
    //Player control 
    var animator: UIDynamicAnimator!
   // var stickyBehavior: StickyCornersBehavior!
    var offset = CGPoint.zero
    let itemAspectRatio: CGFloat = 0.70
    
    var currentFileName:String? = nil
    
    //iWatch
    var watchSession : WCSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tempoTextField.delegate = self
        if UIDevice.current.userInterfaceIdiom == .phone {
            setupKeyBoardForTempoTextField()
        }
        iPadPatternName?.delegate = self
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MainViewController.panPatternTable(_:)))
        self.cursorView.addGestureRecognizer(panGestureRecognizer);
        if tripletSwitch != nil {
            tripletSwitch.addTarget(self, action:#selector(MainViewController.setTripletState(_:)), for:UIControl.Event.valueChanged);
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MainViewController.importPattern(_:)),
            name: NSNotification.Name(rawValue: "ImportPatternNotification"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MainViewController.showPageNumber(_:)),
            name: NSNotification.Name(rawValue: "PageChangeNotification"),
            object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MainViewController.orientationChanged(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: UIDevice.current)
        
        if currentFileName == nil {
            self.title = NSLocalizedString("Unamed", comment: "File name on nav bar");
        } else {
            self.title = currentFileName
        }// self.navigationItem.title = "Nav new pattern";
        
        // Observe the change in percussion page and update the arrow buttons accordingly
        percussionPageViewController!.currentPage.signal.observeValues {value in
            self.leftPageButton.isEnabled = value > 0
            self.rightPageButton.isEnabled = value < 1
        }
        setWatchConnectivity()
    }
    
    func setWatchConnectivity() {
        if (WCSession.isSupported()) {
            watchSession = WCSession.default
            watchSession!.delegate = self
            watchSession!.activate()
        }
    }
    
    @objc dynamic func importPattern(_ notification: Notification){
        let fname = notification.object as! String
        if let pattern = MidiSequencer.sharedInstance.patternFileToNoteTable(fname) {
            // BUG!, use signature from file
            let tempoSignature = MidiSequencer.sharedInstance.getTempoAndSignature()
           // SettingManager.sharedManager.barCount = 1 // By default for now
            self.patternSizeButton.setTitle("1", for: UIControl.State())
            self.currentFileName = fname
            self.title = currentFileName
            self.patternPageViewController.instrumentList = pattern
            self.patternPageViewController.pagesArray = []
            self.tempoTextField.text = String(tempoSignature.tempo)
            self.settingManager.tempo = Double(tempoSignature.tempo)
            self.settingManager.upperTimeSignature = tempoSignature.timeUpper
            self.settingManager.lowerTimeSignature = tempoSignature.timeLower
            self.settingManager.barCount = min(tempoSignature.barCount, 4)
            self.patternSizeButton.setTitle("\(tempoSignature.barCount)", for: UIControl.State())
            self.timeSignatureButton.setTitle("\(tempoSignature.timeUpper)/\(tempoSignature.timeLower)", for: UIControl.State())
            setCursorWidth()
            self.patternPageViewController.reloadData()
            self.patternPageViewController.hasChanges = false
           // MidiSequencer.sharedInstance.loadMidiFile(fname, toSequence: <#T##MusicSequence#>)
            iPadPatternName?.text = fname
        }
    }
    
    @objc dynamic func showPageNumber(_ notification: Notification){
        let pageNumber = notification.object as! String
        self.barNumber.text = pageNumber
        
        UIView.animate(withDuration: 1.0, animations:
            {self.barNumber.alpha = 0.5},
            completion: {_ in  //(value: Bool) in
                UIView.animate(withDuration: 1.0, animations:
                    {self.barNumber.alpha = 0.0})
        })
        
    }
    
    @objc dynamic func setTripletState(_ sender: UISwitch){
        print("Triplet is \(sender.isOn)")
        SettingManager.sharedManager.triplet = sender.isOn
        setDuration()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Move cursor after the table is initialized
        setCursorWidth() // and reload
        moveCursorToBeat(0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
    }
    
    func togglePlayerSegmentedControl(_ doPlay:Bool) {
        playerSegmentedControl.isEnabled = doPlay;
        playerSegmentedControl.isUserInteractionEnabled = doPlay;
        if doPlay {
            playerSegmentedControl.selectedSegmentIndex = PlayerControlEnum.play.rawValue
        }
    }
//    
//    @IBAction func actionClear(sender: AnyObject){
//        self.patternTableViewController.clearPattern()
//        moveCursorToBeat(0)
//        self.currentFileName = nil
//        
//    }

    @IBAction func loadPattern(_ sender: AnyObject) {
        if !self.sequencer.isMusicPlayerPlaying()  {
            self.patternPageViewController.createSequenceFromPattern()
            MidiSequencer.sharedInstance.initializeMusicPlayStartingAtBeat(0)
            MidiSequencer.sharedInstance.musicPlayerPlay()
        } else {
            MidiSequencer.sharedInstance.musicPlayerStop()
        }
        //self.sequencer.loadMIDIFile("Intro", ext: "mid")
    }
    
    //MARK: Segment player
    @IBAction func onNoteRestSegmentControlChange(_ sender: AnyObject) {
       let segmentControl:UISegmentedControl = sender as! UISegmentedControl
        if segmentControl.selectedSegmentIndex == 0 {
            self.settingManager.isRest = false
        } else {
            self.settingManager.isRest = true
        }
    }
    
    @IBAction func onNoteDurationSegmentControlChange(_ sender: AnyObject) {
        setDuration()
    }
    
    @IBAction func onPlayerSegmentControlChange(_ sender: AnyObject) {
        let segmentControl:UISegmentedControl = sender as! UISegmentedControl
        let index:PlayerControlEnum = PlayerControlEnum(rawValue: segmentControl.selectedSegmentIndex)!
        
        switch(index) {
        case .pause:
            self.sequencer.musicPlayerStop()
            break
        case .play:
            gatherSettingParams()
            patternPageViewController.createSequenceFromPattern()
            sequencer.initializeMusicPlayStartingAtBeat(0)
            sequencer.musicPlayerPlay()
            //playerSegmentedControl.selectedSegmentIndex = PlayerControlEnum.Deselect.rawValue
            break
        default:
            sequencer.musicPlayerStop()
        }
    }
    
    @IBAction func dropDownMenu (_ sender: AnyObject) {
        self.performSegue(withIdentifier: "menuPopoverSegue", sender: self)
    }
  
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func beatFractionFromNoteDuration(_ duration:NoteDurationEnum) -> Float {
        // Could have done some math here, but this is much clearer
        switch (duration) {
        case .whole:
            return 4.0 // 4 beats
        case .half:
            return 2.0 // 2 beats etc
        case .fourth:
            return 1.0
        case .eighth:
            return 0.5
        case .sixteenth:
            return 0.25
        case .thirtySecond:
            return 0.125
        }
    }

    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "padsSegue" {
            self.percussionPageViewController = segue.destination as? PercussionPageViewController
            (segue.destination as! PercussionPageViewController).mainViewController = self
        } else if segue.identifier == "patternsSegue" {
            self.patternPageViewController = segue.destination as? PatternPageViewController
//            self.patternTableViewController.noteSettings = self.noteSettings
        } else if segue.destination.isKind(of: PopupMenuViewController.self){
        //segue.identifier == "menuPopoverSegue" || segue.identifier == "newPopoverSegue" {
            let popoverViewController = segue.destination
            (popoverViewController as! PopupMenuViewController).delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    // MARK: text field delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.tempoTextField {
            dismissTempoKeyboard()
        } else if textField == self.iPadPatternName {
            savePattern()
        }
        return true;
    }
    
    func textField(_ textField:UITextField, shouldChangeCharactersIn range:NSRange, replacementString string:String ) -> Bool {

        if textField == self.tempoTextField {// 3 characters 0-2
            if range.location > 2 || (string.count > 0 && Int(string) == nil) {
                return false;
            }
        }
        return true;
    }
    
    func setupKeyBoardForTempoTextField() {
        let numberToolbar: UIToolbar = UIToolbar()
        numberToolbar.barStyle = UIBarStyle.blackTranslucent
        
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target:self, action: #selector(MainViewController.dismissTempoKeyboard))
        done.tintColor = UIColor.white
        numberToolbar.items = [done]
        
        numberToolbar.sizeToFit()
        self.tempoTextField.inputAccessoryView = numberToolbar //do it for every relevant textfield if there are more than one
    }
    
    @objc func dismissTempoKeyboard() {
        if self.tempoTextField.text?.lengthOfBytes(using: String.Encoding.ascii) > 0 {
            self.settingManager.tempo = Double(self.tempoTextField.text!)!
        }
        self.tempoTextField.resignFirstResponder()
    }
    
    func gatherSettingParams() {
        if self.tempoTextField.text?.lengthOfBytes(using: String.Encoding.ascii) > 0 {
            self.settingManager.tempo = Double(self.tempoTextField.text!)!
        }
        
    }

    func moveCursorToBeat(_ beat:Float){
        //find beats relative to current bar
        let quarterNotePerBar = self.settingManager.beatCountPerBar()
        let relativeBeat = beat.truncatingRemainder(dividingBy: quarterNotePerBar)
        
        let tableFrame = self.patternPageViewController.getCurrentTableFrame()        // var location = cursorView.frame.origin
        let x = self.patternViewLeadingConstraint.constant +
            (tableFrame.origin.x) +
            self.patternPageViewController.cursorStartX +
            (CGFloat(relativeBeat * self.settingManager.quantizeValue) * self.cursorWidthConstraint.constant) //self.cursorView.frame.width)
        
        DispatchQueue.main.async(execute: {
            var frame = self.cursorView.frame;
            frame.origin.x = x;
            self.cursorView.frame = frame;
        });
        self.cursorLeadingConstraint.constant = x
    }
    
    func scrollToRow(_ row:Int) {
        let bottom = self.patternPageViewController.instrumentList.count - 1
        let indexPath = row > bottom/2 ? IndexPath(row: bottom, section: 1) : IndexPath(row: 0, section: 0)
        self.patternPageViewController
            .getCurrentPageController()?
            .tableView
            .scrollToRow(at: indexPath, at:.none, animated: true)
        
    }
    
    // MARK: Gesture Callbacks
    
    @objc func panPatternTable(_ pan: UIPanGestureRecognizer) {
        var location = pan.location(in: view)
        let tableFrame = self.patternPageViewController.getCurrentTableFrame()
        
        switch pan.state {
        case .began:  break
            
        case .changed:
            // Get reference bounds.
            location.y = cursorView.center.y
           // let cursorWidth = cursorView.bounds.size.width
            let minX = (tableFrame.origin.x) + self.patternPageViewController.cursorStartX + self.cursorWidthConstraint.constant/2
            let maxX = (tableFrame.origin.x) + (tableFrame.size.width) - self.cursorWidthConstraint.constant/2
            if location.x >= minX && location.x <= maxX {
                location.y = cursorView.center.y
                // Apply the resulting item center.
                self.cursorView.center = location
                self.savedLocation.x = location.x
            }
        case .cancelled, .ended:
            // Get the current velocity of the item from the pan gesture recognizer.
            location = self.cursorView.center
            let quantizedBeats = floor((location.x - (tableFrame.origin.x) - self.patternPageViewController.cursorStartX)/self.cursorView.frame.width)
            
            location.x = self.patternViewLeadingConstraint.constant + tableFrame.origin.x + self.patternPageViewController.cursorStartX + (quantizedBeats * self.cursorView.frame.width) + self.cursorView.frame.width/2.0
            location.y = cursorView.center.y
            //update the beat position in pattern
            // move to quantized position
            UIView.animate(withDuration: 0.5, animations: {
                let dx = location.x - self.cursorView.center.x
                let dy = location.y - self.cursorView.center.y
                self.cursorView.transform = CGAffineTransform(translationX: dx, y: dy) });
            
            self.cursorLeadingConstraint.constant = self.cursorView.center.x - self.cursorView.frame.width/2.0;
            let position = Float(quantizedBeats)/self.settingManager.quantizeValue
            self.patternPageViewController.setBeatPosition(position)// cursorView.bounds.size.width/2.0)
        default: ()
        }
    }
    
    // MARK: Helper Functions
    fileprivate func setCursorWidth() {
        DispatchQueue.main.async(execute: {
            let quarterNotePerBar = self.settingManager.beatCountPerBar();
            let width  = (self.patternPageViewController.getCurrentTableFrame().width - self.patternPageViewController.cursorStartX) / CGFloat(quarterNotePerBar * self.settingManager.quantizeValue)
//            if self.settingManager.triplet {
//                self.cursorWidthConstraint.constant = width * 2 / 3
//            } else {
//                self.cursorWidthConstraint.constant = width
//            }
            self.cursorWidthConstraint.constant = width
            let height = self.patternPageViewController.getCurrentTableFrame().height/CGFloat(self.patternPageViewController.instrumentList.count/2 + 1)
            self.cursorTopConstraint.constant = height
            self.moveCursorToBeat(self.patternPageViewController.absCursorBeatPosition)
        });
    }
    
    func longPress(_ longPress: UILongPressGestureRecognizer) {
        guard longPress.state == .began else { return }
        
        // Toggle debug mode.
        //  animator.debugEnabled = !animator.debugEnabled
    }
    
    // MARK: PopoverMenuDelegate
    func menuSelectedOpen() {
       self.performSegue(withIdentifier: "fileSelectionSegue", sender: true)
    }
    
    func menuSelectedSave() {
        self.patternPageViewController.createSequenceFromPattern()
        gatherSettingParams()
        if let fname = self.currentFileName {
            _ = MidiFileManager.patternsSharedInstance.saveMidiPattern(fname, fromSequencer: MidiSequencer.sharedInstance)
        } else {
            // go to file selection screen
            self.performSegue(withIdentifier: "savePatternSegue", sender: false)
        }
    }

    func popupMenuSelectIndex(_ index: Int, title: String) {
        switch title {
        case "File":
            switch index {
            case 0:
                self.patternPageViewController.clearPattern()
                moveCursorToBeat(0)
                self.currentFileName = nil
                self.title = NSLocalizedString("New Pattern", comment: "File name on nav bar");
                break
            case 1:
                menuSelectedOpen()
                break
            case 2:
                menuSelectedSave()
                break
            default:
                break
            }
        case "Time":
            switch index {
            case 0:
                self.settingManager.upperTimeSignature = 2
                self.settingManager.lowerTimeSignature = 4
                self.timeSignatureButton.setTitle("2/4", for: UIControl.State())
                break
            case 1:
                self.settingManager.upperTimeSignature = 3
                self.settingManager.lowerTimeSignature = 4
                self.timeSignatureButton.setTitle("3/4", for: UIControl.State())
                break
            case 2:
                self.settingManager.upperTimeSignature = 4
                self.settingManager.lowerTimeSignature = 4
                self.timeSignatureButton.setTitle("4/4", for: UIControl.State())
                break
            case 3:
                self.settingManager.upperTimeSignature = 5
                self.settingManager.lowerTimeSignature = 4
                self.timeSignatureButton.setTitle("5/4", for: UIControl.State())
                break
            case 4:
                self.settingManager.upperTimeSignature = 6
                self.settingManager.lowerTimeSignature = 4
                self.timeSignatureButton.setTitle("6/4", for: UIControl.State())
                break
            case 5:
                self.settingManager.upperTimeSignature = 6
                self.settingManager.lowerTimeSignature = 8
                self.timeSignatureButton.setTitle("6/8", for: UIControl.State())
                break
            default:
                break
            }
            setQuantizeValue()
            setCursorWidth()
            self.patternPageViewController.reloadData()
         case "Size":
            switch index {
            case 0:
                self.settingManager.barCount = 1
                self.patternSizeButton.setTitle("1", for: UIControl.State())
                break
            case 1:
                self.settingManager.barCount = 2
                self.patternSizeButton.setTitle("2", for: UIControl.State())
                break
            case 2:
                self.settingManager.barCount = 4
                self.patternSizeButton.setTitle("4", for: UIControl.State())
                break
            default:
                break
            }
            self.patternPageViewController.reloadData()
            //setCursorWidth()
        case "DrumSet":
            SettingManager.sharedManager.drumset = index
            break
            
        default:
            break;
        }
        
    }
    
    fileprivate func setQuantizeValue() {
        self.settingManager.quantizeValue = 1/self.settingManager.duration
//        if self.settingManager.lowerTimeSignature == 8 {// special case for x/8
//            self.settingManager.quantizeValue /= 2
//        }

    }
    
    fileprivate func createNew(){
        if self.patternPageViewController.hasChanges {
            UIHelper.showAlertMessageWithOptions(NSLocalizedString("There are unsaved changes. Discard changes?", comment: "Alert when create new pattern"), withTitle:NSLocalizedString("Alert", comment: ""), onController:self, okAction: { _ in
                self.clearPattern()
            })
        }
        else {
            clearPattern()
        }
    }
    
    fileprivate func clearPattern() {
        self.patternPageViewController.clearPattern()
        self.currentFileName = nil
        self.title = NSLocalizedString("New Pattern", comment: "File name on nav bar");
        self.iPadPatternName?.text = nil
        moveCursorToBeat(0)
        
    }
    
    fileprivate func savePattern() {
        gatherSettingParams()
        patternPageViewController.truncateExcessBars()
        patternPageViewController.createSequenceFromPattern()
        patternPageViewController.reloadData()
        
        let check = self.currentFileName?.compare((iPadPatternName?.text)!) != .orderedSame
        let saved = MidiFileManager.patternsSharedInstance.checkAndSaveMidiFile((iPadPatternName?.text)!, sequencer: MidiSequencer.sharedInstance, onViewController: self, checkDuplicate: check)
        if saved {
            self.currentFileName = String(iPadPatternName!.text!).trimmingCharacters(in: CharacterSet.whitespaces)
            ToastFactory.makeCenterToast(NSLocalizedString("\"\(currentFileName!)\" saved", comment: ""), onView: self.view, isDark: false)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SavePatternNotification"), object: nil)
            patternPageViewController.hasChanges = false
        }
        self.iPadPatternName?.resignFirstResponder()
    }
    
    @objc func orientationChanged(_ note: Notification) {
        setCursorWidth()
    }
    
    // iWatch session Delegate
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        let tempoValue = message["tempo"] as? String
        DispatchQueue.main.async(execute: {
            self.tempoTextField.text = tempoValue
        });
        let action = message["action"] as? String
        if action == "start" {
            playerSegmentedControl.selectedSegmentIndex = PlayerControlEnum.play.rawValue
        } else {
            playerSegmentedControl.selectedSegmentIndex = PlayerControlEnum.pause.rawValue
        }
        replyHandler(["Value":"Hello Watch"])
        onPlayerSegmentControlChange(playerSegmentedControl)
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession){
        
    }
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    internal func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
    }
    
    func setDuration() {
        self.settingManager.duration = beatFractionFromNoteDuration(NoteDurationEnum(rawValue: durationSegmentControl.selectedSegmentIndex)!)
        if settingManager.triplet {
            settingManager.duration = settingManager.duration * 2 / 3
        }
        setQuantizeValue()
        setCursorWidth()
    }
}

enum PlayerControlEnum: Int {
    case deselect = -1
    case pause, play
}

