//
//  JJFSharedPlaylist.h
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/9/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "JJFPlaylistEntry.h"

@interface JJFSharedPlaylist : NSObject <NSCoding>

@property (nonatomic, strong) NSArray *playlist;

- (void)addEntryWithSong:(MPMediaItem *)song andPeerID:(MCPeerID *)peerID;
- (void)addEntry:(JJFPlaylistEntry *)entry;
- (void)removeTop;

- (void)updateLocalURL:(NSURL *)url forEntry:(JJFPlaylistEntry *)entry;

- (JJFPlaylistEntry *)entryForUUID:(NSUUID *)uuid;

@end
