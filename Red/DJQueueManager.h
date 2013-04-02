//
//  DJQueueManager.h
//  Red
//
//  Created by Earl on 2/21/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DJReadingListQueue.h"

@interface DJQueueManager : NSObject <DJReadingListQueue, NSUserNotificationCenterDelegate> {

    NSXPCConnection *_connection;

    NSTimer *_countdownTimer;
    NSUInteger remainingTicks;
}

@property (readonly) NSManagedObjectContext *managedObjectContext;
@property (strong) NSOperationQueue *queue;
@property (assign) BOOL isCountingdown;
@property (readonly, nonatomic, strong) NSDictionary * constants;
- (void) addReadingListItemWithInfoDictionary: (NSDictionary *) dict;
- (void) readItems;
- (void) buildReadingList;
- (void) viewOnlinePorn;
@end
