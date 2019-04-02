//
//  MidiNoteUserCallback.h
//  MetroGroove
//
//  Created by Thinh Nguyen on 5/2/16.
//  Copyright © 2016 Prospertin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface MidiNoteUserCallback : NSObject

typedef void (^OnNoteCallback)(MusicTimeStamp timeStamp);

+ (void (*)(void *inClientData, MusicSequence inSequence, MusicTrack inTrack,
            MusicTimeStamp inEventTime, const MusicEventUserData *inEventData,
            MusicTimeStamp inStartSliceBeat, MusicTimeStamp inEndSliceBeat)) midiNoteUser;

+ (void)setNoteOnCallback:(OnNoteCallback)onCallback;

@end

OSStatus MIDIClientCreate_withBlock(MIDIClientRef *outClient, CFStringRef name, void (^notifyRefCon)(const MIDINotification *message));

OSStatus MIDIInputPortCreate_withBlock(MIDIClientRef midiClient, CFStringRef name, MIDIPortRef* outport, void (^readRefCon)(const MIDITimeStamp ts, const UInt8 *datum, const UInt16 len));

OSStatus MIDIDestinationCreate_withBlock(MIDIClientRef midiClient, CFStringRef name, MIDIEndpointRef* virtualDestination, void (^readRefCon)(const MIDITimeStamp ts, const UInt8 *data, const UInt16 len));

