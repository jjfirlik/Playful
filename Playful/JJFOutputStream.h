//
//  JJFOutputStream.h
//  Playful
//
//  Created by Jackson Firlik on 7/28/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JJFPlaylistEntry.h"

@protocol JJFOutputStreamDelegate

@optional
- (void)outputStreamEndedForEntry:(JJFPlaylistEntry *)entry;

@end

@interface JJFOutputStream : NSObject


@property (nonatomic, strong) id<JJFOutputStreamDelegate> delegate;

- (instancetype)initWithOutputStream:(NSOutputStream *)stream;
- (instancetype)initWithOutputStream:(NSOutputStream *)stream andEntry:(JJFPlaylistEntry *)entry;


- (void)streamAudioFromURL:(NSURL *)url;
- (void)start;
- (void)stop;

@end
