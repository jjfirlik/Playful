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
#import "JJFAudioFileConverter.h"
#import "JJFSharingController.h"

@interface JJFSessionPeerTableViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *playlistLabel;
@property (nonatomic, weak) IBOutlet UIView *headerView;

@property (nonatomic, weak) JJFSessionManager *sessionManager;
@property (nonatomic, strong) JJFSharingController *sharingController;

@end

@implementation JJFSessionPeerTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setAutoresizesSubviews:NO];
    
    self.tableView.delegate = self;
    self.tableView.rowHeight = 100.0;
    self.tableView.dataSource = self;
    
    [self.headerView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.headerView.layer setShadowOpacity:1.0];
    [self.headerView.layer setShadowRadius:10.0];
    [self.headerView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    [self.headerView.layer setZPosition:2.0];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.sharingController = [[JJFSharingController alloc] init];

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

#pragma mark - Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat relativeScrollOffset = scrollView.contentOffset.y / MAX(self.tableView.contentSize.height,
                                                                    self.tableView.frame.size.height);
    NSLog(@"ScrollViewOffset %f", relativeScrollOffset);

    CGFloat backgroundOffset = relativeScrollOffset * self.tableView.rowHeight;
    for (int i = 0; i <self.sharingController.sharedPlaylist.playlist.count; i++) {
        JJFPlaylistCell *cell = (JJFPlaylistCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        CGRect frame = CGRectMake(cell.backgroundView.frame.origin.x,
                                  backgroundOffset,
                                  cell.backgroundView.frame.size.width,
                                  cell.backgroundView.frame.size.height);
        cell.backgroundView.frame = frame;
        
    }
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

    
    // Check to make sure it is a valid file, not iCloud Media
        NSURL *songURL = [entry songURL];

        if (!songURL)
        {
            NSLog(@"URL is %@, probably iCloud media", songURL);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Add Song" message:@"Song cannot be iCloud Media" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
            return;
        }
    
    // Send entry to sharing controller for handling
    [self.sharingController handleEntry:entry];
    
    NSInteger lastRow = [self.sharingController.sharedPlaylist.playlist indexOfObject:entry];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationBottom];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = [[self.sharingController.sharedPlaylist playlist] count];
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

//Image Scaling Function
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JJFPlaylistCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JJFPlaylistCell" forIndexPath:indexPath];
    
    NSLog(@"Cell for row at index: %@", indexPath);
    
    JJFPlaylistEntry *item = [self.sharingController.sharedPlaylist.playlist objectAtIndex:indexPath.row];
    
    UIColor *deepTurquoise = [UIColor colorWithRed:55.0/255.0 green:85.0/255.0 blue:99.0/255.0 alpha:1.0];
    
    UIImage *backgroundImage = [self imageWithImage:item.albumImage scaledToSize:CGSizeMake(320.0, 320.0)];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    cell.backgroundView = backgroundView;
    [cell.backgroundView setContentMode:UIViewContentModeCenter];
    
    
    NSMutableAttributedString *songString = [[NSMutableAttributedString alloc] initWithString:item.songTitle];
    [songString addAttribute:NSBackgroundColorAttributeName value:deepTurquoise range:NSMakeRange(0, songString.length)];
    cell.songLabel.attributedText = songString;
    
    
    NSMutableAttributedString *artistString = [[NSMutableAttributedString alloc] initWithString:item.artistName];
    [artistString addAttribute:NSBackgroundColorAttributeName value:deepTurquoise range:NSMakeRange(0, artistString.length)];
    cell.artistLabel.attributedText = artistString;
    
    if (item.isStreaming)
    {
        [cell.activityIndicator startAnimating];
    }
    
    [cell layoutSubviews];

    
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
