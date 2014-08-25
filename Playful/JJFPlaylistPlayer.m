//
//  JJFPlaylistPlayer.m
//  Playful
//
//  Created by Jackson Firlik on 8/1/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFPlaylistPlayer.h"
#import "JJFSessionManager.h"

@interface JJFPlaylistPlayer ()

@property (weak, nonatomic) JJFSharedPlaylist *playlist;
@property (strong, nonatomic) AVQueuePlayer *player;

@end

@implementation JJFPlaylistPlayer

- (instancetype)initWithPlaylist:(JJFSharedPlaylist *)playlist
{
    self = [super init];
    
    if (self)
    {
        self.player = [[AVQueuePlayer alloc] init];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithPlaylist:nil];
}

- (JJFSharedPlaylist *)playlist
{
    return [[JJFSessionManager sharedManager] sharedPlaylist];
}

- (void)setupQueue
{
    NSArray *playlistArray = [self.playlist playlist];
    NSMutableArray *playlistItems = [NSMutableArray array];
    
    for (JJFPlaylistEntry *item in playlistArray)
    {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[item songURL]];
        NSLog(@"Adding %@", item.songURL);
        [playlistItems addObject:playerItem];
    }
    
    self.player = [[AVQueuePlayer alloc] initWithItems:playlistItems];
}

- (void)addEntry:(JJFPlaylistEntry *)entry
{
    NSURL *songURL = [entry songURL];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:songURL];
    
    [self.player insertItem:item afterItem:nil];
}

/*- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[AVPlayerItem class]])
    {
        AVPlayerItem *item = (AVPlayerItem *)object;
        //playerItem status value changed?
        if ([keyPath isEqualToString:@"status"])
        {   //yes->check it...
            switch(item.status)
            {
                case AVPlayerItemStatusFailed:
                    NSLog(@"player item status failed");
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    NSLog(@"player item status is ready to play");
                    [self.player insertItem:item afterItem:nil];
                    break;
                case AVPlayerItemStatusUnknown:
                    NSLog(@"player item status is unknown");
                    break;
            }
        }
    }
}
*/

- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (void)next
{
    [self.player advanceToNextItem];
}

- (BOOL)isPlaying
{
    return ([self.player rate] != 0);
}

@end
