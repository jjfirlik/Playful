//
//  JJFSessionTableViewController.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/9/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFSessionTableViewController.h"

@interface JJFSessionTableViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation JJFSessionTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setAutoresizesSubviews:NO];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSong:)];
    
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
    
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
    MPMediaItem *song = [[mediaItemCollection items] firstObject];
    
    JJFPlaylistEntry *entry = [[JJFPlaylistEntry alloc] initWithMediaItem:song andPeerID:self.sessionManager.peerID];
    
    [self.sessionManager.sharedPlaylist addEntry:entry];
    
    NSInteger lastRow = [self.sessionManager.sharedPlaylist.playlist indexOfObject:entry];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationTop];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = [[self.sessionManager.sharedPlaylist playlist] count];
    NSLog(@"PLAYLIST COUNT %lu", count);
    return count;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    NSLog(@"Cellforrow");
    
    JJFPlaylistEntry *item = [self.sessionManager.sharedPlaylist.playlist objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", item.songTitle, item.artistName];

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
