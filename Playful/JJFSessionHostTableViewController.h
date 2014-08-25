
//  JJFSessionHostTableViewController.h
//  PlayfulTest
//
//  Created by Jackson Firlik on 7/9/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJFMediaPickerController.h"
#import "JJFSharedPlaylist.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "JJFSessionManager.h"

@interface JJFSessionHostTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MPMediaPickerControllerDelegate>

@end