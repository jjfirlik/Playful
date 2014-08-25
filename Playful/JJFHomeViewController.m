//
//  JJFHomeViewController.m
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/6/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import "JJFHomeViewController.h"
#import "JJFCreateViewController.h"
#import "JJFJoinViewController.h"
#import "JJFAppDelegate.h"

@interface JJFHomeViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *homeImage;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
- (IBAction)createSession:(id)sender;
- (IBAction)joinSession:(id)sender;


@end

@implementation JJFHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBar.hidden = YES;
    
    //Hide the status bar
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}


/*- (BOOL)prefersStatusBarHidden {
 return YES;
 }*/


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createSession:(id)sender {
    
    JJFCreateViewController *createViewController = [[JJFCreateViewController alloc] init];
    
    [self.navigationController pushViewController:createViewController animated:YES];
    
}

- (IBAction)joinSession:(id)sender {
    
    JJFJoinViewController *joinViewController = [[JJFJoinViewController alloc] init];
    
    [self.navigationController pushViewController:joinViewController animated:YES];
}
@end
