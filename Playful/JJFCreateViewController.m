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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePeerDisplays:) name:@"peerFoundOrLost" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

- (void)updatePeerDisplays:(NSNotification *)notification
{
    
    NSDictionary *userInfo = [notification userInfo];
    NSArray *peersArray = [userInfo valueForKey:@"peers"];
    NSUInteger peerCount = [peersArray count];

    
    
    NSMutableString *peerCountLabelText = [NSMutableString stringWithFormat:@"Found %@ peer", [NSNumber numberWithInteger:peerCount]];

    if (peerCount != 1)
    {
        [peerCountLabelText appendString:@"s"];
    }
    
    
    NSMutableString *peerNameLabelText = [NSMutableString string];
    
    for (MCPeerID *peer in peersArray)
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
    
    [self.navigationController pushViewController:sessionViewController animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
