//
//  JJFPlaylistEntry.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/10/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFPlaylistEntry.h"

@implementation JJFPlaylistEntry

- (instancetype)initWithMediaItem:(MPMediaItem *)item andPeerID:(MCPeerID *)peerID
{
    self = [super init];
    
    if (self) {
        self.artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        self.songTitle = [item valueForProperty:MPMediaItemPropertyTitle];
        
        MPMediaItemArtwork *art = [item valueForProperty:MPMediaItemPropertyArtwork];
        self.albumImage = [art imageWithSize:CGSizeMake(50.0, 50.0)];
        
        //**Will have to change this to reflect local vs. streamed file**//
        self.songURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        self.peerID = peerID;
        
        self.uuid = [NSUUID UUID];
        
        self.isStreaming = NO;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self) {
        self.artistName = [aDecoder decodeObjectForKey:@"artistName"];
        self.songTitle = [aDecoder decodeObjectForKey:@"songTitle"];
        self.albumImage = [aDecoder decodeObjectForKey:@"albumImage"];
        
        self.songURL = [aDecoder decodeObjectForKey:@"songURL"];
        self.peerID = [aDecoder decodeObjectForKey:@"peerID"];
        self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        
        self.isStreaming = [[aDecoder decodeObjectForKey:@"isStreaming"] boolValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.artistName forKey:@"artistName"];
    [aCoder encodeObject:self.songTitle forKey:@"songTitle"];
    [aCoder encodeObject:self.albumImage forKey:@"albumImage"];
    [aCoder encodeObject:self.songURL forKey:@"songURL"];
    [aCoder encodeObject:self.peerID forKey:@"peerID"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isStreaming] forKey:@"isStreaming"];
}

@end
