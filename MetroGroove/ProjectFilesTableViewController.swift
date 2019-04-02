//
//  FileTableViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 12/4/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ProjectFilesTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MidiPlayerDelegate {

   // @IBOutlet weak var tabBar: UITabBarItem!
    //var fileList:Array<String>?
    var midiPlayerViewController:MidiPlayerViewController?
    var projectViewController:ProjectViewController?
    //var searchController:UISearchController!
   // var resultController:SearchResultTableViewController!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBAction func onCancel(_ sender: AnyObject) {
       // self.searchController.active = false
        dismiss()
    }
    
    @IBAction func onOpen(_ sender: AnyObject) {
        let fname = searchBar.text!
        if MidiFileManager.projectsSharedInstance.fileList?.contains(fname) == false {
            showMessage(NSLocalizedString("File doesn't exist, please select project file.", comment: "File not exists"), withTitle: nil)
            return;
        }
        else {
            if fname.characters.count > 5 { //?.mid
                //check if suffix is .mid
                let fname = self.searchBar.text!
                if let index = fname.range(of: ".", options: .backwards)?.lowerBound {
                    let ext = fname.substring(from: index)
                    if ext == ".mid" {
                        let fileUrl = MidiFileManager.projectsSharedInstance.getUrlForFile(fname)
                        if midiPlayerViewController == nil {
                            midiPlayerViewController = self.storyboard!.instantiateViewController(withIdentifier: "genericMidiPlayer") as? MidiPlayerViewController;
                        }
                        midiPlayerViewController!.loadMidiFileFromUrl(fileUrl, displayName:fname)
                        displayMidiPlayer()
                        return
                    }
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "OpenProjectNotification"), object: fname)
           // dismiss()
        }
    }
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var tableView:UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // self.fileList = getMidiFileList()
        configureSearchBar()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ProjectFilesTableViewController.updateFileListTable(_:)),
            name: NSNotification.Name(rawValue: "SaveProjectNotification"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ProjectFilesTableViewController.launchMidiPlayer(_:)),
            name: NSNotification.Name(rawValue: "PlayProjectNotification"),
            object: nil)
        // Create an instance of a midiplayer

    }

    override func viewWillAppear(_ animated: Bool) {
        print("Showing project file list")
        if projectViewController == nil {
            projectViewController = self.storyboard!.instantiateViewController(withIdentifier: "projectViewController") as? ProjectViewController
        }
        splitViewController?.showDetailViewController(projectViewController!, sender: self)
    }
    
    func configureSearchBar() {
        self.navigationBar.topItem!.title = NSLocalizedString("Projects", comment: "Project Title on file selection")
        self.searchBar.placeholder = "Search project..."
        self.searchBar.setValue(NSLocalizedString("Open", comment: "Open button"), forKey:"_cancelButtonText"); // Override the default cancel button
        self.searchBar.tintColor =  UIColor.white
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return MidiFileManager.projectsSharedInstance.fileList!.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileTableCell", for: indexPath)
        cell.textLabel?.text = MidiFileManager.projectsSharedInstance.fileList![indexPath.row]
        
        return cell
    }

    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Return false if you do not want the specified item to be editable.
        self.searchBar.text = MidiFileManager.projectsSharedInstance.fileList![indexPath.row]
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let fname = MidiFileManager.projectsSharedInstance.fileList!.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            _ = MidiFileManager.projectsSharedInstance.deleteFile(fname)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
//     MARK: - Navigation
//
//     In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToAviPlayerController" {
            if let avpVC = segue.destination as? AVPlayerViewController {
                print("Launching avi player")
                DispatchQueue.main.async {
                    let url = MidiFileManager.projectsSharedInstance.getUrlForFile(self.searchBar.text!)
                    avpVC.player = AVPlayer(url: url!)
                }
            }
        }
    }

    
    // MARK: UISearchBarDelegate
    
    // Called when the search bar becomes first responder
    func updateSearchResultsForSearchController(_ searchController: UISearchController) {
        debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func dismiss() {
       self.dismiss(animated: true, completion: nil)
    }
    
    func showMessage(_ message:String, withTitle title:String?) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "File alert"), style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    dynamic func updateFileListTable(_ notification: Notification){
        self.tableView.reloadData()
    }
    
    dynamic func launchMidiPlayer(_ notification: Notification) {
        let projSeq = notification.object as! ProjectSequencer
        guard let sequencer = projSeq.sequencer else {
            return
        }
        var alreadyShow = true
        if midiPlayerViewController == nil {
            alreadyShow = false
            midiPlayerViewController = self.storyboard!.instantiateViewController(withIdentifier: "genericMidiPlayer") as? MidiPlayerViewController;
            midiPlayerViewController?.midiPlayerDelegate = self
        } else if !(view.subviews.contains(midiPlayerViewController!.view )) {
            alreadyShow = false
        }
        // Could be a separate midiSequencer instance?
        sequencer.initializeMusicPlayStartingAtBeat(projSeq.beatPosition)
        midiPlayerViewController!.sequencer = sequencer
        if let name = projSeq.projectName {
            midiPlayerViewController!.displayName = name
        }
        if alreadyShow == false {
            displayMidiPlayer()
        } else {
           // midiPlayerViewController?.counterPicker.reloadAllComponents()
            DispatchQueue.main.async(execute: {
               self.initMidiPlayerController()
            })
            
        }
    }
    
    fileprivate func displayMidiPlayer() {
        midiPlayerViewController!.view.frame = CGRect(x:0, y:0, width:view.frame.size.width, height:view.frame.size.height);
        UIView.transition(with: view,
            duration:1.0,
            options:UIViewAnimationOptions.transitionCrossDissolve,
            animations: {
                self.initMidiPlayerController()
                self.view.addSubview(self.midiPlayerViewController!.view)
            }, completion: nil)

    }
    
    fileprivate func initMidiPlayerController() {
        self.midiPlayerViewController?.segmentControl.selectedSegmentIndex = MidiPlayerControlEnum.pause.rawValue
        self.midiPlayerViewController?.fileNameLabel.text = self.midiPlayerViewController?.displayName
        self.midiPlayerViewController?.counterPicker.reloadComponent(0)
    }
    
    //MARK: playerDelegate
    func playerClose() {
    
    }
}
