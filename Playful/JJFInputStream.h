//
//  JJFInputStream.h
//  Playful
//
//  Created by Jackson Firlik on 7/28/14.
//  Copyright (c) 2014 Jackson Firlik. All rights reserved.
//


#import <Foundation/Foundation.h>
@class JJFPlaylistEntry;

@protocol JJFInputStreamDelegate <NSObject>

@optional
- (void)inputStreamEndedForEntry:(JJFPlaylistEntry *)entry;

@end

@interface JJFInputStream : NSObject

@property (nonatomic, strong) id<JJFInputStreamDelegate> delegate;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream;
- (instancetype)initWithInputStream:(NSInputStream *)inputStream andEntry:(JJFPlaylistEntry *)entry;

- (void)start;

@end

