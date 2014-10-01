//
//  JJFPlaylistPlayer.h
//  Playful
//
//  Created by Jackson Firlik on 8/1/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "JJFSharedPlaylist.h"

@interface JJFPlaylistPlayer : NSObject

- (void)addEntry:(JJFPlaylistEntry *)entry;

- (void)play;
- (void)pause;
- (void)next;

@property (nonatomic, assign) BOOL isPlaying;

@end
