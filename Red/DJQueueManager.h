//
//  DJQueueManager.h
//  Red
//
//  Created by Earl on 2/21/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DJQueueManager : NSObject
- (void) addReadingListItemWithJSONInfo: (id) json;
+ (id)sharedQueueManager;
@end
