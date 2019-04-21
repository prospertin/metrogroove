
//
//  PatternFilesTableViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 1/29/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//
import UIKit

class PatternFilesTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   // @IBOutlet weak var tabBar: UITabBarItem!
    //var fileList:Array<String>?
    
    //var searchController:UISearchController!
    // var resultController:SearchResultTableViewController!
    var patternViewController:MainViewController?
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBAction func onCancel(_ sender: AnyObject) {
        // self.searchController.active = false
        dismiss()
    }
    
    @IBAction func onOpen(_ sender: AnyObject) {
        //let fname = self.searchController.searchBar.text
        let fname = self.searchBar.text!
        if MidiFileManager.patternsSharedInstance.fileList?.contains(fname) == false {
            showMessage(NSLocalizedString("File doesn't exist, please select a pattern file.", comment: "File not exists"), withTitle: nil)
            return;
        }
        else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ImportPatternNotification"), object: self.searchBar.text!)
            dismiss()
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
            selector: #selector(PatternFilesTableViewController.updateFileListTable(_:)),
            name: NSNotification.Name(rawValue: "SavePatternNotification"),
            object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Showing pattern file list")
        if patternViewController == nil {
            patternViewController = self.storyboard!.instantiateViewController(withIdentifier: "patternViewController") as? MainViewController
        }
        if let svc = splitViewController {
            svc.showDetailViewController(patternViewController!, sender: self)

        }
    }
    
    func configureSearchBar() {
        self.navigationBar.topItem!.title = NSLocalizedString("Patterns", comment: "Import Title on file selection")
        self.searchBar.placeholder = "Search pattern..."
        self.searchBar.setValue(NSLocalizedString("Open", comment: "Import button"), forKey:"_cancelButtonText"); // Override the default cancel button
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
        return MidiFileManager.patternsSharedInstance.fileList!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileTableCell", for: indexPath)
        cell.textLabel?.text = MidiFileManager.patternsSharedInstance.fileList![indexPath.row]
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Return false if you do not want the specified item to be editable.
        self.searchBar.text = MidiFileManager.patternsSharedInstance.fileList![indexPath.row]
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let fname = MidiFileManager.patternsSharedInstance.fileList!.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            _ = MidiFileManager.patternsSharedInstance.deleteFile(fname)
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
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: UISearchBarDelegate
    
    // Called when the search bar becomes first responder
    func updateSearchResultsForSearchController(_ searchController: UISearchController) {
        debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showMessage(_ message:String, withTitle title:String?) {
        UIHelper.showAlertMessage(message, withTitle:title, onController:self)
    }
    
    @objc dynamic func updateFileListTable(_ notification: Notification){
        self.tableView.reloadData()
    }
}
