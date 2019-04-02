//
//  UIHelper.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 5/5/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//
import UIKit

class UIHelper: NSObject {

    static func showAlertMessage(_ message:String, withTitle title:String?, onController parent:UIViewController) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "File alert"), style: UIAlertActionStyle.default,handler: nil))
        parent.present(alertController, animated: true, completion: nil)
    }
    
    static func showAlertMessageWithOptions(_ message:String, withTitle title:String?, onController parent:UIViewController, okAction: @escaping ((UIAlertAction) -> Void)) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertActionStyle.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm"), style: UIAlertActionStyle.destructive, handler: okAction ))
        parent.present(alertController, animated: true, completion: nil)
    }
    
}
