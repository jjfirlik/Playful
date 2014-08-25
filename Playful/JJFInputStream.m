//
//  JJFInputStream.m
//  Playful
//
//  Created by Jackson Firlik on 7/28/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFInputStream.h"
#import "JJFAudioFileWriter.h"
#import "JJFSessionManager.h"
#import "JJFPlaylistEntry.h"

@interface JJFInputStream () <NSStreamDelegate>

@property (strong, nonatomic) NSThread *audioStreamerThread;
@property (assign, atomic) BOOL isPlaying;

@property (strong, nonatomic) JJFAudioFileWriter *audioFileWriter;
@property (weak, nonatomic) JJFPlaylistEntry *entry;

@property (strong, nonatomic) NSStream *audioStream;

@end

@implementation JJFInputStream


- (instancetype)initWithInputStream:(NSInputStream *)inputStream
{
    return [self initWithInputStream:inputStream andEntry:nil];
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream andEntry:(JJFPlaylistEntry *)entry
{
    self = [self init];
    if (self)
    {
        self.audioStream = inputStream;
        self.entry = entry;
        self.audioFileWriter = [[JJFAudioFileWriter alloc] initWithEntry:self.entry];
    }
    
    return self;
}

- (void)start
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    }
    
    self.audioStreamerThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [self.audioStreamerThread start];
}

- (void)run
{
    @autoreleasepool {
        self.audioStream.delegate = self;
        [self.audioStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.audioStream open];
        
        self.isPlaying = YES;
        
        while (self.isPlaying && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t buffer[512];
            NSInteger length = [(NSInputStream *)aStream read:buffer maxLength:512];
            [self.audioFileWriter parseData:buffer length:(UInt32)length];
            break;
        }
            
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Stream error");
            break;
        }
            
        case NSStreamEventEndEncountered:
        {
            NSLog(@"Stream Ended");
            [self.audioFileWriter closeFile];
            [self close];
        }
            
        default:
            break;
    }
}

- (void)close
{
    [self.audioStream close];
    self.audioStream.delegate = nil;
    [self.audioStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

@end
