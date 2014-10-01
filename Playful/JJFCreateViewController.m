//
//  JJFCreateViewController.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/6/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFCreateViewController.h"
#import "JJFSessionManager.h"
#import "JJFAppDelegate.h"
#import "JJFSessionHostTableViewController.h"

@interface JJFCreateViewController ()

@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@property (weak, nonatomic) IBOutlet UILabel *peerCountLabel;
@property (weak, nonatomic) IBOutlet UITextView *peerNameTextView;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UILabel *tapAnywhere;
@property (weak, nonatomic) UIColor *lightTurquoise;
@property (weak, nonatomic) UIColor *deepTurquoise;

@property (strong, nonatomic) NSMutableArray *peersFound;

- (IBAction)connect:(id)sender;

@end

@implementation JJFCreateViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Set up the background tap to go back
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [self.view addGestureRecognizer:self.tapGesture];
        
        self.peersFound = [NSMutableArray array];
        
        self.displayName = @"Jackson";
        
        [[JJFSessionManager sharedManager] browseForPeers:YES];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    //hide the status bar
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePeerDisplaysWithNotification:) name:@"peerFoundOrLost" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    
    [self.view setBackgroundColor:self.lightTurquoise];

    [self.connectButton setHidden:NO];
    [self.peerCountLabel setAlpha:1.0];
    [self.peerNameTextView setAlpha:1.0];
    [self.tapAnywhere setAlpha:1.0];
    [self updatePeerDisplays];
    
}

- (UIColor *)lightTurquoise
{
    return [UIColor colorWithRed:164.0/255.0 green:193.0/255.0 blue:193.0/255.0 alpha:1.0];
}

- (UIColor *)deepTurquoise
{
    return [UIColor colorWithRed:55.0/255.0 green:85.0/255.0 blue:99.0/255.0 alpha:1.0];
}

- (void)updatePeerDisplaysWithNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSArray *peersArray = [userInfo valueForKey:@"peers"];
    self.peersFound = [NSMutableArray arrayWithArray:peersArray];
    [self performSelectorOnMainThread:@selector(updatePeerDisplays) withObject:nil waitUntilDone:YES];
}

- (void)updatePeerDisplays
{
    NSUInteger peerCount = [self.peersFound count];
    
    NSMutableString *peerCountLabelText = [NSMutableString stringWithFormat:@"Found %@ peer", [NSNumber numberWithInteger:peerCount]];
    
    if (peerCount != 1)
    {
        [peerCountLabelText appendString:@"s"];
    }
    
    
    NSMutableString *peerNameLabelText = [NSMutableString string];
    
    for (MCPeerID *peer in self.peersFound)
    {
        [peerNameLabelText appendFormat:@"%@\n", peer.displayName];
    }
    
    
    self.peerCountLabel.text = peerCountLabelText;
    self.peerNameTextView.text = peerNameLabelText;
}

/*- (BOOL)prefersStatusBarHidden {
    return YES;
}*/

- (IBAction)backgroundTapped:(UITapGestureRecognizer *)recognizer
{
    if ([JJFSessionManager sharedManager].peerCount != 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Session In Progress" message:@"Peers will be disconnected" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alert show];
    }
    
    
    [[JJFSessionManager sharedManager] resetSession];
    
    [self.navigationController popViewControllerAnimated:YES];

}

- (IBAction)connect:(id)sender
{
    //[[self.appDelegate sessionManager] browseForPeers:NO];
    //[[self.appDelegate sessionManager] inviteAllPeers];
    
    JJFSessionHostTableViewController *sessionViewController = [[JJFSessionHostTableViewController alloc] init];
    
    [UIView animateWithDuration:1.0
                     animations:^{
    
                         [self.view setBackgroundColor:self.deepTurquoise];
                         [self.peerCountLabel setAlpha:0.0];
                         [self.peerNameTextView setAlpha:0.0];
                         [self.tapAnywhere setAlpha:0.0];
                         [self.connectButton setFrame:CGRectMake(0.0, 568.0, 320.0, 70.0)];
                     }
                     completion:^(BOOL finished){
                         [self.connectButton setHidden:YES];
                         [self.navigationController pushViewController:sessionViewController animated:YES];
                         
                     }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
