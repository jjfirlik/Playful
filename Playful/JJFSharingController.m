//
//  JJFSharingController.m
//  Playful
//
//  Created by Jackson Firlik on 9/23/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFSharingController.h"
#import "JJFSessionManager.h"
#import "JJFSharedPlaylist.h"

@interface JJFSharingController ()

@property (nonatomic, strong) JJFSessionManager *sessionManager;

@end

@implementation JJFSharingController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.sharedPlaylist = [[JJFSharedPlaylist alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedPlaylistWithNotification:) name:@"receivedPlaylistFromHost" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedEntryWithNotification:) name:@"receivedEntryFromPeer" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedResourceWithNotification:) name:@"finishedReceivingResource" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendUpdatedPlaylist) name:@"peerJoinedSession" object:nil];
    }
    
    return self;
}

- (JJFSessionManager *)sessionManager
{
    return [JJFSessionManager sharedManager];
}

- (void)sendUpdatedPlaylist
{
    
    NSDictionary *dict = @{@"type": @"playlist",
                           @"playlist": self.sharedPlaylist.playlist};
    
    NSData *playlistData = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    NSArray *allPeers = [self.sessionManager.session connectedPeers];
    
    [self.sessionManager.session sendData:playlistData toPeers:allPeers withMode:MCSessionSendDataReliable error:nil];
    
}

- (void)receivedResourceWithNotification:(NSNotification *)note
{
    NSDictionary *dict = [note userInfo];
    NSString *resourceName = [dict objectForKey:@"resourceName"];
    NSURL *localURL = [dict objectForKey:@"URL"];
    NSError *error = [dict objectForKey:@"error"];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSURL *directory = [[NSURL alloc] initFileURLWithPath:docsDir isDirectory:YES];
    
    NSURL *outputFilePath = [[directory URLByAppendingPathComponent:resourceName] URLByAppendingPathExtension:@"caf"];
    
    [[NSFileManager defaultManager] moveItemAtURL:localURL toURL:outputFilePath error:&error];
    NSLog(@"File Saved At %@", outputFilePath);
    
    JJFPlaylistEntry *entry = [self.sharedPlaylist entryForUUIDString:resourceName];
    [self.sharedPlaylist updateLocalURL:outputFilePath forEntry:entry];
    
    NSDictionary *entryDict = @{@"entry": entry};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"entryReadyForQueue" object:self userInfo:entryDict];
    
}

- (void)receivedPlaylistWithNotification:(NSNotification *)note
{
    NSArray *playlist = [[note userInfo] valueForKey:@"playlist"];
    [self.sharedPlaylist setPlaylist:playlist];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedData" object:self];
    
}

- (void)receivedEntryWithNotification:(NSNotification *)note
{
    JJFPlaylistEntry *entry = [[note userInfo] valueForKey:@"entry"];
    [self.sharedPlaylist addEntry:entry];
    [self sendUpdatedPlaylist];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedData" object:self];

}

- (void)handleEntry:(JJFPlaylistEntry *)entry
{
    
    //If host, add song immediately to playlist & queue, send playlist
    if (self.sessionManager.isHost)
    {
        entry.isStreaming = NO;
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
        [self prepareEntryForHost:entry];
        
    }
}

- (void)prepareEntryForHost:(JJFPlaylistEntry *)entry
{
    
    // Sends metadata about the entry to host
    [self sendEntryData:entry];
    
    // Convert the entry to a local, compressed AAC format CAF file
    JJFAudioFileConverter *converter = [[JJFAudioFileConverter alloc] initWithPlaylistEntry:entry];
    converter.delegate = self;
    
    [converter convertWithFileName:entry.uuid.UUIDString];
    //Converter will call back to sendConvertedEntry when finished

}

- (void)sendConvertedEntry:(JJFPlaylistEntry *)entry atURL:(NSURL *)filePath
{
    [self.sessionManager.session sendResourceAtURL:filePath
                                          withName:entry.uuid.UUIDString toPeer:self.sessionManager.host
                             withCompletionHandler:^(NSError *error){
                                 
                                 //Handle the error.
                                 NSLog(@"Entry Finished Sending");
                                 
                             }];
}

- (void)sendEntryData:(JJFPlaylistEntry *)entry
{
    NSDictionary *dict = @{@"type": @"entry",
                           @"entry": entry};
    
    NSData *entryData = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    NSArray *hostArray = [NSArray arrayWithObject:self.sessionManager.host];
    
    [self.sessionManager.session sendData:entryData toPeers:hostArray withMode:MCSessionSendDataReliable error:nil];
}

- (void)removePlaylistTop
{
    [self.sharedPlaylist removeTop];
    [self sendUpdatedPlaylist];
}
@end
