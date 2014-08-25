//
//  JJFAudioFileWriter.m
//  Playful
//
//  Created by Jackson Firlik on 7/28/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFAudioFileWriter.h"
#import "JJFPlaylistEntry.h"
#import "JJFSessionManager.h"

@interface JJFAudioFileWriter ()

@property (assign, nonatomic) AudioFileStreamID audioFileStreamID;
@property (assign, nonatomic) AudioFileID audioFile;
@property (strong, nonatomic) JJFPlaylistEntry *songEntry;
@property (assign, nonatomic) UInt32 byteOffset;
@property (assign, nonatomic) SInt64 recordPacket;

@property (assign, nonatomic) AudioBufferList bufferList;

- (void)didChangeProperty:(AudioFileStreamPropertyID)propertyID flags:(UInt32 *)flags;
- (void)didReceivePackets:(const void *)packets
       packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions
          numberOfPackets:(UInt32)numberOfPackets
            numberOfBytes:(UInt32)numberOfBytes;

@end

#pragma mark Callbacks

void AudioFileStreamPropertyListener(void *inClientData,
                                     AudioFileStreamID inAudioFileStreamID,
                                     AudioFileStreamPropertyID inPropertyID,
                                     UInt32 *ioFlags)
{
    JJFAudioFileWriter *audioFileWriter = (__bridge JJFAudioFileWriter *)inClientData;
    [audioFileWriter didChangeProperty:inPropertyID flags:ioFlags];
    
}

void AudioFileStreamPacketsListener(void *inClientData,
                                    UInt32 inNumberBytes,
                                    UInt32 inNumberPackets,
                                    const void *inInputData,
                                    AudioStreamPacketDescription *inPacketDescriptions)
{
    JJFAudioFileWriter *audioFileWriter = (__bridge  JJFAudioFileWriter *)inClientData;
    [audioFileWriter didReceivePackets:inInputData packetDescriptions:inPacketDescriptions numberOfPackets:inNumberPackets numberOfBytes:inNumberBytes];
}


@implementation JJFAudioFileWriter


- (instancetype)initWithEntry:(JJFPlaylistEntry *)entry
{
    self = [super init];
    if (self)
    {
        self.songEntry = entry;
        
        OSStatus err = AudioFileStreamOpen((__bridge void *)self,
                                           AudioFileStreamPropertyListener,
                                           AudioFileStreamPacketsListener,
                                           0,
                                           &_audioFileStreamID);
        
        if (err) return nil;

        _byteOffset = 0;
        _recordPacket = 0;
        
        _bufferList.mNumberBuffers = 1;
        
        self.discontinuous = YES;
    }
    
    return self;
}


- (void)didChangeProperty:(AudioFileStreamPropertyID)propertyID flags:(UInt32 *)flags
{
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        UInt32 basicDescriptionSize = sizeof(_basicDescription);
        OSStatus err = AudioFileStreamGetProperty(self.audioFileStreamID,
                                                  kAudioFileStreamProperty_DataFormat,
                                                  &basicDescriptionSize,
                                                  &_basicDescription);
        
        if (err) return;
        
        UInt32 byteCountSize;
        AudioFileStreamGetPropertyInfo(self.audioFileStreamID,
                                       kAudioFileStreamProperty_AudioDataByteCount,
                                       &byteCountSize,
                                       NULL);
        
        AudioFileStreamGetProperty(self.audioFileStreamID,
                                   kAudioFileStreamProperty_AudioDataByteCount,
                                   &byteCountSize,
                                   &_totalByteCount);
        
        UInt32 packetCountSize;
        AudioFileStreamGetPropertyInfo(self.audioFileStreamID,
                                       kAudioFileStreamProperty_AudioDataPacketCount,
                                       &packetCountSize,
                                       NULL);
        
        AudioFileStreamGetProperty(self.audioFileStreamID,
                                   kAudioFileStreamProperty_AudioDataPacketCount,
                                   &packetCountSize,
                                   &_totalPacketCount);
        
        NSLog(@"Total byte count %llu bytes", _totalByteCount);
        NSLog(@"Total packet count %llu packets", _totalPacketCount);
        
        UInt32 sizeOfUInt32 = sizeof(UInt32);
        err = AudioFileStreamGetProperty(self.audioFileStreamID,
                                         kAudioFileStreamProperty_PacketSizeUpperBound,
                                         &sizeOfUInt32,
                                         &_packetBufferSize);
        
        if (err || !self.packetBufferSize) {
            AudioFileStreamGetProperty(self.audioFileStreamID,
                                       kAudioFileStreamProperty_MaximumPacketSize,
                                       &sizeOfUInt32,
                                       &_packetBufferSize);
        }
        
        Boolean writeable;
        err = AudioFileStreamGetPropertyInfo(self.audioFileStreamID,
                                             kAudioFileStreamProperty_MagicCookieData,
                                             &_magicCookieLength,
                                             &writeable);
        
        if (!err) {
            self.magicCookieData = calloc(1, self.magicCookieLength);
            AudioFileStreamGetProperty(self.audioFileStreamID,
                                       kAudioFileStreamProperty_MagicCookieData,
                                       &_magicCookieLength,
                                       _magicCookieData);
            
            
        }
        
        
        // Create AudioFile of same type as AudioFileStream
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *soundFile = [self.songEntry.uuid.UUIDString stringByAppendingString:@".caf"];
        NSString *soundFilePath = [docsDir stringByAppendingPathComponent:soundFile];
        
        CFURLRef songURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                         (CFStringRef)soundFilePath,
                                                         kCFURLPOSIXPathStyle,
                                                         false);
        
        [[[JJFSessionManager sharedManager] sharedPlaylist] updateLocalURL:(__bridge NSURL *)songURL forEntry:self.songEntry];
        
        UInt32 format4cc = CFSwapInt32HostToBig(_basicDescription.mFormatID);
        
        NSLog(@"mFormatID: %4.4s, mFormatFlags: %d, mFramesPerPacket: %d",
              (char*)&format4cc,
              _basicDescription.mFormatFlags,
              _basicDescription.mFramesPerPacket);
        
        AudioFileCreateWithURL(songURL,
                               kAudioFileCAFType,
                               &_basicDescription,
                               kAudioFileFlags_EraseFile,
                               &_audioFile);
        
        
        AudioFileSetProperty(_audioFile,
                             kAudioFilePropertyMagicCookieData,
                             sizeof(_magicCookieData),
                             &_magicCookieData);
        
        AudioFileSetProperty(_audioFile,
                             kAudioFilePropertyAudioDataByteCount,
                             sizeof(UInt32),
                             &_totalByteCount);
        
        
        CFRelease(songURL);
        
    }
}

- (void)didReceivePackets:(const void *)packets
       packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions
          numberOfPackets:(UInt32)numberOfPackets
            numberOfBytes:(UInt32)numberOfBytes
{
    //NSLog(@"Received %d packets, %d bytes", numberOfPackets, numberOfBytes);

    if (packetDescriptions) {
        for (NSUInteger i = 0; i < numberOfPackets; i++) {
            
            OSStatus err = AudioFileWritePackets(_audioFile,
                                                 false,
                                                 numberOfBytes,
                                                 packetDescriptions,
                                                 _recordPacket,
                                                 &numberOfPackets,
                                                 packets);
    
            if (err != noErr){
                [self error:err];
            }
            
            _recordPacket += numberOfPackets;
        }
    }
    
    else {
        
        OSStatus err = AudioFileWriteBytes(_audioFile,
                                           false,
                                           _byteOffset,
                                           &numberOfBytes,
                                           packets);
        if (err != noErr){
            [self error:err];
        }
        
        _byteOffset += numberOfBytes;

    }
}

- (void)error:(OSStatus)error
{
    switch (error) {
        case kExtAudioFileError_NonPCMClientFormat:
            NSLog(@"NonPCMClientFormat");
            break;
            
        case kExtAudioFileError_MaxPacketSizeUnknown:
            NSLog(@"MaxPacketSizeUnknown");
            break;
            
        case kExtAudioFileError_InvalidDataFormat:
            NSLog(@"InvalidDataFormat");
            break;
        
        case kExtAudioFileError_AsyncWriteBufferOverflow:
            NSLog(@"WriteBufferOverflow");
            break;
            
        case kExtAudioFileError_AsyncWriteTooLarge:
            NSLog(@"WriteTooLarge");
            break;
            
        case kExtAudioFileError_CodecUnavailableInputConsumed:
            NSLog(@"CodecUnavailableInputConsumed");
            break;
            
        case kExtAudioFileError_CodecUnavailableInputNotConsumed:
            NSLog(@"CodecUnavailableInputNotConsumed");
            break;
            
        default:
            NSLog(@"someOtherError %d", error);
            break;
    }
}

- (void)parseData:(const void *)data
           length:(UInt32)length
{
    OSStatus err;
    
    if (self.discontinuous) {
        err = AudioFileStreamParseBytes(self.audioFileStreamID,
                                        length,
                                        data,
                                        kAudioFileStreamParseFlag_Discontinuity);
        self.discontinuous = NO;
    } else {
        err = AudioFileStreamParseBytes(self.audioFileStreamID,
                                        length,
                                        data,
                                        0);
    }
    
    //*******//
    if (err != noErr)
    {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        NSLog(@"%@", error.description);
        exit(-1);
    }
}

- (void)closeFile
{
    AudioFileClose(_audioFile);
    NSLog(@"AudioFile Closed");
    
    NSDictionary *dict = @{@"entry": self.songEntry};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"entryReadyForQueue" object:self userInfo:dict];
    

    
}
- (void)dealloc
{
    AudioFileStreamClose(self.audioFileStreamID);
    free(_magicCookieData);
}
@end
