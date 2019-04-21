//
//  searchResultTableViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 12/6/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import UIKit

class SaveTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var fnameTextField: UITextField!
    
    @IBAction func onSave(_ sender: UIButton) {
        let fname = self.fnameTextField.text
        if MidiFileManager.patternsSharedInstance.checkAndSaveMidiFile(fname, sequencer: MidiSequencer.sharedInstance, onViewController:self, checkDuplicate: true) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        let list = MidiFileManager.patternsSharedInstance.getFileList()
        return list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileTableCell", for: indexPath)
        cell.textLabel?.text = MidiFileManager.patternsSharedInstance.fileList![indexPath.row]
        return cell
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

}
