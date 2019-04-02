//
//  PatternCollectionViewCell.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 3/1/16.
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


protocol PatternSectionDelegate {
    func removeSection(_ atIndex: Int)
    func highlightSection(_ atIndex: Int)
    func updateBarCount(_ count: Int, atIndex: Int)
    func updateSectionName(_ name: String, atIndex: Int)
}

class PatternCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var patternNameLabel: UILabel!
    @IBOutlet weak var barCount: UITextField!
    @IBOutlet weak var sectionNameTextField: UITextField!
    
    @IBAction func deleteSection(_ sender: AnyObject) {
        removeSection()
    }
   
  
    static let highlightColor = UIColor(red: 255/255, green: 33/255, blue: 28/255, alpha: 1)
    static let regularColor = UIColor(red: 171/255, green: 33/255, blue: 28/255, alpha: 1)

    let tap = UITapGestureRecognizer()
    let press = UILongPressGestureRecognizer()
    var index:Int = -1
    var patternSectionDelegate:PatternSectionDelegate?
    var animating:Bool = false
    //    override init(frame: CGRect) {
//        super.init(frame: frame)
//        tap.numberOfTapsRequired = 2
//        tap.addTarget(self, action: "removeNote:")
//        self.addGestureRecognizer(tap)
//    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func awakeFromNib() {
        tap.numberOfTapsRequired = 1
        patternNameLabel.addGestureRecognizer(tap)
        tap.addTarget(self, action: #selector(PatternCollectionViewCell.highlightSection(_:)))
        barCount.delegate = self // text field delegate
        sectionNameTextField.delegate = self
        press.addTarget(self, action: #selector(PatternCollectionViewCell.showNameEditor(_:)))
        //self.padButton.addGestureRecognizer(press)
        self.addGestureRecognizer(press)
    }
    
    func showNameEditor(_ recognizer: UILongPressGestureRecognizer){
        sectionNameTextField.text = patternNameLabel.text
        sectionNameTextField.isHidden = false
        sectionNameTextField.becomeFirstResponder()
    }
    
//    func launchPatternSectionEditor(recognizer: UILongPressGestureRecognizer){
//        if patternSectionDelegate != nil {
//            patternSectionDelegate?.launchSectionEditor(self.index)
//        }
//    }
    
    func removeSection() {
        if patternSectionDelegate != nil {
            let parent = patternSectionDelegate as! UIViewController
            let alert = UIAlertController(
                title: NSLocalizedString("Confirmation", comment: "Alert dialog"),
                message: NSLocalizedString("Remove '\(patternNameLabel!.text!)' bars(\(barCount!.text!))?", comment: "Delete pattern confirmation"),
                preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertActionStyle.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Confirm delete button"), style: UIAlertActionStyle.destructive, handler: { _ in
                PatchManager.sharedManager.playPopSound()
                self.patternSectionDelegate?.removeSection(self.index)
                } ))
            parent.present(alert, animated: true, completion: nil)
        }
    }
    
    func highlightSection(_ recognizer: UITapGestureRecognizer) {
        let duration = 0.5
        let delay = 0.0
        let options = UIViewKeyframeAnimationOptions.calculationModePaced
        if animating {
            return
        }
        animating = true
        let isHighlighted = self.backgroundColor == PatternCollectionViewCell.highlightColor
        UIView.animateKeyframes(withDuration: duration, delay: delay, options: options, animations: {
            
            // note that we've set relativeStartTime and relativeDuration to zero.
            // Because we're using `CalculationModePaced` these values are ignored
            // and iOS figures out values that are needed to create a smooth constant transition
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0, animations: {
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.backgroundColor = isHighlighted ? PatternCollectionViewCell.regularColor : PatternCollectionViewCell.highlightColor
              //  self.transform = CGAffineTransformTranslate(self.transform, 100.0, 200)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0, animations: {
                self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
            
            }, completion: { _ in
                self.animating = false
        })
        patternSectionDelegate?.highlightSection(isHighlighted ? -1 : index)
    }
    
    // MARK: text field delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard(textField)
        return true
    }
    
    func textField(_ textField:UITextField, shouldChangeCharactersIn range:NSRange, replacementString string:String ) -> Bool {
        if textField == barCount {
            if range.location > 2 || (string.characters.count > 0 && Int(string) == nil) {// 3 characters 0-2 and numerical
                return false;
            }
        }
        return true;
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        dismissKeyboard(textField)
        return true
    }
    
    func setupKeyBoardForTempoTextField() {
        let numberToolbar: UIToolbar = UIToolbar()
        numberToolbar.barStyle = UIBarStyle.blackTranslucent
        
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target:self, action: #selector(PatternCollectionViewCell.dismissKeyboard))
        done.tintColor = UIColor.white
        numberToolbar.items = [done]
        
        numberToolbar.sizeToFit()
        barCount.inputAccessoryView = numberToolbar //do it for every relevant textfield if there are more than one
        
    }
    
    func dismissKeyboard(_ textField: UITextField) {
        textField.resignFirstResponder()
        if textField == barCount {
            patternSectionDelegate?.updateBarCount(Int(barCount.text!) ?? 1, atIndex:index)
        } else  {
            if sectionNameTextField.text != nil && sectionNameTextField.text?.characters.count > 0 {
                patternNameLabel.text = sectionNameTextField.text
            }
            sectionNameTextField.isHidden = true
            patternSectionDelegate?.updateSectionName(patternNameLabel.text!, atIndex: index)
        }
    }


}
