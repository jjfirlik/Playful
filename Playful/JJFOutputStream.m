//
//  JJFOutputStream.m
//  Playful
//
//  Created by Jackson Firlik on 7/28/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFOutputStream.h"

#import <AVFoundation/AVFoundation.h>


@interface JJFOutputStream () <NSStreamDelegate>

@property (strong, nonatomic) NSStream *audioStream;
@property (strong, nonatomic) JJFPlaylistEntry *entry;
@property (strong, nonatomic) AVAssetReader *assetReader;
@property (strong, nonatomic) AVAssetReaderTrackOutput *assetOutput;
@property (strong, nonatomic) NSThread *streamThread;

@property (assign, atomic) BOOL isStreaming;

@end

@implementation JJFOutputStream

- (instancetype)init
{
    self = [self initWithOutputStream:nil andEntry:nil];
    return self;
    
}

- (instancetype)initWithOutputStream:(NSOutputStream *)stream
{

    self = [self initWithOutputStream:stream andEntry:nil];
    return self;
    
}

- (instancetype)initWithOutputStream:(NSOutputStream *)stream andEntry:(JJFPlaylistEntry *)entry
{
    self = [super init];
    if (self)
    {
        self.audioStream = stream;
        self.entry = entry;
    }
    
    return self;
    
}

- (void)start
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    }
    
    self.streamThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [self.streamThread start];
}

- (void)run
{
    @autoreleasepool {
        self.audioStream.delegate = self;
        [self.audioStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.audioStream open];
        
        self.isStreaming = YES;
        
        while (self.isStreaming && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    }
}

- (void)streamAudioFromURL:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSError *assetError;
    
    self.assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    
    //NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, nil];

    self.assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:asset.tracks[0] outputSettings:nil];

    
    if (![self.assetReader canAddOutput:self.assetOutput]) return;
    
    [self.assetReader addOutput:self.assetOutput];
    [self.assetReader startReading];
    
}

- (void)sendDataChunk
{
    
    CMSampleBufferRef sampleBuffer;
    
    sampleBuffer = [self.assetOutput copyNextSampleBuffer];

    if (sampleBuffer == NULL || CMSampleBufferGetNumSamples(sampleBuffer) == 0) {
        CFRelease(sampleBuffer);
        [self stop];
        return;
    }
    
    CMBlockBufferRef blockBuffer;
    AudioBufferList audioBufferList;
    
    OSStatus err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    CMItemCount count = CMSampleBufferGetNumSamples(sampleBuffer);
    
    NSLog(@"***SENT %ld SAMPLES***", count);
    
    if (err) {
        CFRelease(sampleBuffer);
        return;
    }
    
    
    for (NSUInteger i = 0; i < audioBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
        
        [(NSOutputStream *)self.audioStream write:audioBuffer.mData maxLength:audioBuffer.mDataByteSize];
    }
    
    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
    
}

- (void)stop
{
    [self performSelector:@selector(stopThread) onThread:self.streamThread withObject:nil waitUntilDone:YES];
}

- (void)stopThread
{    
    self.isStreaming = NO;
    [self.audioStream close];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            [self sendDataChunk];
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Stream error");
            break;
        
        case NSStreamEventEndEncountered:
            NSLog(@"Output Stream ended");
            [self stop];
            break;
            
        default:
            break;
    }
    
}

@end
