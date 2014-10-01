//
//  JJFSharingController.h
//  Playful
//
//  Created by Jackson Firlik on 9/23/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JJFAudioFileConverter.h"
@class JJFPlaylistEntry;
@class JJFSharedPlaylist;

@interface JJFSharingController : NSObject <JJFAudioFileConverterDelegate>

@property (nonatomic, strong) JJFSharedPlaylist *sharedPlaylist;
- (void)handleEntry:(JJFPlaylistEntry *)entry;

- (void)removePlaylistTop;
- (void)sendUpdatedPlaylist;

@end
