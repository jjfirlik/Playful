//
//  JJFSessionManager.h
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/7/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "JJFSharedPlaylist.h"
#import "JJFInputStream.h"
@class JJFOutputStream;

@interface JJFSessionManager : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, JJFInputStreamDelegate>

+ (instancetype)sharedManager;

@property (nonatomic, strong) MCPeerID *host;
- (BOOL)isHost;

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, assign) NSInteger peerCount;

@property (nonatomic, strong) MCSession *session;

- (void)browseForPeers:(BOOL)shouldBrowse;
- (void)addPeer:(MCPeerID *)peer;
- (void)removePeer:(MCPeerID *)peer;
- (void)inviteAllPeers;

- (void)advertiseSelf:(BOOL)shouldAdvertise;

- (void)setupSessionWithDisplayName:(NSString *)displayName;
- (void)setupSession;
- (void)resetSession;


@end
