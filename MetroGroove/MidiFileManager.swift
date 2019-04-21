//
//  PatternFileManager.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 1/14/16.
//  Copyright © 2016 Prospertin. All rights reserved.
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


class MidiFileManager: NSObject {

    static let midiSharedInstance:MidiFileManager = MidiFileManager()
    static let patternsSharedInstance:MidiFileManager = MidiFileManager(fileExtension: ".mid")
    static let projectsSharedInstance:MidiFileManager = MidiFileManager(fileExtension: ".mgp");
    
    var fileExtension = ".mid"
    
    var fileList:[String]?
    var directoryPath:String!
    
    override init() {
        super.init();
        initFileDirectories(nil)
        self.fileList = getFileList()
    }
    
    init(fileExtension: String) {
        super.init();
        self.fileExtension = fileExtension
        initFileDirectories("")
        self.fileList = getFileList()
    }
    
    func initFileDirectories(_ dirName: String?) {
        let docDirs:Array<String>? = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true)
        if let dirs = docDirs {
            let dir = dirs[0]
            if dirName == nil || dirName == "" {
                directoryPath = dir
            } else {
                directoryPath = createdSubDirIfNotExistInDir(dir, subDirectory: dirName!)
            }
        }
    }
    
    func createdSubDirIfNotExistInDir(_ dir: String, subDirectory: String) -> String {
        do {
            let path = dir + "/\(subDirectory)"
            if !FileManager.default.fileExists(atPath: path) {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            }
            return path
        } catch {
            print("Error getting/creating dir \(dir)")
        }
        return ""
    }
        
    func getFileList() -> [String] {
        do {
            let fileMgr = FileManager.default
            let list = try fileMgr.contentsOfDirectory(atPath: directoryPath)
            fileList = []
            for fname in list {
                let attribs: NSDictionary? = try fileMgr.attributesOfItem(
                    atPath: "\(directoryPath!)/\(fname)") as NSDictionary?
                let type = attribs!["NSFileType"] as! FileAttributeType
                if type != FileAttributeType.typeDirectory && fname.hasSuffix(fileExtension){
                    // remove extension
                    let extIndex = fname.index(fname.endIndex, offsetBy: -fileExtension.count)
                    fileList?.append(String(fname[..<extIndex]))
                }
            }
            return fileList!
        } catch {
            print("Error getting file list \(error)")
            return []
        }
    }
  
    func deleteFile(_ filename:String) -> Bool {
        let fileUrl = getUrlForFile(filename)
        if let url = fileUrl {
            do {
                try FileManager.default.removeItem(atPath: url.path);
                self.fileList = getFileList()
                return true
            } catch {
                print(error)
            }
        }
        return false
    }
    
    func getUrlForFile(_ filename:String) -> URL? {
        return URL(fileURLWithPath: directoryPath + "/\(filename.trimmingCharacters(in: CharacterSet.whitespaces))\(fileExtension)");
       // return NSURL(string: directoryPath.stringByAppendingString("/\(filename)"))
    }
    
    func checkAndSaveMidiFile(_ fname: String?, sequencer:MidiSequencer, onViewController vc:UIViewController, checkDuplicate:Bool) -> Bool {
        
        if let error = checkFile(fname, checkDuplicate: checkDuplicate) {
            showMessage( error, withTitle: nil, onViewController: vc)
            return false
        } else {
            if saveMidiPattern("\(fname!)", fromSequencer: sequencer) {
                return true
            }
            showMessage( "Error saving file", withTitle: nil, onViewController: vc)
            return false
        }
    }
    
    func saveMidiPattern(_ fname:String?, fromSequencer sequencer:MidiSequencer) -> Bool {
        let fileUrl = getUrlForFile(fname!)
        let rv = sequencer.saveSequenceMidiToFileUrl(fileUrl!)
        self.fileList = getFileList()
        return rv
    }
    
    func checkFile(_ fname: String?, checkDuplicate:Bool) -> String? {
        if fname != nil && fname?.count > 0  {
            
            if isValidFileName(fname!) == false {
                return NSLocalizedString("Invalid file name. Please use alpha-numerics, spaces, '_' and '-'.", comment: "invalid file name")

            }
            let existingFiles = getFileList()
            if checkDuplicate && existingFiles.contains(fname!) {
                // show existing file error
                return NSLocalizedString("File already exists", comment: "File exists when save")
            } else {
                // Ok to save
                self.fileList = getFileList()
                return nil
            }
        } else {
            // Show no name error
            return NSLocalizedString("Please enter a file name", comment: "File not exists when save")
        }

    }
    
    func isValidFileName(_ name: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[A-Z0-9 _-]+$", options: [.caseInsensitive])
        
        return regex.firstMatch(in: name, options:[], range: NSMakeRange(0, name.count)) != nil
    }
    
    func showMessage(_ message:String, withTitle title:String?, onViewController vc:UIViewController) {
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: title, message:
                message, preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "File alert"), style: UIAlertAction.Style.default,handler: nil))
            vc.view.window!.rootViewController!.present(alertController, animated: true, completion: nil)
        })
    }
    

    func saveProjectFile(_ fname: String, project: Project, checkDuplicate: Bool, onViewController vc: UIViewController) -> Bool{
        if let error = checkFile(fname, checkDuplicate: checkDuplicate) {
            showMessage( error, withTitle: nil, onViewController: vc)
            return false
        } else {
            if let pathUrl = getUrlForFile(fname) {
                NSKeyedArchiver.archiveRootObject(project, toFile: pathUrl.path)
                self.fileList = getFileList()
                return true
            }
        }
        return false
    }

    func loadProjectFile(_ fname: String) -> Project? {
        if let pathUrl = getUrlForFile(fname) {
            if let proj = NSKeyedUnarchiver.unarchiveObject(withFile: pathUrl.path) {
                return proj as? Project
            } else {
                return nil
            }
        }
        return nil
    }
}
