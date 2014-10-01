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
#import "JJFAudioFileConverter.h"

@interface JJFSessionManager ()

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;

@property (nonatomic, strong) NSMutableArray *peersFound;

@property (strong, nonatomic) JJFInputStream *inputStream;
@property (strong, nonatomic) JJFOutputStream *outputStream;

@end

@implementation JJFSessionManager

+ (instancetype)sharedManager
{
    static JJFSessionManager *sharedManager = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        sharedManager = [[self alloc] initPrivate];
    });
    
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

#pragma mark - Session


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
    NSDictionary *dict = @{@"peer": peerID};

    if (state != MCSessionStateConnecting) {
        if (state == MCSessionStateConnected) {
            NSLog(@"peer %@ joined session", peerID.displayName);
            
            if ([self isHost]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"peerJoinedSession" object:self
                userInfo:dict];
            }
            
        }
        
        else if (state == MCSessionStateNotConnected) {
            NSLog(@"peer %@ left session", peerID.displayName);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"peerLeftSession" object:self
                                                              userInfo:dict];
        }
    }
}

// Handle SharedPlaylist Data Sharing
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    // Peer receives entire playlist from host
    if ([[dict objectForKey:@"type"] isEqualToString:@"playlist"]) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedPlaylistFromHost" object:self userInfo:dict];

    }
    
    // Host receives single entry, then sends entire playlist
    // (Maintains synchronization between all peers in case of lag)
    if ([[dict objectForKey:@"type"] isEqualToString:@"entry"]) {

        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedEntryFromPeer" object:self userInfo:dict];
        
    }
}

// Handle I/O streams
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

// Handle Resources
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSDictionary *dict = @{@"resourceName":resourceName,
                           @"peer":peerID,
                           @"progress":progress};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startedReceivingResource" object:self.session userInfo:dict];
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    if (error)
    {
        //Handle the error
        return;
    }
    
    NSDictionary *dict = @{@"resourceName":resourceName,
                           @"peer":peerID,
                           @"URL":localURL};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"finishedReceivingResource" object:self.session userInfo:dict];
}


@end
