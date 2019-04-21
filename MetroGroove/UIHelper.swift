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
            message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "File alert"), style: UIAlertAction.Style.default,handler: nil))
        parent.present(alertController, animated: true, completion: nil)
    }
    
    static func showAlertMessageWithOptions(_ message:String, withTitle title:String?, onController parent:UIViewController, okAction: @escaping ((UIAlertAction) -> Void)) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertAction.Style.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm"), style: UIAlertAction.Style.destructive, handler: okAction ))
        parent.present(alertController, animated: true, completion: nil)
    }
    
}
