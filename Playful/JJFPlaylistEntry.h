//
//  JJFPlaylistEntry.h
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/10/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface JJFPlaylistEntry : NSObject <NSCoding>


- (instancetype)initWithMediaItem:(MPMediaItem *)item andPeerID:(MCPeerID *)peerID;

@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) UIImage *albumImage;
@property (nonatomic, strong) NSString *songTitle;
@property (nonatomic, strong) NSURL *songURL;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) NSUUID *uuid;

@property (nonatomic, assign) BOOL isStreaming;


@end
