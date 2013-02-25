//
//  DJSafariBookmarksManager.m
//  Red
//
//  Created by Earl on 2/23/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "DJLinkImporter.h"
#import "DJAppDelegate.h"
#import "LinkRollSite+Extra.h"
#import "ReadingListItem+Extra.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "Things.h"
NSString * const SAFARI_BOOKMARKS_PATH = @"/Users/earltagra/Library/Safari/Bookmarks.plist";

@implementation DJLinkImporter
+ (id)sharedImporter
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance reload];
    });


    return sharedInstance;
}


- (id)init
{
    self = [super init];
    if (self) {
        _linkRoll = [NSMutableArray array];
  //      _linkRollListNames = @[@"General", @"Important", @"News", @"Occasional"];
        _readingList = [NSMutableArray array];

    }
    return self;
}

- (void) reload {


    NSDictionary *bookmarksDict = [NSDictionary dictionaryWithContentsOfFile:SAFARI_BOOKMARKS_PATH];
    
    [self recurse:bookmarksDict parent:nil];

}

-(void)recurse:(NSDictionary *)dict parent:(NSDictionary *) parent{

    NSString *type = [dict valueForKey:@"WebBookmarkType"];

    if ([type isEqualToString:@"WebBookmarkTypeList"]) {


        NSArray *children = [dict valueForKey:@"Children"];

        NSString *title = [dict valueForKey:@"Title"];
        if ([title isEqualToString:@"@red"]) {

            self.linkRollListNames = [dict valueForKeyPath:@"Children.Title"];

        }
        for (NSDictionary *child in children) {
            [self recurse:child parent:dict];
        }
        

    } else if ([type isEqualToString:@"WebBookmarkTypeLeaf"]) {

        NSString *parentTitle = [parent valueForKey:@"Title"];
        if ([self.linkRollListNames containsObject:parentTitle]) {


            NSDictionary *bookmark = @{
                                       @"title": [dict valueForKeyPath:@"URIDictionary.title"],
                                       @"group": parentTitle,
                                       @"urlString": [dict valueForKey:@"URLString"]
                                       };
            [self.linkRoll addObject:bookmark];

            

            //we're under the @"red" bookmarks




        } else if ([parentTitle isEqualToString:@"com.apple.ReadingList"]) {

            NSDictionary *item= @{
                                       @"title": [dict valueForKeyPath:@"URIDictionary.title"],
                                       @"urlString": [dict valueForKey:@"URLString"],
                                       @"dateAdded": [dict valueForKeyPath:@"ReadingList.DateAdded"],
                                                      
                                                      
                                       };

            
            [self.readingList addObject:item];


        }
    }


}

- (void) updateLinkRoll {

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"LinkRollSite"];
    NSArray *sites = [self.managedObjectContext executeFetchRequest:request error:nil];

    // Look for what's new; compare what was added to the bookmarks
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT(urlString IN %@)", [sites valueForKey:@"urlString"]];
    NSArray *newLinkRollSites = [self.linkRoll filteredArrayUsingPredicate:predicate];

    [newLinkRollSites enumerateObjectsUsingBlock:^(NSDictionary* siteInfo, NSUInteger idx, BOOL *stop) {
        LinkRollSite *site = [LinkRollSite linkRollSiteWithDefaultContext];
        [site setValuesForKeysWithDictionary:siteInfo];

        
    }];
    // Look for what's new; compare what was deleted from the bookmarks

    predicate = [NSPredicate predicateWithFormat:@"NOT(urlString IN %@)", [self.linkRoll valueForKey:@"urlString"]];
    NSArray *deletedLinkRollSites = [sites filteredArrayUsingPredicate:predicate];

    [deletedLinkRollSites enumerateObjectsUsingBlock:^(LinkRollSite *site, NSUInteger idx, BOOL *stop) {

        [self.managedObjectContext deleteObject:site];
        NSLog(@"%@ was deleted", site.title);

    }];


    
}

- (void) importReadingListItems {

    for (NSDictionary *info in self.readingList) {

        ReadingListItem *item = [ReadingListItem readingListItemWithDefaultContext];
        [item setValuesForKeysWithDictionary:info];

        
    }



}

- (void) importToDosFromThingsApp {

    ThingsApplication *things = [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
    ThingsArea *redQueue =[things.areas objectWithName:@"Red Queue"];

    SBElementArray *todos = redQueue.toDos;


    [todos enumerateObjectsUsingBlock:^(ThingsToDo* todo, NSUInteger idx, BOOL *stop) {

        if (todo.status == ThingsStatusOpen) {

            ReadingListItem *item = [ReadingListItem readingListItemWithDefaultContext];
            item.title = todo.name;
            item.dateAdded = todo.creationDate;
            item.urlString = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", item.title];
            todo.status = ThingsStatusCompleted;
            
        }
       

    }];



    
}

- (NSManagedObjectContext *) managedObjectContext {
    return [[NSApp delegate] managedObjectContext];
}



@end
