//
//  JJFJoinViewController.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/6/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFJoinViewController.h"
#import "JJFSessionManager.h"
#import "JJFAppDelegate.h"
#import "JJFSessionPeerTableViewController.h"

@interface JJFJoinViewController ()

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (weak, nonatomic) IBOutlet UILabel *peerCountLabel;
@property (weak, nonatomic) IBOutlet UITextView *peerNameTextView;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;

- (IBAction)join:(id)sender;

@end

@implementation JJFJoinViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // Set up the background tap to go back
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [self.view addGestureRecognizer:self.tapGesture];
        
        self.displayName = @"BillyBob";
        
        [[JJFSessionManager sharedManager] advertiseSelf:YES];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePeerDisplays:) name:@"receivedInvitation" object:nil];
    
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

/*- (BOOL)prefersStatusBarHidden {
 return YES;
 }*/

- (void)updatePeerDisplays:(NSNotification *)notification
{
    
    NSDictionary *userInfo = [notification userInfo];
    MCPeerID *peer = [userInfo valueForKey:@"peerID"];
    
    NSString *peerCountLabelText = @"Found session";
    
    
    NSString *peerNameLabelText = peer.displayName;
    
    self.peerCountLabel.text = peerCountLabelText;
    self.peerNameTextView.text = peerNameLabelText;
    
    UIColor *deepTurquoise = [UIColor colorWithRed:55.0/255.0 green:85.0/255.0 blue:99.0/255.0 alpha:1.0];
    
    [UIView animateWithDuration:2.0
                     animations:^{
                         self.joinButton.backgroundColor = deepTurquoise;
                     }];
    
}


- (IBAction)backgroundTapped:(UITapGestureRecognizer *)recognizer
{
    [[JJFSessionManager sharedManager] resetSession];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)join:(id)sender {
    
    if ([JJFSessionManager sharedManager].peerCount == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Sessions Found" message:@"Please join a session" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
        return;
    }
    
    JJFSessionPeerTableViewController *sessionViewController = [[JJFSessionPeerTableViewController alloc] init];
    
    [self.navigationController pushViewController:sessionViewController animated:YES];
    
}
@end
