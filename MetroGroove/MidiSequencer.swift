//
//  MidiSequencer.swift
//  MetroGroove
//
//  Created by Thinh Nguyen on 7/29/15.
//  Copyright (c) 2015 Prospertin. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class MidiSequencer: NSObject {
    
    static let sharedInstance:MidiSequencer = MidiSequencer()
    //Callbakc
    var midiClientRef = MIDIClientRef()
    var destEndpointRef = MIDIEndpointRef()
    var midiInputPortref = MIDIPortRef()
    typealias MIDIReader = (_ ts:MIDITimeStamp, _ data: UnsafePointer<UInt8>, _ length: UInt16) -> ()
    typealias MIDINotifier = (_ message:UnsafePointer<MIDINotification>) -> ()
    
    //
    var musicSequence:MusicSequence? = nil // We can only deal with 1 sequence at a time.
    var musicPlayer:MusicPlayer? = nil
    var processingGraph:AUGraph? = nil
    var samplerUnit:AudioUnit? = nil
    var sequenceDuration:Float = 0
    var beatPerBar:Float = 0
    
    let soundFontMuseCoreName = "GeneralUser GS MuseScore v1.442"

    override init() {
        super.init()
        initAudioGraph()
        startAudioGraph()
    }
    // Wrapper to handle global drum sequence
    func initPercussionSequenceWithPatch(_ patch:UInt8, trackCount:Int) {
        if self.musicSequence != nil {
            DisposeMusicSequence(self.musicSequence!)
        }
        self.musicSequence = createPercussionSequenceWithPatch(patch, trackCount: trackCount)!
        MusicSequenceSetAUGraph(self.musicSequence!, self.processingGraph)
        loadSoundToSamplerUnitWithPreset(patch) //Preset 0 -- 1st set
        setCallBack()
    }
    
    func setCallBack() {
//        MidiNoteUserCallback.setNoteOnCallback({ (ts:MusicTimeStamp) in
//            print("TimeStamp \(ts)")
//        })
//        MusicSequenceSetUserCallback(musicSequence, MidiNoteUserCallback.midiNoteUser(), nil);
//        
        initMidiInterceptor()
        let status = MusicSequenceSetMIDIEndpoint(musicSequence!, self.destEndpointRef)
        if status != OSStatus(noErr) {
            print("error setting sequence endpoint \(status)")
        }
    }
    func addTempoTrack(_ tempo:Float64, timeSignature:(upper: Int, lower: Int), barCount: Int) {
        createTempoTrackForSequence(musicSequence!, tempo: tempo, timeSignature: timeSignature, barCount: barCount)
    }
    // MARK: Add note/data
    func addNoteToPercussionTrack(_ track: UInt32, note: UInt8, beat: Float, velocity: UInt8, releaseVelocity: UInt8, duration: Float32) {
        addNoteToTrack(track, beat:beat, channel:UInt8(9), note:note, velocity:velocity, releaseVelocity:releaseVelocity, duration:duration, musicSequence:self.musicSequence!)
    }
    
    ///
    func createPercussionSequenceWithPatch(_ patch:UInt8, trackCount:Int) -> MusicSequence? {
        var sequence:MusicSequence? = nil
        let status = NewMusicSequence(&sequence)
        if (status != OSStatus(noErr)) {
            print("\(#line) bad status \(status) creating sequence")
            handleStatus(status)
            return nil;
        }
        
        // Create musicTrack -- unique track for drums for now?
        for i in 1...trackCount {
            print("track \(i)")
            addTrackWithPatch(patch, forSequence: sequence!)
        }
        return sequence;
        
    }
    
    func createTempoTrackForSequence(_ sequence: MusicSequence, tempo: Float64, timeSignature: (upper: Int, lower: Int), barCount: Int) {
        // Create tempoTrack
        var tempoTrack:MusicTrack? = nil //MusicTrack()
        if MusicSequenceGetTempoTrack(sequence, &tempoTrack) != noErr {
            print("Cannot get tempo track")
        }
        //MusicTrackClear(tempoTrack, 0, 1)
        if MusicTrackNewExtendedTempoEvent(tempoTrack!, 0.0, tempo) != noErr {
            print("could not set tempo")
        }
        
        //Set time signature to 7/16(
        let data:[UInt8] = [UInt8(timeSignature.upper), UInt8(timeSignature.lower), UInt8(barCount), 0x08] //0x18, 0x08]
        let timeSignatureMetaEvent = MyMetaEvent(type: 0x58, data: data)
        //let timeSignatureMetaEvent = MyMetaEvent(type: kMusicEventType_Meta, data: data)
        //
        //        timeSignatureMetaEvent.metaEventType = kMusicEventType_Meta //0x58;
        //        timeSignatureMetaEvent.dataLength = 4;
        //        timeSignatureMetaEvent.data[0] = 0x07;
        //        timeSignatureMetaEvent.data[1] = 0x04;
        //        timeSignatureMetaEvent.data[2] = 0x18;
        //        timeSignatureMetaEvent.data[3] = 0x08;
        if MusicTrackNewMetaEvent(tempoTrack!, 0, timeSignatureMetaEvent.metaEventPtr) != noErr {
            print("Could not set time signature")
        }
    }
    
    func addTrackWithPatch(_ patch:UInt8, forSequence sequence:MusicSequence) {
        var musicTrack: MusicTrack? = nil
        var status = MusicSequenceNewTrack(sequence, &musicTrack)
        if status != OSStatus(noErr) {
            print("\(#line) bad status \(status) creating track")
            handleStatus(status)
        }
        
        // bank select msb
        var chanMsg = MIDIChannelMessage(status: 0xB9, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(musicTrack!, 0, &chanMsg)
        if status != OSStatus(noErr) {
            print("creating bank select event \(status)")
        }
        // bank select lsb
        chanMsg = MIDIChannelMessage(status: 0xB9, data1: 32, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(musicTrack!, 0, &chanMsg)
        if status != OSStatus(noErr) {
            print("creating bank select event \(status)")
        }

        chanMsg = MIDIChannelMessage(status: 0xC9, data1: patch, data2:0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(musicTrack!, 0, &chanMsg)
        if status != OSStatus(noErr) {
            print("creating program change event \(status)")
        }
    }
 
    func addNoteToTrack(_ trackNumber:UInt32, beat:Float, channel:UInt8, note:UInt8, velocity:UInt8, releaseVelocity:UInt8, duration:Float32, musicSequence:MusicSequence) {
        let track = getTrack(trackNumber, fromSequence:musicSequence)
        var midiMsg = MIDINoteMessage(channel:channel, note:note, velocity:velocity, releaseVelocity: releaseVelocity, duration:duration)
        
        addMidiNoteMessage(&midiMsg, toTrack:track, atBeat:beat)
    }

    func addMidiNoteMessage(_ noteMsgPtr:UnsafePointer<MIDINoteMessage>, toTrack track:MusicTrack, atBeat beat:Float) {
        var status = OSStatus(noErr)
        status = MusicTrackNewMIDINoteEvent(track, MusicTimeStamp(beat), noteMsgPtr)
        if status != OSStatus(noErr) {
            print("bad status \(status) creating note event")
            handleStatus(status)
        }
    }
    
//    func addRestToTrack(track:MusicTrack, atBeat beat:Float, duration:Float32) {
//        var midiMsg = MIDINote
//    }
    
    func getTrack(_ trackIndex:UInt32, fromSequence sequence:MusicSequence) -> MusicTrack {
        var track:MusicTrack? = nil
        let status = MusicSequenceGetIndTrack(sequence, trackIndex, &track)
        if status != OSStatus(noErr) {
            print("bad status \(status) getting track")
            handleStatus(status)
        }
        return track!
    }
    
    //MARK: SAMPLER audio
    func loadSoundToSamplerUnitWithPreset(_ preset:UInt8)  {//preset = patch number
        if let bankURL = Bundle.main.url(forResource: soundFontMuseCoreName, withExtension: "sf2") {
            var instdata = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(bankURL as CFURL),
                instrumentType: UInt8(kInstrumentType_DLSPreset),
                bankMSB: UInt8(kAUSampler_DefaultPercussionBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                presetID: preset)
            
            let status = AudioUnitSetProperty(
                self.samplerUnit!,
                UInt32(kAUSamplerProperty_LoadInstrument),
                UInt32(kAudioUnitScope_Global),
                0,
                &instdata,
                UInt32(MemoryLayout<AUSamplerInstrumentData>.size))
            handleStatus(status)
        }
    }

    func initAudioGraph() {
        // Create Audio Graph
        var samplerNode:AUNode = AUNode() //TODO ????????????
        var status = NewAUGraph(&self.processingGraph)
        //Create Sampler
        var componentDescription:AudioComponentDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_Sampler),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        if status == OSStatus(noErr) {
            status = AUGraphAddNode(self.processingGraph!, &componentDescription, &samplerNode)
        }
        // Create ioNode
        var ioNode:AUNode = AUNode()
        var ioUnitDescription:AudioComponentDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        status = AUGraphAddNode(self.processingGraph!, &ioUnitDescription, &ioNode)
        
        //Obtain Audio Unit
        var ioUnit:AudioUnit? = nil //AudioUnit()
        self.samplerUnit = nil //AudioUnit()
        status = AUGraphOpen(self.processingGraph!)
        status = AUGraphNodeInfo(self.processingGraph!, samplerNode, nil, &samplerUnit)
        status = AUGraphNodeInfo(self.processingGraph!, ioNode, nil, &ioUnit)
        // Wire them ?
        let ioUnitOutputElement:AudioUnitElement = 0
        let samplerOutputElement:AudioUnitElement = 0
        status = AUGraphConnectNodeInput(self.processingGraph!,
                samplerNode, samplerOutputElement, // srcnode, inSourceOutputNumber
                ioNode, ioUnitOutputElement) // destnode, inDestInputNumber
        
    }
    
    func startAudioGraph() {
        // Initialize and start Graph
        var outIsInitialized:DarwinBoolean = false
        var status = AUGraphIsInitialized(self.processingGraph!, &outIsInitialized)
        if outIsInitialized == false {
            status = AUGraphInitialize(self.processingGraph!)
        }
        
        var isRunning:DarwinBoolean = false
        AUGraphIsRunning(self.processingGraph!, &isRunning)
        if isRunning == false {
            status = AUGraphStart(self.processingGraph!)
        }
        handleStatus(status)
    }
    
    func playNote(_ pitch:UInt8, velocity:UInt8, channel:UInt8)    {
        // or with channel. channel is 0 in this example
        let noteCommand = UInt32(0x90 | 0)
        MusicDeviceMIDIEvent(self.samplerUnit!, noteCommand, UInt32(pitch), UInt32(velocity), UInt32(channel))
    }
    
    func stopNote(_ pitch:UInt8, channel:UInt8)    {
        let noteCommand = UInt32(0x80 | 0)
        MusicDeviceMIDIEvent(self.samplerUnit!, noteCommand, UInt32(pitch), 0, UInt32(channel))
    }
    
    let stopNoteBlock = stopNote
    
    // MARK: Sequencer load/play
    func seqToData(_ musicSequence:MusicSequence) -> Data {
        var status = OSStatus(noErr)
        var data:Unmanaged<CFData>?
        status = MusicSequenceFileCreateData(musicSequence, MusicSequenceFileTypeID.midiType, MusicSequenceFileFlags.eraseFile,
            480, &data)
        if status != OSStatus(noErr) {
            handleStatus(status)
            return Data() // Empty data?
        }
        let ns:Data = data!.takeRetainedValue() as Data
        return ns
    }
    
    func setLoopForTrack(_ trackNum:Int, withLen len:Int) {
        let track:MusicTrack = getTrack(UInt32(trackNum), fromSequence:self.musicSequence!)
        setTrackLoopDuration(track, duration:MusicTimeStamp(len))
    }
    
    func setTrackLoopDuration(_ musicTrack:MusicTrack, duration:MusicTimeStamp)   {
        print("loop duration to \(duration)")
        var loopInfo = MusicTrackLoopInfo(loopDuration: duration, numberOfLoops: 0)
        let loopInfoLen:Int = MemoryLayout<MusicTrackLoopInfo>.size;
        let status = MusicTrackSetProperty(musicTrack, kSequenceTrackProperty_LoopInfo, &loopInfo, UInt32(loopInfoLen) )
        if status != OSStatus(noErr) {
            print("Error setting loopinfo on track \(status)")
            return
        }
    }

    //MARK: music player control
    
    func initializeMusicPlayStartingAtBeat(_ startBeatPosition: Float) {
        disposeCurrentMusicPlayer()
        NewMusicPlayer(&musicPlayer);
        MusicPlayerSetSequence(musicPlayer!, musicSequence);
        MusicPlayerSetTime(musicPlayer!, MusicTimeStamp(startBeatPosition))
        MusicPlayerPreroll(musicPlayer!);
        let tempoSign = getTempoAndSignature()
        beatPerBar = SettingManager.sharedManager.beatCountPerBar(upperTimeSignature: Int(tempoSign.timeUpper), lowerTimeSignature: Int(tempoSign.timeLower))
    }
    
    func isMusicPlayerPlaying() -> Bool {
        if musicPlayer == nil {
            return false
        }
        var isPlaying:DarwinBoolean = false
        MusicPlayerIsPlaying(musicPlayer!, &isPlaying)
        
        return isPlaying == true
    }
    
    func setStartMusicPlayerAtBeat(_ beat: Float) {
        if musicPlayer != nil {
            MusicPlayerSetTime(musicPlayer!, MusicTimeStamp(beat))
        }
    }
    
    func musicPlayerPlay(){
        if musicPlayer == nil {
            return
        }
        if !isMusicPlayerPlaying() {
            MusicPlayerStart(musicPlayer!);
        }
    }
    
    func musicPlayerStop(){
        if musicPlayer == nil {
            return
        }
        if isMusicPlayerPlaying() {
            MusicPlayerStop(musicPlayer!)
        }
    }
    // MARK: get tempo and signature info from tracks

    func getTempoFromSequence() -> Int {
        var tempoTrack:MusicTrack? = nil //MusicTrack()
        if MusicSequenceGetTempoTrack(musicSequence!, &tempoTrack) != noErr {
            return 0
        }
        var iterator:MusicEventIterator? = nil;
        NewMusicEventIterator(tempoTrack!, &iterator);
        
        var timeStamp:MusicTimeStamp  = 0
        var eventType:MusicEventType = 0
        var eventData:UnsafeRawPointer? = nil //Equivalent to void*
        var eventDataSize:UInt32  = 0
        
        MusicEventIteratorGetEventInfo(iterator!, &timeStamp, &eventType, &eventData, &eventDataSize);
        let data = eventData?.bindMemory(to: ExtendedTempoEvent.self, capacity: 1)
        let tempo = data?.pointee.bpm
        
        return Int(tempo!)
    }
    
    func getTempoAndSignature() -> (tempo: Int, timeUpper: Int, timeLower: Int, barCount: Int) {
        var status:OSStatus = noErr;
        var tempoTrack: MusicTrack? = nil //MusicTrack()
    
        var tempo: Int = 120
        var timeUpper = 4
        var timeLower = 4
        var barCount = 1
        
        status = MusicSequenceGetTempoTrack(musicSequence!, &tempoTrack);
        if noErr != status {
            handleStatus(status)
            return (0, 0, 0, 0)
        }
    
        // Create an interator
        var iterator: MusicEventIterator? = nil
        NewMusicEventIterator(tempoTrack!, &iterator);
        var eventData:UnsafeRawPointer? = nil //Equivalent to void*
        var timeStamp:MusicTimeStamp  = 0
        var eventDataSize:UInt32  = 0
        var eventType:MusicEventType = 0
        
        var hasNext:DarwinBoolean = true;
 
        // Iterate over events
        while hasNext.boolValue {
    
            // See if there are any more events
            // Copy the event data into the variables we prepared earlier
            MusicEventIteratorGetEventInfo(iterator!, &timeStamp, &eventType, &eventData, &eventDataSize);
    
            // Process Midi Note messages
            if(eventType==kMusicEventType_ExtendedTempo) {
                // Cast the midi event data as a midi note message
                let data = eventData?.bindMemory(to: ExtendedTempoEvent.self, capacity: 1)
                tempo = Int((data?.pointee.bpm)!)
            } else if (eventType == kMusicEventType_Meta){
                var byte:UInt8 = 0
                let size = MemoryLayout<MIDIMetaEvent>.size
                //let ptr = eventData?.bindMemory(to: MIDIMetaEvent.self, capacity: 1)
                let ptr = eventData?.bindMemory(to: UInt8.self, capacity: size)
                /* MIDIMetaEvent size = 4 UInt8 + 1 Int32 = 8 bytes
                 public var metaEventType: UInt8
                 
                 public var unused1: UInt8
                 
                 public var unused2: UInt8
                 
                 public var unused3: UInt8
                 
                 public var dataLength: UInt32
                 
                 public var data: (UInt8) <==== skip 8 bytes to get to these 4 bytes of data

                 */
                memcpy(&byte, (ptr! + 8), 1)
                timeUpper = Int(byte)
                memcpy(&byte, (ptr! + 9) , 1)
                timeLower = Int(byte)
                memcpy(&byte, (ptr! + 10), 1)
                barCount = Int(byte)
            
//                memcpy(&byte, eventData + 8, 1)
//                timeUpper = Int(byte)
//                memcpy(&byte, eventData + 9, 1)
//                timeLower = Int(byte)
//                memcpy(&byte, eventData + 10, 1)
//                barCount = Int(byte)
            }
            MusicEventIteratorHasNextEvent(iterator!, &hasNext)
            if hasNext.boolValue {
                MusicEventIteratorNextEvent(iterator!)
            }
        }
        return (tempo, timeUpper, timeLower, barCount)
    }
    //MARK this section is for AVMidiPlayer
    
    func handleStatus(_ status:OSStatus) {
        
        if status == 0 {return}
        
        switch(status) {
            // AudioToolbox
        case kAUGraphErr_NodeNotFound:
            print("Error:kAUGraphErr_NodeNotFound \n");
            
        case kAUGraphErr_OutputNodeErr:
            print( "Error:kAUGraphErr_OutputNodeErr \n");
            
        case kAUGraphErr_InvalidConnection:
            print("Error:kAUGraphErr_InvalidConnection \n");
            
        case kAUGraphErr_CannotDoInCurrentContext:
            print( "Error:kAUGraphErr_CannotDoInCurrentContext \n");
            
        case kAUGraphErr_InvalidAudioUnit:
            print( "Error:kAUGraphErr_InvalidAudioUnit \n");
            
            // Core MIDI constants. Not using them here.
//                case kMIDIInvalidClient :
//                    print( "kMIDIInvalidClient ");
//            
//            
//                case kMIDIInvalidPort :
//                    print( "kMIDIInvalidPort ");
//            
//            
//                case kMIDIWrongEndpointType :
//                    print( "kMIDIWrongEndpointType");
//            
//            
//                case kMIDINoConnection :
//                    print( "kMIDINoConnection ");
//            
//            
//                case kMIDIUnknownEndpoint :
//                    print( "kMIDIUnknownEndpoint ");
//            
//            
//                case kMIDIUnknownProperty :
//                    print( "kMIDIUnknownProperty ");
//            
//            
//                case kMIDIWrongPropertyType :
//                    print( "kMIDIWrongPropertyType ");
//            
//            
//                case kMIDINoCurrentSetup :
//                    print( "kMIDINoCurrentSetup ");
//            
//            
//                case kMIDIMessageSendErr :
//                    print( "kMIDIMessageSendErr ");
//            
//            
//                case kMIDIServerStartErr :
//                    print( "kMIDIServerStartErr ");
//            
//            
//                case kMIDISetupFormatErr :
//                    print( "kMIDISetupFormatErr ");
//            
//            
//                case kMIDIWrongThread :
//                    print( "kMIDIWrongThread ");
//            
//            
//                case kMIDIObjectNotFound :
//                    print( "kMIDIObjectNotFound ");
//            
//            
//                case kMIDIIDNotUnique :
//                    print( "kMIDIIDNotUnique ");
//            
            
        case kAudioToolboxErr_InvalidSequenceType :
            print( " kAudioToolboxErr_InvalidSequenceType ");
            
        case kAudioToolboxErr_TrackIndexError :
            print( " kAudioToolboxErr_TrackIndexError ");
            
        case kAudioToolboxErr_TrackNotFound :
            print( " kAudioToolboxErr_TrackNotFound ");
            
        case kAudioToolboxErr_EndOfTrack :
            print( " kAudioToolboxErr_EndOfTrack ");
            
        case kAudioToolboxErr_StartOfTrack :
            print( " kAudioToolboxErr_StartOfTrack ");
            
        case kAudioToolboxErr_IllegalTrackDestination	:
            print( " kAudioToolboxErr_IllegalTrackDestination");
            
        case kAudioToolboxErr_NoSequence 		:
            print( " kAudioToolboxErr_NoSequence ");
            
        case kAudioToolboxErr_InvalidEventType		:
            print( " kAudioToolboxErr_InvalidEventType");
            
        case kAudioToolboxErr_InvalidPlayerState	:
            print( " kAudioToolboxErr_InvalidPlayerState");
            
        case kAudioUnitErr_InvalidProperty		:
            print( " kAudioUnitErr_InvalidProperty");
            
        case kAudioUnitErr_InvalidParameter		:
            print( " kAudioUnitErr_InvalidParameter");
            
        case kAudioUnitErr_InvalidElement		:
            print( " kAudioUnitErr_InvalidElement");
            
        case kAudioUnitErr_NoConnection			:
            print( " kAudioUnitErr_NoConnection");
            
        case kAudioUnitErr_FailedInitialization		:
            print( " kAudioUnitErr_FailedInitialization");
            
        case kAudioUnitErr_TooManyFramesToProcess	:
            print( " kAudioUnitErr_TooManyFramesToProcess");
            
        case kAudioUnitErr_InvalidFile			:
            print( " kAudioUnitErr_InvalidFile");
            
        case kAudioUnitErr_FormatNotSupported		:
            print( " kAudioUnitErr_FormatNotSupported");
            
        case kAudioUnitErr_Uninitialized		:
            print( " kAudioUnitErr_Uninitialized");
            
        case kAudioUnitErr_InvalidScope			:
            print( " kAudioUnitErr_InvalidScope");
            
        case kAudioUnitErr_PropertyNotWritable		:
            print( " kAudioUnitErr_PropertyNotWritable");
            
        case kAudioUnitErr_InvalidPropertyValue		:
            print( " kAudioUnitErr_InvalidPropertyValue");
            
        case kAudioUnitErr_PropertyNotInUse		:
            print( " kAudioUnitErr_PropertyNotInUse");
            
        case kAudioUnitErr_Initialized			:
            print( " kAudioUnitErr_Initialized");
            
        case kAudioUnitErr_InvalidOfflineRender		:
            print( " kAudioUnitErr_InvalidOfflineRender");
            
        case kAudioUnitErr_Unauthorized			:
            print( " kAudioUnitErr_Unauthorized");
            
        default:
            print("Unknown Error")
        }
    }

    func disposeCurrentMusicPlayer() {
        musicPlayerStop()
        if self.musicPlayer != nil {
            DisposeMusicPlayer(self.musicPlayer!)
            self.musicPlayer = nil
        }
     }

    func disposeMusicSequence(_ musicSequence:MusicSequence?) {
        if musicSequence != nil {
            DisposeMusicSequence(musicSequence!)
        }
    }
    
    //MARK: Read write from midi file
    // Parse a midi file into a array of instruments with Notes
    func patternFileToNoteTable(_ fileName:String) -> [Array<Note>]? {
        let fileUrl = MidiFileManager.patternsSharedInstance.getUrlForFile(fileName);
        if loadMidiFileToNewSequencer(fileUrl) {
            return parseMidiEventsFromTracks()
        }
        return nil;
    }

    func loadMidiFileToNewSequencer(_ fileUrl:URL?) -> Bool {
        guard fileUrl != nil else {
            return false
        }
        var sequence:MusicSequence? = nil
        let status = NewMusicSequence(&sequence)
      
        if status == noErr {
            if loadMidiFile(fileUrl, toSequence: sequence!) {
                disposeMusicSequence(self.musicSequence)
                self.musicSequence = sequence
                return true
            }
        }
        return false
    }
    
    func loadMidiFile(_ fileUrl:URL?, toSequence sequence: MusicSequence) -> Bool  {
        let url = fileUrl! as CFURL
        let status = MusicSequenceFileLoad(sequence, url, MusicSequenceFileTypeID.midiType, MusicSequenceLoadFlags());
        if status != noErr {
            handleStatus(status)
            return false
        }
        return true
    }

    func saveSequenceMidiToFileUrl(_ fileUrl:URL?) -> Bool {
        
        guard fileUrl != nil else {
            return false
        }
        let status = MusicSequenceFileCreate(self.musicSequence!, fileUrl! as CFURL, MusicSequenceFileTypeID.midiType, MusicSequenceFileFlags.eraseFile, Int16(480))
        //seqToData(self.musicSequence)
        if status != noErr {
            handleStatus(status)
            return false
        } else {
            return true
        }
    }
    //////////////////////
    func parseMidiEventsFromTracks() -> [Array<Note>] {
        var trackCount:UInt32 = 0
        MusicSequenceGetTrackCount(self.musicSequence!, &trackCount);
        var track:MusicTrack? = nil
        var instrumentList:[Array<Note>] = []
        for _ in PatchManager.sharedManager.patchList {
            instrumentList.append([])
        }
        if trackCount > 0 {
            for index in 0...trackCount-1 {
                MusicSequenceGetIndTrack(self.musicSequence!, index, &track);
                var iterator:MusicEventIterator? = nil
                NewMusicEventIterator(track!, &iterator)
                let tuple = parseTrackForMidiEvents(iterator!)
                if (tuple.1 < 0) {
                    continue
                }
                instrumentList[tuple.1].append(contentsOf: tuple.0)
            }
        }
        return instrumentList
    }
    
    func parseTrackForMidiEvents(_ iterator:MusicEventIterator) -> ([Note], Int){
        var timeStamp:MusicTimeStamp = 0
        var eventType:MusicEventType = 0
        var eventData: UnsafeRawPointer?  = nil
        var eventDataSize:UInt32 = 0
        var hasNext:DarwinBoolean = true
        var index = 0
        var noteArray:[Note] = [];
        
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        while (hasNext).boolValue{
            MusicEventIteratorGetEventInfo(iterator, &timeStamp, &eventType, &eventData, &eventDataSize);
            
            print("event type: \(eventType)")
            switch (eventType){
            case kMusicEventType_MIDINoteMessage:
                let note:Note = Note()
                let data = eventData?.bindMemory(to: MIDINoteMessage.self, capacity: 1)
                //let data = UnsafePointer<MIDINoteMessage>(eventData)
                index = PatchManager.sharedManager.getTrackIndexForPatchValue(Int((data?.pointee.note)!))
                if index < 0 || index >= PatchManager.sharedManager.patchList.count {
                    break;
                }
                if timeStamp > 0 && noteArray.isEmpty {
                    // There are rest in front of the first note, so create a rest
                    let note:Note = Note()
                    note.pitch = 0
                    note.velocity = 0
                    note.beatPosition = Float(0.0)
                    note.endPosition = Float(timeStamp)
                    noteArray.append(note)
                }
                //note.channel = data.memory.channel
                note.pitch = (data?.pointee.note)!
                note.velocity = (data?.pointee.velocity)!
                note.beatPosition = Float(timeStamp)
                note.endPosition = Float(timeStamp) + (data?.pointee.duration)!
                noteArray.append(note)
                break
            case kMusicEventType_MIDIChannelMessage:
                //let data = UnsafePointer<MIDIChannelMessage>(eventData)
            break // TODO
            case kMusicEventType_NULL: break
            case kMusicEventType_ExtendedNote: break
            case kMusicEventType_ExtendedTempo: break
            case kMusicEventType_User: break
            case kMusicEventType_Meta: break
            case kMusicEventType_MIDIRawData: break
            case kMusicEventType_Parameter: break
            case kMusicEventType_AUPreset: break
            default: break
            }
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        return (noteArray, index)
    }

    //MARK: player controll
    func rewind() -> Bool  {
        var timeStamp:MusicTimeStamp = 0
        let status = MusicPlayerGetTime(musicPlayer!, &timeStamp)
        if status == noErr {
            if timeStamp > 1 {
                MusicPlayerSetTime(musicPlayer!, timeStamp - 1)
                updateBarCount(timeStamp - 1)
                return true
            }else {
                MusicPlayerSetTime(musicPlayer!, 0)
                return false
            }
        }
        return false // Error -> Done
    }
    
    func forward() -> Bool  {
        var timeStamp:MusicTimeStamp = 0
        let status = MusicPlayerGetTime(musicPlayer!, &timeStamp)
        if status == noErr {
            if timeStamp < MusicTimeStamp(sequenceDuration) {
                MusicPlayerSetTime(musicPlayer!, timeStamp + 1)
                updateBarCount(timeStamp + 1)
                return true
            }else {
                return false
            }
        }
        return false // Error -> Done

    }
    
    // MARK: callback
    func initMidiInterceptor() {
        
        enableNetwork()
        
        var status = OSStatus(noErr)
        let s:CFString = "MGMidiClient" as CFString
        status = MIDIClientCreate_withBlock(&midiClientRef, s, midiNotifyCallback)
        if status != noErr {
            print("error creating client: \(status)")
            return
        } else {
            print("midi client created \(midiClientRef)")
        }
        
        let portString:CFString = "MGMidiInputPort" as CFString
        status = MIDIInputPortCreate_withBlock(midiClientRef,
                                               portString,
                                               &midiInputPortref,
                                               midiPacketReadCallback)
        if status != noErr {
            print("error creating input port: \(status)")
            return
        } else {
            print("midi input port created \(midiInputPortref)")
        }
        
        let destString:CFString = "MGVirtualDestination" as CFString
        status = MIDIDestinationCreate_withBlock(midiClientRef,
                                                 destString,
                                                 &destEndpointRef,
                                                 midiPacketReadCallback)
        if status != noErr {
            print("error creating virtual destination: \(status)")
        } else {
            print("midi virtual destination created \(destEndpointRef)")
        }
        
        
        connect()
        
    }
    let midiNotifyCallback = { (_ message:UnsafePointer<MIDINotification>?) -> Void in
        print("got a MIDINotification!")
    }
//    func midiNotifyCallback(_ message:UnsafePointer<MIDINotification>) -> Void {
//        print("got a MIDINotification!")
//        
//    }
    
    /*
     Since we have a virtual destination, we need to forward the events to the sampler.
     */
    //TODO: implement the other forarding functions besides noteOn and noteOff.
    func midiPacketReadCallback(_ ts:MIDITimeStamp, dataIn:UnsafePointer<UInt8>?, len:UInt16) {
        
      //  print("ts:\(ts) ")
        
        guard let data = dataIn else { return }
        
        let midiStatus = data[0]
        let rawStatus = data[0] & 0xF0 // without channel
        let channel = midiStatus & 0x0F
        
        switch rawStatus {
            
        case 0x80:
            print("Note off. Channel \(channel) note \(data[1]) velocity \(data[2])")
            // forward to sampler
            // Yes, bad API design. The read proc gives you the data as UInt8s, yet you need a UInt32 to play it with MusicDeviceMIDIEvent
            // playNoteOff(UInt32(channel), noteNum: UInt32(data[1]))
            stopNote(UInt8(data[1]), channel:UInt8(channel))
        case 0x90:
           // print("Note on. Channel \(channel) note \(data[1]) velocity \(data[2])")
            // forward to sampler
            playNote(UInt8(data[1]), velocity:UInt8(data[2]), channel:UInt8(channel))
            //  playNoteOn(UInt32(channel), noteNum:UInt32(data[1]), velocity: UInt32(data[2]))
            
        case 0xA0:
            print("Polyphonic Key Pressure (Aftertouch). Channel \(channel) note \(data[1]) pressure \(data[2])")
            
        case 0xB0:
            print("Control Change. Channel \(channel) controller \(data[1]) value \(data[2])")
            
        case 0xC0:
            print("Program Change. Channel \(channel) program \(data[1])")
            
        case 0xD0:
            print("Channel Pressure (Aftertouch). Channel \(channel) pressure \(data[1])")
            
        case 0xE0:
            print("Pitch Bend Change. Channel \(channel) lsb \(data[1]) msb \(data[2])")
            
        default: print("Unhandled message \(midiStatus)")
        }
        var timeStamp:MusicTimeStamp = 0
        let status = MusicPlayerGetTime(musicPlayer!, &timeStamp)
        if status == noErr && beatPerBar > 0 {
           updateBarCount(timeStamp)
        }
        
    }
    
    func updateBarCount(_ timeStamp: MusicTimeStamp) {
        let mod = Int(timeStamp) % Int(beatPerBar)
        let barCount = Int(timeStamp) / Int(beatPerBar)
        //print("Time = \(timeStamp) \(beatPerBar) mod \(mod) barCount \(barCount)")
        
        if mod == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "PlayBackCount"), object: String(barCount))
        }
    }
    
    func enableNetwork() {
        let session = MIDINetworkSession.default()
        session.isEnabled = true
        session.connectionPolicy = MIDINetworkConnectionPolicy.anyone//MIDINetworkConnectionPolicy_Anyone
        print("net session enabled \(MIDINetworkSession.default().isEnabled)")
    }
    
    /**
     Connect our input port to all midi sources.
     */
    func connect() {
        var status = OSStatus(noErr)
        let sourceCount = MIDIGetNumberOfSources()
        print("source count \(sourceCount)")
        
        for srcIndex in 0 ..< sourceCount {
            _ = MIDIGetSource(srcIndex)
            
            let midiEndPoint = MIDIGetSource(srcIndex)
            status = MIDIPortConnectSource(self.midiInputPortref,
                                           midiEndPoint,
                                           nil)
            if status == OSStatus(noErr) {
                //print("connected source endpoint \(midiEndPoint) to midiInputPortref")
            } else {
                print("Error connecting to source midi port!")
            }
        }
    }

   
}

class MyMetaEvent {
    
    fileprivate var size: Int
    fileprivate var mem : UnsafeMutableRawPointer

    // Data header followed in memory by a sequence of UInt8.
    var metaEventPtr : UnsafeMutablePointer<MIDIMetaEvent>
    
    init(type: UInt32, data: [UInt8]) {

        size = MemoryLayout<MIDIMetaEvent>.size // size = 12 = 4 UInt8 + 1 Uint32 + 4 Bytes of data
        mem = UnsafeMutableRawPointer.allocate(
            byteCount: size * MemoryLayout<UInt8>.stride,
            alignment: MemoryLayout<MIDIMetaEvent>.alignment)
        
        let ptr = mem.bindMemory(to: MIDIMetaEvent.self, capacity: 1)
        let eventData = (mem + 8).bindMemory(to: UInt8.self, capacity: data.count)
        ptr.pointee.metaEventType = UInt8(type)
        ptr.pointee.dataLength = UInt32(data.count)
        for index in 0..<data.count {
            eventData[index] = data[index]
        }
        metaEventPtr = UnsafeMutablePointer(ptr)
    }
    
    //    func init2(type: UInt8, data: [UInt8]) {
//        // Allocate memory of the required size:
//        size = sizeof(MIDIMetaEvent) + data.count
//        mem = UnsafeMutablePointer<UInt8>.alloc(size)
//        // Convert pointer:
//        metaEventPtr = UnsafeMutablePointer(mem)
//        
//        // Fill data:
//        metaEventPtr.memory.metaEventType = type
//        metaEventPtr.memory.dataLength = UInt32(data.count)
//        memcpy(mem + 8, data, Int(data.count))
//    }
    
//    func oldinit(type: UInt32, data: [UInt8]) {
//        // Allocate memory of the required size:
//        size = MemoryLayout<MIDIMetaEvent>.size + data.count
//        mem = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
//        // Convert pointer:
//        metaEventPtr = UnsafeMutablePointer<MIDIMetaEvent>.allocate(capacity: 1)
//        // Fill data:
//        metaEventPtr.pointee.metaEventType = UInt8(type)
//        metaEventPtr.pointee.dataLength = UInt32(data.count)
//        //Separate the 2 pieces data and metaEvent -- HACK
//        memcpy(mem + 8, data, Int(data.count))
//        
//    }
    func getDataAtIndex(_ index: Int) -> UInt8{
        var byte:UInt8 = 0
        memcpy(&byte, mem + 8 + index, 1)
        return byte
    }
    
    deinit {
        // Release the allocated memory:
        mem.deallocate()
        //metaEventPtr.deallocate(capacity: 1)
    }
}
