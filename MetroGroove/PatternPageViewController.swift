//
//  PatternPageControllerViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 12/30/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import UIKit
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


let MAX_INSTRUMENT_COUNT = 18

class PatternPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate{

    var pagesArray:Array<PatternTableViewController> = []
    var instrumentList:[Array<Note>] = []
    var absCursorBeatPosition:Float = 0.0 // number of beats from the start of pattern.
    var timer:Timer!
    
    var cursorStartX:CGFloat = 0 //Hacky find a better way
    var hasChanges = false
    
   // var currentTableView:UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for _ in 0...MAX_INSTRUMENT_COUNT - 1  {
            self.instrumentList.append([])
        }
        resizePagesToCount(SettingManager.sharedManager.barCount)
        // Do any additional setup after loading the view.
        self.dataSource = self
        self.delegate = self
        
        self.setViewControllers([pagesArray.first!], direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        self.cursorStartX = (getCurrentPageController()?.startX)!
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: - Paging
    //Called before a gesture-driven transition begins.
    func pageViewController(_ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]) {
    }
    
    //Called after a gesture-driven transition completes.
    func pageViewController(_ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool) {
            if completed {
                let currentIndex = getCurrentPageController()?.pageIndex
                self.absCursorBeatPosition = SettingManager.sharedManager.beatCountPerBar()
                    * Float(currentIndex!)
                    + self.absCursorBeatPosition.truncatingRemainder(dividingBy: SettingManager.sharedManager.beatCountPerBar())
                NotificationCenter.default.post(name: Notification.Name(rawValue: "PageChangeNotification"), object: String(currentIndex! + 1))
            }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! PatternTableViewController).pageIndex
        return viewControllerAtIndex(index! - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! PatternTableViewController).pageIndex
        return viewControllerAtIndex(index! + 1)
    }
    
//    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
//        return self.pagesArray.count
//    }
//
//    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
//        return 0
//    }
   
    func viewControllerAtIndex(_ index: Int) -> PatternTableViewController! {
        if index < 0 || index >= self.pagesArray.count {
            return nil
        }
        else {
            return pagesArray[index]
        }
    }
    
    func resizePagesToCount(_ count: Int) {
        let currentPageIndex = getCurrentPageController()?.pageIndex
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if count < pagesArray.count {
            self.pagesArray.removeSubrange(count..<pagesArray.count) //Range<Int>(start: count, end: pagesArray.count))
        } else if count > pagesArray.count {
            for i in pagesArray.count..<count {
                let vc = storyboard.instantiateViewController(withIdentifier: "patternTableViewController") as! PatternTableViewController
                vc.pageIndex = i
                vc.pageViewController = self// Pass to table
                pagesArray.append(vc)
            }
        }
        
        if currentPageIndex > count - 1 {
            slideToPage(count - 1, animation: true, completion: nil) // slide to the last page
        } else if currentPageIndex != nil {
            slideToPage(currentPageIndex!, animation: false, completion: nil) // slide to the same page - trick to update the pager
        }
    }
    /*
    // MARK - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    // MARK: Load/process data
    func reloadData() {
        resizePagesToCount(SettingManager.sharedManager.barCount)
     //   getCurrentPageController()?.tableView.reloadData()
        for page in self.pagesArray {
            page.tableView.reloadData()
        }
    }

    func getCurrentTableFrame() -> CGRect {
        return self.view.frame //tableView.superview?.frame

    }
    
    func setBeatPosition(_ relativeBeat:Float){
        if let pageIndex = getCurrentPageController()?.pageIndex {
            self.absCursorBeatPosition = relativeBeat +  Float(pageIndex) * SettingManager.sharedManager.beatCountPerBar()
            //SettingManager.sharedManager.upperTimeSignature)
        } else {
            self.absCursorBeatPosition = relativeBeat
        }
    }
    
    func clearPattern(){
        for line in 0...instrumentList.count - 1 {
            self.instrumentList[line] = [];
        }
        // Reinititialize sequencer
        let drumset = SettingManager.sharedManager.drumset
        MidiSequencer.sharedInstance.initPercussionSequenceWithPatch(UInt8(drumset), trackCount: instrumentList.count)
        MidiSequencer.sharedInstance.addTempoTrack(SettingManager.sharedManager.tempo,
            timeSignature:(SettingManager.sharedManager.upperTimeSignature, lower: SettingManager.sharedManager.lowerTimeSignature), barCount: SettingManager.sharedManager.barCount)
        self.pagesArray = []
        self.reloadData()
        self.absCursorBeatPosition = 0
    }
    
    func addNoteWithPitch(_ pitch:UInt8, velocity:UInt8, toLine line:Int, completion block:((Float) -> Void)?) -> Float {
        hasChanges = true
        if velocity > 0 {
            let note = Note(pitch:pitch, velocity:SettingManager.sharedManager.isRest ? 0 : velocity,
                beatPosition: self.absCursorBeatPosition,
                endPosition: self.absCursorBeatPosition + SettingManager.sharedManager.duration)
            insertNote(note, toLine:line)
            getCurrentPageController()?.tableView.reloadData()
        }
        self.absCursorBeatPosition += SettingManager.sharedManager.duration
        
        var cursorMoved = false
        if self.absCursorBeatPosition >= SettingManager.sharedManager.totalPatternBeats() {
            self.absCursorBeatPosition = 0.0;
            if pagesArray.count > 1 {
                slideToPage(0, animation: true, completion: { _ in
                    block!(self.absCursorBeatPosition)
                })
                cursorMoved = true
            }
        } else {
            if let currentPage = getCurrentPageController() {
                let beatPerPage = SettingManager.sharedManager.beatCountPerBar()
                if self.absCursorBeatPosition >= Float(currentPage.pageIndex + 1 ) * beatPerPage {
                    self.slideToPage(currentPage.pageIndex + 1, animation: true, completion:  { _ in
                        block!(self.absCursorBeatPosition)
                    })
                    cursorMoved = true
                }
            }
        }
        // if cursor is not moved by sliding to another page, do it here
        if cursorMoved == false {
            block!(self.absCursorBeatPosition)
        }
        return self.absCursorBeatPosition
    }
    
    func insertNote(_ note:Note, toLine line:Int) {
        var lineArray = instrumentList[line]
    
        for i in 0..<lineArray.count {
            let existingNote = lineArray[i]
            //Replacing an existing note
            if note.beatPosition == existingNote.beatPosition {
                lineArray.insert(note, at: i)
                // chop notes that overlap
                self.instrumentList[line] = adjustSubsequentNotesToFitNote(note, fromIndex: i+1, inNoteList: lineArray)
                return
                
            }
            else if note.beatPosition < existingNote.beatPosition {
                if i > 0 {
                    let previousNote = lineArray[i-1]
                    // chop previous note if it's end note overlap new note
                    if previousNote.endPosition > note.beatPosition {
                        previousNote.endPosition = note.beatPosition
                    }
                    lineArray[i-1] = previousNote
                }
                lineArray.insert(note, at: i)
                //chop subsequent notes that overlap
                self.instrumentList[line] = adjustSubsequentNotesToFitNote(note, fromIndex: i+1, inNoteList: lineArray)
                return
            }
        }
        
        lineArray.append(note)
        self.instrumentList[line] = lineArray
        //return lineArray //Reassign array line, becasue lineArray is just a copy of the original line
    }
    
    fileprivate func adjustSubsequentNotesToFitNote(_ note:Note, fromIndex index: Int, inNoteList lineArray:Array<Note>) -> Array<Note> {
        var newLine = Array<Note>()
   
        for i in 0..<lineArray.count {
            let nextNote = lineArray[i]
            if i < index || nextNote.beatPosition >= note.endPosition{
                newLine.append(nextNote)
            }
        }
        return newLine
    }
    
    /*
    * Pattern is ready, transform them to midi message and load them up
    */
    func createSequenceFromPattern() {
        let sequencer = MidiSequencer.sharedInstance
        let drumset = SettingManager.sharedManager.drumset
        sequencer.initPercussionSequenceWithPatch(UInt8(drumset), trackCount: instrumentList.count)
        sequencer.addTempoTrack(SettingManager.sharedManager.tempo,
            timeSignature:(SettingManager.sharedManager.upperTimeSignature, lower: SettingManager.sharedManager.lowerTimeSignature), barCount: SettingManager.sharedManager.barCount)
        // Transform each note to midi message and add them to the corresponding track
        for line in 0...instrumentList.count - 1 {
            let track = UInt32(line)
            for note in instrumentList[line] {
                sequencer.addNoteToPercussionTrack(track, note: note.pitch, beat: note.beatPosition,
                    velocity: note.velocity, releaseVelocity: UInt8(0), duration: note.endPosition - note.beatPosition)
            }
            
            sequencer.setLoopForTrack(line, withLen: Int(SettingManager.sharedManager.totalPatternBeats()))
        }
    }
    
    func truncateExcessBars() {
        // Transform each note to midi message and add them to the corresponding track
        for line in 0...instrumentList.count - 1 {
            var newLine:Array<Note> = []
            for note in instrumentList[line] {
                if note.beatPosition >= SettingManager.sharedManager.totalPatternBeats() {
                    break;
                }
                newLine += [note]
            }
            instrumentList[line] = newLine
        }
    }

    func getCurrentPageController() -> PatternTableViewController? {
        if self.viewControllers!.count > 0 {
            return  (self.viewControllers![self.viewControllers!.count - 1] as! PatternTableViewController)
        } else {
          return nil
        }
    }
    
    func slideToPage(_ pageIndex:Int, animation:Bool, completion: ((Void) -> Void)?) {
        if pageIndex >=  self.pagesArray.count || pageIndex < 0 {
            return
        }
        let destPage = viewControllerAtIndex(pageIndex)
        //let viewControllers = [destPage];
        let direction = pageIndex > getCurrentPageController()?.pageIndex ? UIPageViewControllerNavigationDirection.forward : UIPageViewControllerNavigationDirection.reverse
        let visiblePages:Array<UIViewController> = [destPage!]
        setViewControllers(visiblePages, direction:direction, animated:animation, completion: { _ in
            if let block = completion{
                block()
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "PageChangeNotification"), object: String(pageIndex + 1))
        });
    }
    
   //MARK: Recording
    func record() {
        let interval = (TimeInterval)(Double(60.0)/SettingManager.sharedManager.tempo * Double(SettingManager.sharedManager.quantizeValue))
        timer = Timer.scheduledTimer(timeInterval: interval, target:self, selector: #selector(PatternPageViewController.updateBeat), userInfo: interval, repeats: true)
    }
    
    func stopRecord() {
        timer.invalidate()
        timer = nil
    }
    
    func updateBeat() {
        let interval = timer.userInfo as! TimeInterval
        absCursorBeatPosition = (absCursorBeatPosition + Float(interval)).truncatingRemainder(dividingBy: (Float(SettingManager.sharedManager.upperTimeSignature) * Float(SettingManager.sharedManager.barCount)))
    }

}
