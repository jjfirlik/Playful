//
//  JJFPlaylistCell.h
//  Playful
//
//  Created by Jackson Firlik on 8/13/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JJFPlaylistCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *albumImage;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (assign, nonatomic) BOOL finishedStreaming;


@end
