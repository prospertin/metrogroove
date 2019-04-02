//
//  DrumCollectionViewCell.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 9/6/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import UIKit

protocol DrumCellDelegate {
    func addNote(noteValue note:UInt8, withVelocity velocity:UInt8, toLine line:Int)
}

class DrumCollectionViewCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var settingButton: UIImageView!
    @IBOutlet weak var velocityLabel: UILabel!
    @IBOutlet var containerView: UIView! // Contain the button
    @IBOutlet weak var padButton: UIButton!
    @IBOutlet var patchSettingView: UIView!
    
    @IBAction func onPadHit(_ sender: AnyObject) {
        self.delegate.addNote(noteValue: self.noteValue, withVelocity: self.velocity, toLine: self.lineNumber)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.velocity = UInt8(sender.value)
        self.velocityLabel.text = "\(self.velocity)"
    }
    
    var delegate:DrumCellDelegate!
    var noteValue:UInt8!
    var velocity:UInt8 = 80 // Default
    var lineNumber:Int!
    var editMode:Bool = false
    var settingViewFrame:CGRect = CGRect() //Hack
    
    let margin = CGFloat(15)
    
    let press = UILongPressGestureRecognizer()
    
    @IBAction func onDragInside(_ sender: AnyObject){
        
        UIView.transition(with: patchSettingView,
            duration:1,
            options:UIViewAnimationOptions.transitionFlipFromRight,
            animations:{
                if (!self.editMode) {
                    self.padButton.isHidden = true
                    self.patchSettingView.isHidden = false
                    //[flipContainerView addSubview:backCard.view];
                    self.editMode = true
                } else {
                    self.padButton.isHidden = false
                    self.patchSettingView.isHidden = true
                    self.editMode = false
                    // [backCard removeFromSuperview]; //or hide it.
                }
                
            }, completion:nil)
    }
    
    func initSettingButton() {
        self.settingButton.layer.cornerRadius = self.settingButton.frame.size.height / 2;
        self.settingButton.layer.masksToBounds = true;
        self.settingButton.layer.borderWidth = 0;
        
        press.addTarget(self, action: #selector(DrumCollectionViewCell.flipView(_:)))
        self.settingButton.addGestureRecognizer(press)
       // self.addGestureRecognizer(press)
    }
    
    func flipView(_ longPress: UILongPressGestureRecognizer){
        guard longPress.state == .began else { return }
        // set a transition style
        let transitionOptions = UIViewAnimationOptions.transitionFlipFromRight
        var views : (frontView: UIView, backView: UIView)

        if !self.editMode {
            views = (frontView: self.containerView, backView: self.patchSettingView)
            self.padButton.isEnabled = false
            self.editMode = true
            self.velocityLabel.text = NSLocalizedString("Velocity", comment: "Label velocity")
        } else {
            //return
            views = (frontView: self.patchSettingView, backView: self.containerView)
            self.padButton.isEnabled = true
            self.editMode = false

        }
        UIView.transition(with: self,
                duration:1.0,
                options:transitionOptions,
                animations: {
                    // DONT DO THIS, it will deallocate the view 
                    //remove the front object...
                  //  views.frontView.removeFromSuperview()
                    // ... and add the other object
                    self.addSubview(views.backView)
                    
                },
                completion:{_ in
                    if self.editMode {
                        UIView.animate(withDuration: 2.0, animations: {
                            self.velocityLabel.alpha = 0
                            }, completion: {_ in
                            UIView.animate(withDuration: 1.0, animations: {
                                self.velocityLabel.text = "\(self.velocity)"
                                self.velocityLabel.alpha = 1
                                }, completion: nil )})
                    }
            })
    }
    
    func inFrame(_ frame:CGRect, point:CGPoint) -> Bool{
        
        return frame.contains(point)
    }
    
    func setConstraints(_ theView:UIView) {
        
        let edgeLength = self.frame.width - CGFloat(self.margin)
        
        let constX:NSLayoutConstraint = NSLayoutConstraint(item: theView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0);
        self.addConstraint(constX);

        let constY:NSLayoutConstraint = NSLayoutConstraint(item: theView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0);
        self.addConstraint(constY);

        let constW:NSLayoutConstraint = NSLayoutConstraint(item: theView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1, constant: edgeLength);
        self.addConstraint(constW);

        let constH:NSLayoutConstraint = NSLayoutConstraint(item: theView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1, constant: edgeLength);
        self.addConstraint(constH);
    }
    
    // Delegates
//    func gestureRecognizer(gestureRecognizer:UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool{
//        print("Item touched: \(touch)")
//        return false
//    }

}
