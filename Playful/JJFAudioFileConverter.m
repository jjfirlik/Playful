//
//  JJFAudioFileConverter.m
//  Playful
//
//  Created by Jackson Firlik on 9/6/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFAudioFileConverter.h"
#import <AVFoundation/AVFoundation.h>
#import "JJFPlaylistEntry.h"
#import "JJFSessionManager.h"

@interface JJFAudioFileConverter ()

@property (nonatomic, strong) JJFPlaylistEntry *entry;
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, strong) AVAssetReaderOutput *assetReaderOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;

@property (nonatomic, strong) dispatch_queue_t serializationQueue;

@property (nonatomic, strong) NSURL *documentsDirectory;

@property (nonatomic, assign) BOOL cancelled;


@end

@implementation JJFAudioFileConverter

- (instancetype)initWithPlaylistEntry:(JJFPlaylistEntry *)entry
{
    if (self = [super init]){
        // Create the AVAsset
        self.entry = entry;
        self.asset = [AVAsset assetWithURL:entry.songURL];
    };
    
    return self;
}

- (NSURL *)documentsDirectory
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSURL *directory = [[NSURL alloc] initFileURLWithPath:docsDir isDirectory:YES];
    return directory;
}

- (BOOL)setupAssetReaderAndAssetWriter:(NSError **)outError
{
    // Create and initialize the asset reader.
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:outError];
    BOOL success = (self.assetReader != nil);
    if (success)
    {
        // If the asset reader was successfully initialized, do the same for the asset writer.
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputFilePath fileType:AVFileTypeCoreAudioFormat error:outError];
        success = (self.assetWriter != nil);
    }
    
    if (success)
    {
        // If the reader and writer were successfully initialized, grab the audio and video asset tracks that will be used.
        AVAssetTrack *assetAudioTrack = nil;
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0)
            assetAudioTrack = [audioTracks objectAtIndex:0];
        
        if (assetAudioTrack)
        {
            // If there is an audio track to read, set the decompression settings to Linear PCM and create the asset reader output.
            NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
            self.assetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
            [self.assetReader addOutput:self.assetReaderOutput];
            // Then, set the compression settings to 128kbps AAC and create the asset writer input.
            AudioChannelLayout stereoChannelLayout = {
                .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                .mChannelBitmap = 0,
                .mNumberChannelDescriptions = 0
            };
            
            NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
            NSDictionary *compressionAudioSettings = @{
                                                       AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                                                       AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
                                                       AVSampleRateKey       : [NSNumber numberWithInteger:44100],
                                                       AVChannelLayoutKey    : channelLayoutAsData,
                                                       AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
                                                       };
            self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetAudioTrack mediaType] outputSettings:compressionAudioSettings];
            [self.assetWriter addInput:self.assetWriterInput];
        }
    }
    return success;
    
}

- (void)convertWithFileName:(NSString *)name
{
    self.outputFilePath = [[self.documentsDirectory URLByAppendingPathComponent:name] URLByAppendingPathExtension:@"caf"];
    
    NSError *err;
    
    
    [self setupAssetReaderAndAssetWriter:&err];
    
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
    
    // Create a serialization queue for reading and writing.
    self.serializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    
    [self.assetReader startReading];
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    // Specify the block to execute when the asset writer is ready for media data and the queue to call it on.
    [self.assetWriterInput requestMediaDataWhenReadyOnQueue:self.serializationQueue usingBlock:^{
        while ([self.assetWriterInput isReadyForMoreMediaData])
        {
            // Get the asset reader output's next sample buffer.
            CMSampleBufferRef sampleBuffer = [self.assetReaderOutput copyNextSampleBuffer];
            if (sampleBuffer != NULL)
            {
                // If it exists, append this sample buffer to the output file.
                BOOL success = [self.assetWriterInput appendSampleBuffer:sampleBuffer];
                CFRelease(sampleBuffer);
                sampleBuffer = NULL;
                // Check for errors that may have occurred when appending the new sample buffer.
                if (!success && self.assetWriter.status == AVAssetWriterStatusFailed)
                {
                    //NSError *failureError = self.assetWriter.error;
                    //Handle the error.
                }
            }
            else
            {
                // If the next sample buffer doesn't exist, find out why the asset reader output couldn't vend another one.
                if (self.assetReader.status == AVAssetReaderStatusFailed)
                {
                    //NSError *failureError = self.assetReader.error;
                    //Handle the error here.
                }
                else
                {
                    // The asset reader output must have vended all of its samples. Mark the input as finished.
                    [self.assetWriterInput markAsFinished];
                    NSLog(@"Asset Writer Finished, Fuck Yez.");
                    [self.delegate sendConvertedEntry:self.entry atURL:self.outputFilePath];
                    break;
                }
            }
        }
    }];

    
}

@end
