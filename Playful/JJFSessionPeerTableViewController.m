//
//  JJFSessionPeerTableViewController.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/9/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFSessionPeerTableViewController.h"
#import "JJFOutputStream.h"
#import "JJFPlaylistCell.h"

@interface JJFSessionPeerTableViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *playlistLabel;

//@property (strong, nonatomic) JJFOutputStream *outputStream;

@property (weak, nonatomic) JJFSessionManager *sessionManager;

@end

@implementation JJFSessionPeerTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setAutoresizesSubviews:NO];
    
    self.tableView.delegate = self;
    self.tableView.rowHeight = 65.0;
    self.tableView.dataSource = self;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSong:)];
    
    UINib *nib = [UINib nibWithNibName:@"JJFPlaylistCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"JJFPlaylistCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableWithNotification:) name:@"receivedData" object:nil];

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

- (void)updateTableWithNotification:(NSNotification *)notification
{
    [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
}

- (void)updateTable
{
    [self.tableView reloadData];
}

/*- (BOOL)prefersStatusBarHidden {
    return YES;
}*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (JJFSessionManager *)sessionManager
{
    return [JJFSessionManager sharedManager];
}

/*
- (void)finishedStreamingWithNotification:(NSNotification *)note
{
    JJFSharedPlaylist *sharedPlaylist = [JJFSessionManager sharedManager].sharedPlaylist;
    
    NSDictionary *dict = [note userInfo];
    
    JJFPlaylistEntry *entry = [dict objectForKey:@"entry"];
    
    NSUInteger index = [sharedPlaylist.playlist indexOfObject:entry];
    
    NSLog(@"INDEX %lu", index);
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    
    JJFPlaylistCell *cell = (JJFPlaylistCell *)[self.tableView cellForRowAtIndexPath:path];

    [self performSelector:@selector(stopAnimating:) onThread:[NSThread mainThread] withObject:cell waitUntilDone:NO];
}

- (void)stopAnimating:(JJFPlaylistCell *)cell
{
    [cell.activityIndicator stopAnimating];
    [cell setActivityIndicator:nil];
    
    NSLog(@"%@ set to NIL", cell.songLabel.text);

    
}*/

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
    
    if (![entry.songURL.pathExtension isEqualToString:@"mp3"])
    { UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Song Format" message:@"Song must not be DRM protected" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    return;}
    
    [self.sessionManager handleEntry:entry];
    
    NSInteger lastRow = [self.sessionManager.sharedPlaylist.playlist indexOfObject:entry];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationBottom];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = [[self.sessionManager.sharedPlaylist playlist] count];
    NSLog(@"Playlist count: %lu", count);
    return count;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Additional cell formatting
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = self.playlistLabel.textColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JJFPlaylistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JJFPlaylistCell" forIndexPath:indexPath];
    
    NSLog(@"Cell for row at index: %@", indexPath);
    
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
