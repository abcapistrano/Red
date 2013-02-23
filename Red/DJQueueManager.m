//
//  DJQueueManager.m
//  Red
//
//  Created by Earl on 2/21/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "DJQueueManager.h"
#import "ReadingListItem+Extra.h"
#import "DJAppDelegate.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "Safari.h"
@implementation DJQueueManager
+ (id)sharedQueueManager
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });



    return sharedInstance;
}

- (void) addReadingListItemWithInfoDictionary: (NSDictionary *) dict {

    

    ReadingListItem *item = [ReadingListItem readingListItemWithDefaultContext];
    item.urlString = dict[@"url"];
    item.referrer = dict[@"referrer"];
    item.title = dict[@"title"];

    //TODO: download the real title of the page


    NSUserNotification *note = [NSUserNotification new];
    note.title = @"Added item to the reading list";
    note.informativeText = [NSString stringWithFormat:@"From %@ (via %@).", item.url.host, item.referrerURL.host];
    note.actionButtonTitle = @"Close";

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];


    [[NSApp delegate] saveAction:self];
}

- (void) readItems {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReadingListItem"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isRead == NO"];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:YES];

    request.predicate = pred;
    request.sortDescriptors = @[sd];
    request.fetchLimit = 5;

    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    [self openURLsInSafari:[results valueForKey:@"url"]];

    //mark as read the items fetched
    [results makeObjectsPerformSelector:@selector(markAsRead)];
    [[NSApp delegate] saveAction:self];
    
}

- (void) openURLsInSafari: (NSArray *) urls {

    SafariApplication *safari = [SBApplication applicationWithBundleIdentifier:@"com.apple.Safari"];
    [safari activate];
    SafariDocument *doc = [[safari classForScriptingClass:@"document"] new];

    [safari.documents addObject:doc];

    SafariWindow *activeWindow = [safari.windows objectAtIndex:0];

    Class tabClass = [safari classForScriptingClass:@"tab"];
    [urls enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {

        SafariTab *tab = [tabClass new];
        [activeWindow.tabs addObject:tab];
        tab.URL = url.absoluteString;
        
        
        
    }];

    //close the first tab coz its fake
    [[activeWindow.tabs objectAtIndex:0] closeSaving:0 savingIn:nil];

    
}



- (NSManagedObjectContext *) managedObjectContext {
    return [[NSApp delegate] managedObjectContext];
}

- (void) buildReadingList {


    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"LinkRollSite"];

    NSMutableArray *sites = [NSMutableArray array];

    // General
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group == %@", @"General"];
    [request setPredicate:predicate];
    
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"lastDateAccessed" ascending:YES];
    [request setSortDescriptors:@[sd]];

    [request setFetchLimit:5];

    [sites addObjectsFromArray:[self.managedObjectContext executeFetchRequest:request error:nil]];
    
    //News
    predicate = [NSPredicate predicateWithFormat:@"group == %@", @"News"];
    [request setPredicate:predicate];
    [request setFetchLimit:3];
    [sites addObjectsFromArray:[self.managedObjectContext executeFetchRequest:request error:nil]];



    //Important
    predicate = [NSPredicate predicateWithFormat:@"group == %@", @"Important"];
    [request setPredicate:predicate];
    [request setFetchLimit:0];
    [sites addObjectsFromArray:[self.managedObjectContext executeFetchRequest:request error:nil]];

//open
    [self openURLsInSafari:[sites valueForKey:@"url"]];
    //mark as read
    [sites makeObjectsPerformSelector:@selector(read)];

    [[NSApp delegate] saveAction:self];









    
}


@end
