//
//  NoteView.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 12/24/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//
import UIKit

protocol NoteViewDelegate {
    func removeNote(_ note:Note, atLine line:Int)
}

class NoteView: UIView {
    var note:Note!
    var delegate:NoteViewDelegate?
    var line:Int!
    
   // let tap = UITapGestureRecognizer()
    let press = UILongPressGestureRecognizer()
    
    init(frame:CGRect, forNote note:Note, atLine line:Int) {
        super.init(frame: frame)
        self.note = note
        self.line = line
        //tap.numberOfTapsRequired = 2
        press.addTarget(self, action: #selector(NoteView.removeNote(_:)))
        self.addGestureRecognizer(press)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func removeNote(_ recognizer: UITapGestureRecognizer) {
        self.removeFromSuperview()
        delegate?.removeNote(self.note, atLine:line)
    }

}
