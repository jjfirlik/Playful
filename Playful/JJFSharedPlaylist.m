//
//  JJFSharedPlaylist.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/9/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFSharedPlaylist.h"
#import "JJFAppDelegate.h"
#import "JJFSessionManager.h"

@interface JJFSharedPlaylist ()

@property (nonatomic, strong) NSMutableArray *privatePlaylist;
@property (weak, nonatomic) JJFSessionManager *sessionManager;

@end

@implementation JJFSharedPlaylist

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.privatePlaylist = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    
    self = [super init];
    if (self) {
        self.privatePlaylist = [aDecoder decodeObjectForKey:@"privatePlaylist"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.privatePlaylist forKey:@"privatePlaylist"];
}

- (JJFSessionManager *)sessionManager
{
    return [JJFSessionManager sharedManager];
}

- (NSArray *)playlist
{
    return self.privatePlaylist;
}

- (void)setPlaylist:(NSArray *)playlist
{
    self.privatePlaylist = [NSMutableArray arrayWithArray:playlist];
}

- (void)addEntryWithSong:(MPMediaItem *)song andPeerID:(MCPeerID *)peerID
{
    JJFPlaylistEntry *entry = [[JJFPlaylistEntry alloc] initWithMediaItem:song andPeerID:peerID];
    
    [self addEntry:entry];
}

- (void)addEntry:(JJFPlaylistEntry *)entry
{
    [self.privatePlaylist addObject:entry];
}

- (void)removeTop
{
    [self.privatePlaylist removeObjectAtIndex:0];
}

- (void)updateLocalURL:(NSURL *)url forEntry:(JJFPlaylistEntry *)entry
{
    JJFPlaylistEntry *localEntry = [self.privatePlaylist objectAtIndex:[self.privatePlaylist indexOfObjectIdenticalTo:entry]];
    localEntry.songURL = url;
    
    NSLog(@"%@\n%@",localEntry.songTitle, localEntry.songURL);
}

- (JJFPlaylistEntry *)entryForUUID:(NSUUID *)uuid
{
    JJFPlaylistEntry *entry;
    
    for (JJFPlaylistEntry *item in self.privatePlaylist)
    {
        if ([item.uuid isEqual:uuid])
            entry = item;
    }
    
    return entry;
}

@end
