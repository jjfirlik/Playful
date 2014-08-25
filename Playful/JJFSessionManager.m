//
//  JJFSessionManager.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/7/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFSessionManager.h"
#import "JJFCreateViewController.h"
#import "JJFJoinViewController.h"
#import "JJFOutputStream.h"
#import "JJFInputStream.h"

@interface JJFSessionManager ()

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCSession *session;

@property (nonatomic, strong) MCPeerID *host;
@property (nonatomic, strong) NSMutableArray *peersFound;

@property (strong, nonatomic) JJFInputStream *inputStream;
@property (strong, nonatomic) JJFOutputStream *outputStream;

@end

@implementation JJFSessionManager

+ (instancetype)sharedManager
{
    static JJFSessionManager *sharedManager = nil;
    
    if (!sharedManager) {
        sharedManager = [[self alloc] initPrivate];
    }
    
    return sharedManager;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.peerCount = 0;
        self.advertiser = nil;
        self.browser = nil;
        self.session = nil;
        self.peerID = nil;
        self.peersFound = nil;
        
        self.sharedPlaylist = [[JJFSharedPlaylist alloc] init];

    }
    return self;
}

#pragma mark - Advertiser

- (void)advertiseSelf:(BOOL)shouldAdvertise
{
    if (shouldAdvertise)
    {
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:@"jjf-musicshare"];
        self.advertiser.delegate = self;
        [self.advertiser startAdvertisingPeer];
    }
    
    else
    {
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    
    self.host = peerID;
    
    NSDictionary *dict = @{@"peerID": peerID};
    
    NSLog(@"%@'s advertiser was invited to %@'s session", self.peerID.displayName, peerID.displayName);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedInvitation" object:self userInfo:dict];
    
    invitationHandler(YES, self.session);
}

#pragma mark - Browser

- (void)browseForPeers:(BOOL)shouldBrowse
{
    if (shouldBrowse)
    {
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:@"jjf-musicshare"];
        self.browser.delegate = self;
        [self.browser startBrowsingForPeers];
    }
    
    else {
        [self.browser stopBrowsingForPeers];
        self.browser = nil;
    }
    
    self.host = self.peerID;
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    [self addPeer:peerID];
    
    [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:30];
    
    NSDictionary *dict = @{@"peers": self.peersFound};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"peerFoundOrLost" object:self userInfo:dict];
    
    NSLog(@"browser found peer %@", peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [self removePeer:peerID];
    
    NSDictionary *dict = @{@"peers": self.peersFound};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"peerFoundOrLost" object:self userInfo:dict];
    
    NSLog(@"browser lost peer %@", peerID.displayName);
}

- (void)addPeer:(MCPeerID *)peer
{
    [self.peersFound addObject:peer];
}

- (void)removePeer:(MCPeerID *)peer
{
    [self.peersFound removeObject:peer];
}

- (void)inviteAllPeers
{
    for (MCPeerID *peer in self.peersFound) {
        [self.browser invitePeer:peer toSession:self.session withContext:nil timeout:30];
    }
    
}

- (NSInteger)peerCount
{
    return [[self.session connectedPeers] count];
}

#pragma mark - Session Lifecycle


- (void)setupSessionWithDisplayName:(NSString *)displayName
{
    self.peerCount = 0;
    self.displayName = displayName;
    self.peersFound = [NSMutableArray array];
    self.peerID = [[MCPeerID alloc] initWithDisplayName:self.displayName];
    
    self.session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
}

- (void)setupSession
{
    [self setupSessionWithDisplayName:[UIDevice currentDevice].name];
}

- (void)resetSession
{
    [self browseForPeers:NO];
    [self advertiseSelf:NO];
    
    [[self session] disconnect];
    self.peersFound = [NSMutableArray array];
}

- (BOOL)isHost
{
    if ([self.peerID isEqual:self.host])
        return true;
    else
        return false;
}

#pragma mark - Session Delegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected) {
            NSLog(@"peer %@ joined session", peerID.displayName);
            
            if ([self isHost])
            [self sendUpdatedPlaylist];
        }
        else if (state == MCSessionStateNotConnected){
            NSLog(@"peer %@ left session", peerID.displayName);
        }
    }
    
    NSNumber *stateNumber = [NSNumber numberWithInt:state];
    
    NSDictionary *dict = @{@"peerID": peerID,
                           @"state": stateNumber};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"peerChangedState" object:self userInfo:dict];
}

// Handle SharedPlaylist Data Sharing
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    // Peer receives entire playlist from host
    if ([[dict objectForKey:@"type"] isEqualToString:@"playlist"])
    {
        NSArray *playlistArray = [dict objectForKey:@"playlist"];
        [self.sharedPlaylist setPlaylist:playlistArray];
        NSLog(@"RECEIVED ENTIRE PLAYLIST");
    }
    
    // Host receives single entry, then sends entire playlist
    if ([[dict objectForKey:@"type"] isEqualToString:@"entry"])
    {
        JJFPlaylistEntry *entry = [dict objectForKey:@"entry"];
        [self.sharedPlaylist addEntry:entry];
        [self sendUpdatedPlaylist];
        NSLog(@"RECEIVED SINGLE ENTRY");
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedData" object:self];
}

// Handle I/O streams
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:streamName];
    JJFPlaylistEntry *entry = [self.sharedPlaylist entryForUUID:uuid];

    [self handleInputStream:stream fromPeer:peerID withEntry:entry];
    
    NSLog(@"%@ did receive stream", self.peerID.displayName);
    
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{}


#pragma mark - Stream Handling
- (void)handleInputStream:(NSInputStream *)stream fromPeer:(MCPeerID *)peerID withEntry:(JJFPlaylistEntry *)entry
{
    self.inputStream = [[JJFInputStream alloc] initWithInputStream:stream andEntry:entry];
    self.inputStream.delegate = self;
    [self.inputStream start];
}

- (JJFOutputStream *)outputStreamForPeer:(MCPeerID *)peer withEntry:(JJFPlaylistEntry *)entry
{
    NSError *error;
    
    NSOutputStream *stream = [self.session startStreamWithName:entry.uuid.UUIDString toPeer:peer error:&error];
    JJFOutputStream *outputStream = [[JJFOutputStream alloc] initWithOutputStream:stream andEntry:entry];
    
    if (error) {
        NSLog(@"Error: %@", [error userInfo].description);
    }
    
    return outputStream;
    
}

- (void)streamSongWithEntry:(JJFPlaylistEntry *)entry
{
    NSURL *songURL = [entry songURL];
    
    if (!songURL)
    {
        NSLog(@"Not a valid URL, can't be iCloud media");
        return;
    }
    
    [self sendEntry:entry];
    
    self.outputStream = [self outputStreamForPeer:self.host withEntry:entry];
    
    [self.outputStream streamAudioFromURL:songURL];
    [self.outputStream start];
    
    NSString *songName = [entry songTitle];
    NSString *hostName = [self.host displayName];
    
    NSLog(@"Sending %@ to %@", songName, hostName);
}

- (void)inputStreamEndedForEntry:(JJFPlaylistEntry *)entry
{
    entry.isStreaming = NO;
        
    [self sendUpdatedPlaylist];
    
}

#pragma mark - Playlist Functions

- (void)handleEntry:(JJFPlaylistEntry *)entry
{
    //If host, add song immediately to playlist & queue, send playlist
    if ([self isHost])
    {
        [self.sharedPlaylist addEntry:entry];
        [self sendUpdatedPlaylist];
        
        NSDictionary *dict = @{@"entry": entry};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"entryReadyForQueue" object:self userInfo:dict];
    }
    
    
    //If peer, send entry then stream song
    else
    {
        entry.isStreaming = YES;
        [self.sharedPlaylist addEntry:entry];
        [self streamSongWithEntry:entry];
        
    }
}

- (void)removeTop
{
    [self.sharedPlaylist removeTop];
    [self sendUpdatedPlaylist];
}

- (void)sendUpdatedPlaylist
{
    
    NSDictionary *dict = @{@"type": @"playlist",
                           @"playlist": self.sharedPlaylist.playlist};
    
    NSData *playlistData = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    NSArray *allPeers = [self.session connectedPeers];
    
    [self.session sendData:playlistData toPeers:allPeers withMode:MCSessionSendDataReliable error:nil];
    
}

- (void)sendEntry:(JJFPlaylistEntry *)entry
{
    NSDictionary *dict = @{@"type": @"entry",
                           @"entry": entry};
    
    NSData *entryData = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    NSArray *hostArray = [NSArray arrayWithObject:self.host];
    
    [self.session sendData:entryData toPeers:hostArray withMode:MCSessionSendDataReliable error:nil];
}




@end
