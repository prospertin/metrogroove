//
//  DataModel.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 3/12/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//

import Foundation

enum NoteDurationEnum: Int {
    case whole = 0
    case half, fourth, eighth, sixteenth, thirtySecond
}

class Note: NSObject, NSCoding {
    var pitch:UInt8 = 0
    var velocity:UInt8 = 0
    var beatPosition:Float = 0
    var endPosition:Float = 0
    
    override init() { super.init() }
    
    init(pitch: UInt8, velocity: UInt8, beatPosition: Float, endPosition: Float) {
        self.pitch = pitch
        self.velocity = velocity
        self.beatPosition = beatPosition
        self.endPosition = endPosition
    }
    
    required init(coder aDecoder: NSCoder) {
        pitch = UInt8(aDecoder.decodeInteger(forKey: "pitch"))
        velocity = UInt8(aDecoder.decodeInteger(forKey: "velocity"))
        beatPosition = Float(aDecoder.decodeFloat(forKey: "beatPosition"))
        endPosition = Float(aDecoder.decodeFloat(forKey: "endPosition"))
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(Int(pitch), forKey: "pitch")
        aCoder.encode(Int(velocity), forKey: "velocity")
        aCoder.encode(Float(beatPosition), forKey: "beatPosition")
        aCoder.encode(Float(endPosition), forKey: "endPosition")
    }
}

class Project: NSObject, NSCoding {
    var tempo:String
    var sections:Array<Section>
    
    init(tempo aTempo: String, sections:Array<Section>) {
        self.tempo = aTempo
        self.sections = sections
    }
    
    required init(coder aDecoder: NSCoder) {
        tempo = aDecoder.decodeObject(forKey: "tempo") as? String ?? "120"
        sections = (aDecoder.decodeObject(forKey: "sections") as? NSArray ?? []) as! Array<Section>
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(tempo, forKey: "tempo")
        aCoder.encode(sections, forKey:"sections");
    }
}

class ProjectSequencer {
    var sequencer: MidiSequencer?
    var projectName: String?
    var beatPosition: Float = 0
}

class Section: NSObject, NSCoding {
    var patternName:String!
    var count:Int = 0
    var pattern:[Array<Note>] //Note tables
    var timeSignature:(upper: Int, lower: Int)
    var patternBarCount = 1
    
    init(patternName: String, count: Int, timeSignature:(upper: Int, lower: Int), barCount: Int, pattern: [Array<Note>]) {
        self.patternName = patternName
        self.count = count
        self.timeSignature = timeSignature
        self.pattern = pattern
        self.patternBarCount = barCount
    }
    
    required init(coder aDecoder: NSCoder) {
        patternName = aDecoder.decodeObject(forKey: "patternName") as? String ?? ""
        count = aDecoder.decodeInteger(forKey: "count")
        let patternObjC = aDecoder.decodeObject(forKey: "pattern") as? NSArray ?? []
        pattern = []
        for lineArr in patternObjC {
            pattern.append(lineArr as! Array<Note>)
        }
        let timeUpper = aDecoder.decodeInteger(forKey: "timeUpper")
        let timeLower = aDecoder.decodeInteger(forKey: "timeLower")
        timeSignature = (timeUpper, timeLower)
        patternBarCount = aDecoder.decodeInteger(forKey: "patternBarCount")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(patternName, forKey: "patternName")
        aCoder.encode(count, forKey: "count")
        let patternObjC = NSMutableArray()
        for lineArr in pattern {
            patternObjC.add(NSArray(array: lineArr))
        }
        aCoder.encode(patternObjC, forKey:"pattern");
        aCoder.encode(timeSignature.upper, forKey: "timeUpper")
        aCoder.encode(timeSignature.lower, forKey: "timeLower")
        aCoder.encode(patternBarCount, forKey: "patternBarCount")
    }
    
}
