//
//  PopupPatternTableViewController.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 2/27/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//

import UIKit

class PopupPatternTableViewController: UITableViewController {

    var delegate: PopoverMenuDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return MidiFileManager.patternsSharedInstance.fileList!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "patternPopupCell", for: indexPath)
        cell.textLabel?.text = MidiFileManager.patternsSharedInstance.fileList![indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Add the pattern to the project
        DispatchQueue.main.async(execute: {
            self.dismiss(animated: true, completion: { self.delegate.popupMenuSelectIndex(indexPath.row, title: self.title!)} )
        });
    }
    
    // MARK: UISearchBarDelegate
}
