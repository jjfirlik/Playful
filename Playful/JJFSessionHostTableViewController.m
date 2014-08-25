//
//  JJFSessionHostTableViewController.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/9/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFSessionHostTableViewController.h"
#import "JJFInputStream.h"
#import "JJFPlaylistPlayer.h"
#import "JJFPlaylistCell.h"

@interface JJFSessionHostTableViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) JJFInputStream *inputStream;

@property (weak, nonatomic) IBOutlet UILabel *playlistLabel;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
- (IBAction)togglePlayback:(UIButton *)button;
- (IBAction)nextSong:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (strong, nonatomic) JJFPlaylistPlayer *player;
@property (weak, nonatomic) JJFSessionManager *sessionManager;

@property (strong, nonatomic) NSMutableArray *entriesDoneStreaming;

@end

@implementation JJFSessionHostTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setAutoresizesSubviews:NO];
    
    self.tableView.delegate = self;
    self.tableView.rowHeight = 65.0;
    self.tableView.dataSource = self;
    
    self.inputStream = [[JJFInputStream alloc] initWithInputStream:nil];
    self.entriesDoneStreaming = [NSMutableArray array];
    
    self.player = [[JJFPlaylistPlayer alloc] init];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSong:)];
    
    /*[self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];*/
    
    UINib *nib = [UINib nibWithNibName:@"JJFPlaylistCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"JJFPlaylistCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableWithNotification:) name:@"receivedData" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addEntryToQueueWithNotification:) name:@"entryReadyForQueue" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songFinishedPlayingWithNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    NSLog(@"color is %@", self.playlistLabel.textColor);
    
    //Hide the status bar
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated
{

}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
}

- (JJFSessionManager *)sessionManager
{
    return [JJFSessionManager sharedManager];
}

- (void)updateTableWithNotification:(NSNotification *)note
{
    [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
}

- (void)updateTable
{
    [self.tableView reloadData];
}

- (void)updateCellWithEntry:(JJFPlaylistEntry *)entry
{
    NSInteger index = [self.sessionManager.sharedPlaylist.playlist indexOfObject:entry];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    JJFPlaylistCell *cell = (JJFPlaylistCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    [cell.activityIndicator stopAnimating];
}

/*- (BOOL)prefersStatusBarHidden {
    return YES;
}*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Old Playlist Player Logic
/*
- (void)addLocalSongWithNotification:(NSNotification *)note
{
    NSDictionary *dict = [note userInfo];
    JJFPlaylistEntry *entry = [dict objectForKey:@"entry"];
    
    if (!self.player)
    {
        self.player = [[JJFPlaylistPlayer alloc] init];
        [self.player addEntry:entry];
    }
}

- (void)finishedWritingFileWithNotification:(NSNotification *)note
{
    JJFSharedPlaylist *sharedPlaylist = [self.sessionManager sharedPlaylist];
    
    [self beginPlayingWithNotification:note];
    
    NSDictionary *dict = [note userInfo];
    
    JJFPlaylistEntry *entry = [dict objectForKey:@"entry"];
    JJFPlaylistEntry *localEntry = [sharedPlaylist entryForUUID:entry.uuid];
    
    NSUInteger index = [sharedPlaylist.playlist indexOfObject:localEntry];
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    
    JJFPlaylistCell *cell = (JJFPlaylistCell *)[self.tableView cellForRowAtIndexPath:path];
    
    [cell.activityIndicator stopAnimating];
    [cell setActivityIndicator:nil];
    
}

- (void)beginPlayingWithNotification:(NSNotification *)note
{
    if (!self.player)
    {
        self.player = [[JJFPlaylistPlayer alloc] initWithPlaylist:self.sessionManager.sharedPlaylist];
        [self.player play];
    }
    
    else
    {
        JJFPlaylistEntry *entry = [[note userInfo] objectForKey:@"entry"];
        [self.player addEntry:entry];
    }
}
*/

#pragma mark - Playlist Player Logic

- (void)addEntryToQueueWithNotification:(NSNotification *)note
{
    NSDictionary *dict = [note userInfo];
    
    JJFPlaylistEntry *entry = [dict objectForKey:@"entry"];
    
    entry.isStreaming = NO;
    
    [self performSelectorOnMainThread:@selector(addEntryToQueue:) withObject:entry waitUntilDone:YES];
    
    [self updateCellWithEntry:entry];
    
    [self.sessionManager sendUpdatedPlaylist];
}

- (void)addEntryToQueue:(JJFPlaylistEntry *)entry
{
    [self.player addEntry:entry];
    
    if (![self.player isPlaying])
        [self.player play];
}

- (void)songFinishedPlayingWithNotification:(NSNotification *)note
{
    [self.sessionManager removeTop];
    [self updateTable];
}

#pragma mark - Media Picker

- (IBAction)addSong:(id)sender
{
    NSLog(@"Add da song");
    
    JJFMediaPickerController *mediaPicker = [[JJFMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.delegate = self;
    
    [self presentViewController:mediaPicker animated:YES completion:nil];
    
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:mediaPicker completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    
    [self dismissViewControllerAnimated:YES completion:nil];

    MPMediaItem *song = [[mediaItemCollection items] firstObject];
    
    JJFPlaylistEntry *entry = [[JJFPlaylistEntry alloc] initWithMediaItem:song andPeerID:self.sessionManager.peerID];
    
    [self.sessionManager handleEntry:entry];
    
    NSInteger lastRow = [self.sessionManager.sharedPlaylist.playlist indexOfObject:entry];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationTop];
    
    
}

- (IBAction)togglePlayback:(UIButton *)sender {
    if (sender.selected)
    {
        sender.selected = NO;
        [self.player play];
    }
    
    else
    {
        sender.selected = YES;
        [self.player pause];
    }
    
}

- (IBAction)nextSong:(id)sender {
   

    if ([self.sessionManager.sharedPlaylist.playlist count] == 0)
    {
        return;
    }
    
    [self.player next];
    [self.sessionManager removeTop];
    
    [self updateTable];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = [[self.sessionManager.sharedPlaylist playlist] count];
    NSLog(@"PLAYLIST COUNT %lu", count);
    return count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = self.playlistLabel.textColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JJFPlaylistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JJFPlaylistCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    NSLog(@"Cellforrow");
    
    JJFPlaylistEntry *item = [self.sessionManager.sharedPlaylist.playlist objectAtIndex:indexPath.row];
    
    cell.artistLabel.text = item.artistName;
    cell.albumImage.image = item.albumImage;
    cell.songLabel.text = item.songTitle;
    
    if (item.isStreaming)
    {
        [cell.activityIndicator startAnimating];
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/
@end
