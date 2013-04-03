//
//  DJSafariBookmarksManager.h
//  Red
//
//  Created by Earl on 2/23/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DJLinkImporter : NSObject

@property (strong) NSMutableArray *linkRoll;
@property (strong) NSMutableArray *readingList;
@property (strong) NSArray *linkRollListNames;
@property (readonly) NSManagedObjectContext *managedObjectContext;
@property (strong, readonly, nonatomic) NSDictionary * constants;
+ (id)sharedImporter;
- (void) reload;
- (void) updateLinkRoll;
- (void) importReadingListItems;
- (void) importToDosFromThingsApp;
@end
