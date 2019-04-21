//
//  File.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 8/4/15.
//  Copyright © 2015 Prospertin. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

/**
Uses an AVAudioEngine with a AVAudioUnitSampler, which is a AVAudioUnitMIDIInstrument subclass.
That means you can send the sampler MIDI messages.
The sampler uses a Sound Font. In this class there is one sampler, so the instruments are
swapped in when a message is sent. For multi instrument polyphony, you'd need more than one sampler.
It subclasses NSObject so we can add it as a target.
*/
class MIDISampler : NSObject {
    var engine:AVAudioEngine!
    var playerNode:AVAudioPlayerNode!
    var mixer:AVAudioMixerNode!
    var sampler:AVAudioUnitSampler!
    /// soundbanks are either dls or sf2. see http://www.sf2midi.com/
    var soundbank:URL!
    let melodicBank:UInt8 = UInt8(kAUSampler_DefaultMelodicBankMSB)
    /// general midi number for marimba
    let gmMarimba:UInt8 = 12
    let gmHarpsichord:UInt8 = 6
    
    override init() {
        super.init()
        //        initAudioEngine()
        //        loadMIDIFile()
    }
    
    func initAudioEngine () {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        mixer = engine.mainMixerNode
        engine.connect(playerNode, to: mixer, format: mixer.outputFormat(forBus: 0))
        
        // MIDI
        sampler = AVAudioUnitSampler()
        engine.attach(sampler)
        engine.connect(sampler, to: engine.outputNode, format: nil)
        
        soundbank = Bundle.main.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2")
        
        var error:NSError?
        do {
            try engine.start()
        } catch let error1 as NSError {
            error = error1
            print("error couldn't start engine")
            if let e = error {
                print("error \(e.localizedDescription)")
            }
        }
    }
    
    var mp:AVMIDIPlayer!
    
    func loadMIDIFile() {
        // Load a SoundFont or DLS file.
        self.soundbank = Bundle.main.url(forResource: "GeneralUser GS MuseScore v1.442", withExtension: "sf2")
        print("soundbank \(String(describing: soundbank))")
        
        // a standard MIDI file.
        let contents:URL = Bundle.main.url(forResource: "ntbldmtn", withExtension: "mid")!
        print("contents \(contents)")
        
        var error:NSError?
        
        do {
            self.mp = try AVMIDIPlayer(contentsOf: contents, soundBankURL: soundbank)
        } catch let error1 as NSError {
            error = error1
            self.mp = nil
        }
        if self.mp == nil {
            print("nil midi player")
        }
        if let e = error {
            print("Error \(e.localizedDescription)")
        }
        self.mp.prepareToPlay()
        
        // well, what is the connection to the engine here? none!
     //!!!!!!!!!!!!!!!!!!!!!!   let frobs = MIDIFrobs()
    //    frobs.display(engine.musicSequence)
        //mp.musicSequence does not exist
        
    }
    
    func playMIDIFile() {
        self.mp.play({
            print("midi done")
        })
        
        // or
        //        var completion:AVMIDIPlayerCompletionHandler = {println("done")}
        //        mp.play(completion)
    }
    
    func playSequence() {
        if engine.isRunning {
            print("stopping the engine")
            engine.stop()
        }
        engine.musicSequence = sequence()
        var error:NSError?
        do {
            try engine.start()
        } catch let error1 as NSError {
            error = error1
            print("error couldn't start engine")
            if let e = error {
                print("error \(e.localizedDescription)")
            }
        }
        print("started the engine")
        
    }
    
    
    
    func sequence() -> MusicSequence {
        var status : OSStatus = 0
        var midiSequence:MusicSequence? = nil //MusicSequence()
        status = NewMusicSequence(&midiSequence)
        print("osstatus \(status)")
        print(midiSequence.debugDescription)
        
        var track:MusicTrack? = nil //MusicTrack()
        status = MusicSequenceNewTrack (midiSequence!, &track)
        print("osstatus \(status)")
        
        var message:MIDINoteMessage = MIDINoteMessage(channel: 0, note: 60, velocity: 64, releaseVelocity: 0, duration: 1.0)
        var timeStamp:MusicTimeStamp = 0
        status = MusicTrackNewMIDINoteEvent (track!, timeStamp, &message)
        print("osstatus \(status)")
        
        message = MIDINoteMessage(channel: 0, note: 65, velocity: 64, releaseVelocity: 0, duration: 1.0)
        timeStamp = 5
        status = MusicTrackNewMIDINoteEvent (track!, timeStamp, &message)
        print("osstatus \(status)")
        
        //CAShow(midiSequence)
        
        return midiSequence!
    }
    
//    func setupAudioTest {
//        AudioComponentDescription MixerUnitDescription;
//        MixerUnitDescription.componentType          = kAudioUnitType_Mixer;
//        MixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
//        MixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
//        MixerUnitDescription.componentFlags         = 0;
//        MixerUnitDescription.componentFlagsMask     = 0;
//    }
    
}
//.....
//    MusicSequenceSetAUGraph(s, _processingGraph);
//.......
//    MusicTrackSetDestNode(track[i], samplerNodes[i]);
//......
//    [self loadFromDLSOrSoundFont];
//......
//    MusicPlayerStart(p);
//
//
//AudioComponentDescription MixerUnitDescription;
//MixerUnitDescription.componentType          = kAudioUnitType_Mixer;
//MixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
//MixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
//MixerUnitDescription.componentFlags         = 0;
//MixerUnitDescription.componentFlagsMask     = 0;
//
//AudioComponentDescription cd = {};
//cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
//cd.componentType = kAudioUnitType_MusicDevice; // type - music device
//cd.componentSubType = kAudioUnitSubType_Sampler; // sub type - sampler to convert our MIDI
//
//result = NewAUGraph (&_processingGraph);
//result = AUGraphAddNode(self.processingGraph, &MixerUnitDescription, &mixerNode);
//
//result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode);
//
//result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode2);
//
//cd.componentType = kAudioUnitType_Output;  // Output
//cd.componentSubType = kAudioUnitSubType_RemoteIO;  // Output to speakers
//
//result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
//result = AUGraphOpen (self.processingGraph);
//
//result = AUGraphConnectNodeInput (self.processingGraph, samplerNode, 0, mixerNode, 0);
//result = AUGraphConnectNodeInput (self.processingGraph, samplerNode2, 0, mixerNode, 1);
//
//result = AUGraphConnectNodeInput (self.processingGraph, mixerNode, 0, ioNode, 0);
//result = AUGraphNodeInfo (self.processingGraph, samplerNode, 0, &_samplerUnit);
//result = AUGraphNodeInfo (self.processingGraph, samplerNode2, 0, &_samplerUnit2);
//result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);

//This is the example method from Apple Developer pages which i modified to assign a soundfont to a specific samplerUnit:

//-(OSStatus) loadFromDLSOrSoundFont: (NSURL *)bankURL withPatch: (int)presetNumber withAudioUnit:(AudioUnit)auUnit{
//    
//    OSStatus result = noErr;
//    
//    // fill out a bank preset data structure
//    AUSamplerBankPresetData bpdata;
//    bpdata.bankURL  = (__bridge CFURLRef) bankURL;
//    bpdata.bankMSB  = kAUSampler_DefaultMelodicBankMSB;
//    bpdata.bankLSB  = kAUSampler_DefaultBankLSB;
//    bpdata.presetID = (UInt8) presetNumber;
//    
//    // set the kAUSamplerProperty_LoadPresetFromBank property
//    result = AudioUnitSetProperty(auUnit,
//        kAUSamplerProperty_LoadPresetFromBank,
//        kAudioUnitScope_Global,
//        0,
//        &bpdata,
//        sizeof(bpdata));
//    
//    // check for errors
//    NSCAssert (result == noErr,
//        @"Unable to set the preset property on the Sampler. Error code:%d '%.4s'",
//        (int) result,
//        (const char *)&result);
//    
//    return result;
//}
//Then i did this twice to get each track into musicSequence:
//    
//    if(MusicSequenceFileLoad(tmpSequence, (__bridge CFURLRef)midiFileURL, 0, 0 != noErr))
//{
//    [NSException raise:@"play" format:@"Can't load MusicSequence"];
//}
//
//
//MusicSequenceGetIndTrack(tmpSequence, 0, &tmpTrack);
//MusicSequenceNewTrack(musicSequence, &track);
//MusicTimeStamp trackLen = 0;
//UInt32 trackLenLen = sizeof(trackLen);
//MusicTrackGetProperty(tmpTrack, kSequenceTrackProperty_TrackLength, &trackLen, &trackLenLen);
//MusicTrackCopyInsert(tmpTrack, 0, trackLenLen, track, 0);
//And finally:
//
//MusicTrackSetDestNode(track, samplerNode);
//MusicTrackSetDestNode(track2, samplerNode2);
//But this won't assign the the soundfont to the samplerUnit2:
//
//[self loadFromDLSOrSoundFont: (NSURL *)presetURL2 withPatch: (int)0 withAudioUnit:self.samplerUnit2];
//Assigning to samplerUnit works fi
