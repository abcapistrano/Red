//
//  DJQueueManager.h
//  Red
//
//  Created by Earl on 2/21/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DJQueueManager : NSObject
@property (readonly) NSManagedObjectContext *managedObjectContext;
@property (strong) NSOperationQueue *queue;
- (void) addReadingListItemWithInfoDictionary: (NSDictionary *) dict;
+ (id)sharedQueueManager;
- (void) readItems;
- (void) buildReadingList;
@end
