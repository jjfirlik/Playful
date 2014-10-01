//
//  JJFAudioFileConverter.h
//  Playful
//
//  Created by Jackson Firlik on 9/6/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
@class JJFPlaylistEntry;

@protocol JJFAudioFileConverterDelegate <NSObject>

- (void)sendConvertedEntry:(JJFPlaylistEntry *)entry atURL:(NSURL *)filePath;

@end

@interface JJFAudioFileConverter : NSObject

@property (nonatomic, strong) id<JJFAudioFileConverterDelegate>delegate;

- (instancetype)initWithPlaylistEntry:(JJFPlaylistEntry *)entry;
- (void)convertWithFileName:(NSString *)name;

@property (nonatomic, strong) NSURL *outputFilePath;

@end
