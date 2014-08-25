//
//  JJFAudioFileWriter.h
//  Playful
//
//  Created by Jackson Firlik on 7/28/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
@class JJFPlaylistEntry;

@interface JJFAudioFileWriter : NSObject


@property (assign, nonatomic) AudioStreamBasicDescription basicDescription;
@property (assign, nonatomic) UInt64 totalByteCount;
@property (assign, nonatomic) UInt64 totalPacketCount;
@property (assign, nonatomic) UInt32 packetBufferSize;
@property (assign, nonatomic) void *magicCookieData;
@property (assign, nonatomic) UInt32 magicCookieLength;
@property (assign, nonatomic) BOOL discontinuous;

- (instancetype)initWithEntry:(JJFPlaylistEntry *)entry;

- (void)parseData:(const void *)data length:(UInt32)length;

- (void)closeFile;


@end
