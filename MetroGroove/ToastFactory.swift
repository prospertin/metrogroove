//
//  ToastFactory.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 3/14/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//
import UIKit

class ToastFactory: NSObject {
    
    // Toaster params
    static let toastMaxWidth:CGFloat = 250.0;
    static let toastPadding:CGFloat = 15.0;
    static let toastMaxMessageWidth:CGFloat = 220.0;
    static let toastLineMaxHeight:CGFloat = 20.0;
    static let toastCornerRadius:CGFloat = 8.0;
    static let toastBackgroundOpacity:CGFloat = 0.8;
    static let toastOpacity:CGFloat = 0.8;
    static let toastMaxLine:CGFloat = 20;
    static let toastTopMargin:CGFloat = 70.0;
    //Toast shadow
    static let toastShadowOpacity:Float = 0.8;
    static let toastShadowRadius:CGFloat = 6.0;
    static let toastShadowOffset = CGSize( width: 4.0, height: 4.0 );
    static let toastDefaultDuration:TimeInterval = 3.0;
    static let toastFadeDuration:TimeInterval = 0.5;
    //Toast Label
    static let toastLabelAlpha:CGFloat = 1.0;
    static let toastLabelFontSize:CGFloat = 14.0;
    
    static func makeTopToast(_ message: String, onView parentView: UIView, isDark: Bool) {
        let toastView = ToastFactory.createToastWithMessage(message, isDark: isDark)
        ToastFactory.showToast(toastView!, onView: parentView, duration: toastDefaultDuration, yPosition: toastTopMargin);
    }
    
    static func makeCenterToast(_ message: String, onView parentView: UIView, isDark: Bool) {
        let toastView = ToastFactory.createToastWithMessage(message, isDark: isDark)
        ToastFactory.showToast(toastView!, onView: parentView, duration: toastDefaultDuration, yPosition: parentView.bounds.height/2);
    }
    
    static func showToast(_ toast: UIView, onView parentView: UIView, yPosition: CGFloat) {
        toast.center = CGPoint(x: parentView.bounds.size.width/2, y: (toast.frame.size.height / 2) + yPosition)
        toast.alpha = toastOpacity
        parentView.addSubview(toast)
        UIView.animate(withDuration: toastFadeDuration, delay:0.0, options:([.curveEaseOut, .allowUserInteraction]),
            animations: {
                toast.alpha = toastOpacity;
            },
            completion: nil);
    }
    
    static func showToast(_ toast: UIView, onView parentView: UIView, duration: TimeInterval, yPosition: CGFloat) {
        toast.center = CGPoint(x: parentView.bounds.size.width/2, y: (toast.frame.size.height / 2) + yPosition)
        toast.alpha = toastOpacity
        parentView.addSubview(toast)
        UIView.animate(withDuration: toastFadeDuration, delay:0.0, options:([.curveEaseOut, .allowUserInteraction]),
            animations: {
                toast.alpha = toastOpacity;
            },
            completion: { _ in
                Timer.scheduledTimer(timeInterval: duration, target:self, selector:#selector(ToastFactory.toastTimerFinish(_:)), userInfo:toast, repeats:false)
                // associate the timer with the toast view
        });
    }
    
    dynamic static func toastTimerFinish(_ timer: Timer){
        ToastFactory.dismissToast(timer.userInfo as! UIView);
        timer.invalidate();
    }
    
    static fileprivate func dismissToast(_ toast: UIView) {
        UIView.animate(withDuration: toastFadeDuration, delay: 0.0, options:([.curveEaseIn, .beginFromCurrentState]),
            animations: {
                toast.alpha = 0.0;
            },
            completion: { _ in
                toast.removeFromSuperview()
            });
    }
    
    static fileprivate func createToastWithMessage(_ message: String?, isDark: Bool) -> UIView? {
        guard (message != nil) else  {
            return nil
        }
        let toastView = UIView()
        toastView.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin]
        //UIViewAutoresizing.FlexibleTopMargin | 
        toastView.layer.cornerRadius = toastCornerRadius
        //Shadow
        toastView.layer.shadowColor = UIColor.black.cgColor
        toastView.layer.shadowOpacity = toastShadowOpacity
        toastView.layer.shadowRadius = toastShadowRadius;
        toastView.layer.shadowOffset = toastShadowOffset;
        toastView.backgroundColor = isDark ? UIColor.black.withAlphaComponent(toastBackgroundOpacity) : UIColor.white//.colorWithAlphaComponent(toastBackgroundOpacity) ;
        
        let msgLabel = UILabel();
        msgLabel.numberOfLines = 0; //Init to zero so it will be set dynamically
       // msgLabel.font = [UIFont fontWithName:"HelveticaNeue-Light" size:toastLabelFontSize];
        msgLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        msgLabel.textAlignment = NSTextAlignment.center;
        msgLabel.textColor = isDark ?  UIColor.white : UIColor.black
        msgLabel.backgroundColor = UIColor.clear
        msgLabel.alpha = toastLabelAlpha;
        msgLabel.text = message;
        
        // size the message label according to the length of the text
        let maxSizeMessage = CGSize(width: toastMaxMessageWidth, height: toastLineMaxHeight * toastMaxLine);
        let expectedSizeMessage = sizeForString(message! as NSString, font: msgLabel.font, constrainedToSize: maxSizeMessage, lineBreakMode: msgLabel.lineBreakMode);
        let messageWidth = expectedSizeMessage.width;
        let messageHeight = expectedSizeMessage.height;
        let msgX = (toastMaxWidth - messageWidth)/2;
        let msgY = toastPadding;
        
        toastView.frame = CGRect(x: 0.0, y: 0.0, width: toastMaxWidth, height: messageHeight + 2 * toastPadding);
        msgLabel.frame = CGRect(x: msgX, y: msgY, width: messageWidth, height: messageHeight);
        toastView.addSubview(msgLabel)
        
        return toastView
    }
    
    static fileprivate func sizeForString(_ string: NSString, font: UIFont, constrainedToSize: CGSize, lineBreakMode: NSLineBreakMode) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = lineBreakMode;
        let attributes = [NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle];
        let boundingRect = string.boundingRect(with: constrainedToSize, options:NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attributes, context:nil);
        let width:Float = Float(boundingRect.size.width)
        let height:Float = Float(boundingRect.size.height)
        return CGSize(width: CGFloat(ceilf(width)), height: CGFloat(ceilf(height)));
    }

}
