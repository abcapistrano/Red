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
#import "AFNetworking.h"
#import "NSArray+ConvenienceMethods.h"
#import "NSDate+Weekend.h"
#import "Things.h"

@implementation DJQueueManager

- (id)init
{
    self = [super init];
    if (self) {
        _queue = [NSOperationQueue new];

        _connection = [[NSXPCConnection alloc] initWithServiceName:@"com.demonjelly.RedWebServer"];
        [_connection setExportedObject:self];
        NSXPCInterface *interface = [NSXPCInterface interfaceWithProtocol: @protocol(DJReadingListQueue)];
        [_connection setExportedInterface:interface];

        [_connection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(Agent)]];
        [_connection resume];
        
        [[_connection remoteObjectProxy] wake];

        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

        __block __weak NSXPCConnection* weakConnection = _connection;
        _connection.interruptionHandler = ^{

            NSLog(@"interrupted");
            [[weakConnection remoteObjectProxy] wake];

        };

    }
    return self;
}



- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void) websocketConnected {

    NSUserNotification *note = [NSUserNotification new];
    note.title = @"Connected to Red Server";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];

}

- (void) addReadingListItemWithInfoDictionary: (NSDictionary *) dict {

    
    ReadingListItem *item = [ReadingListItem readingListItemWithDefaultContext];
    item.urlString = dict[@"url"];
    item.referrer = dict[@"referrer"];
    item.title = dict[@"title"];

    NSBlockOperation *findDuplicate = [NSBlockOperation blockOperationWithBlock:^{

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReadingListItem"];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"urlString == %@", item.urlString];

        [request setPredicate:pred];
        NSError *error;
        NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];

        if (count > 1) {


            [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                [NSApp activateIgnoringOtherApps:YES];
                NSAlert *alert = [NSAlert alertWithMessageText:@"Duplicate Item Added."
                                                 defaultButton:@"Delete it"
                                               alternateButton:@"Keep it"
                                                   otherButton:nil
                                     informativeTextWithFormat:@"%@ (from %@).", item.title, item.url.host];

                if ([alert runModal] == NSOKButton) {

                    [self.managedObjectContext deleteObject:item];
                    
                    
                }
                
            }];
            
        }
        
        
        
    }];

    [_queue addOperation:findDuplicate];
   
    NSURLRequest *request = [NSURLRequest requestWithURL:item.url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [op addDependency:findDuplicate];


    

    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {

        if (item.managedObjectContext == nil) //item is deleted
        {
            return;
        }
        NSString *mimeType = operation.response.MIMEType;

        CFStringRef MIMEType = (__bridge CFStringRef)mimeType;
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, NULL);
        NSString *UTIString = (__bridge_transfer NSString *)UTI;

        if ([[NSWorkspace sharedWorkspace] type:UTIString conformsToType:@"public.html"]) {

            NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData:responseObject options:NSXMLDocumentTidyHTML error:nil];
            NSString *title = [[[doc nodesForXPath:@"//title/text()" error:nil] lastObject] stringValue];

            if ([title length] > 0) {
                item.title = title;
            }

        } else {
            
            NSArray *parts = [item.urlString componentsSeparatedByString:@"/"];
            NSString *filename = [parts objectAtIndex:[parts count]-1];

            item.title = filename;


        }
        
        NSLog(@"success: %@", item.title);

        NSUserNotification *note = [NSUserNotification new];
        note.title = [NSString stringWithFormat:@"Added: '%@'", item.title];
        note.informativeText = [NSString stringWithFormat:@"From %@ (via %@).", item.url.host, item.referrerURL.host];
        note.actionButtonTitle = @"Close";

        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];




    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"fail: %@", [error localizedDescription]);

        
    }];

    


    [self.queue addOperation:op];


}


- (void) readItems {

    //look for the prize 'readArticles' before Proceeding

    ThingsApplication *things = [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
    ThingsTag *readArticlesTag = [[things tags] objectWithName:@"readArticles"];
    SBElementArray *todos = [readArticlesTag.toDos copy];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == %@", [NSAppleEventDescriptor descriptorWithEnumCode:ThingsStatusOpen]];

    NSSortDescriptor *dueDateSD = [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES];

    [todos filterUsingPredicate:pred];
    NSArray *sortedResults = [todos sortedArrayUsingDescriptors:@[dueDateSD]];


    if ([sortedResults count] == 0) {

        [NSApp activateIgnoringOtherApps:YES];
        NSRunAlertPanel(@"Prize Requirement",
                        @"You must have a 'readArticles' prize before you can proceed.",
                        @"Dismiss", nil, nil);

        return;
    }

    ThingsToDo *readArticlesPrize = [[sortedResults objectAtIndex:0] get];
    [readArticlesPrize setStatus:ThingsStatusCompleted];


    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReadingListItem"];
    
    pred = [NSPredicate predicateWithFormat:@"isRead == NO"];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:YES];

    request.predicate = pred;
    request.sortDescriptors = @[sd];
    request.fetchLimit = 50;

    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    NSArray *subresults = [results sample:10];
    
    [self openURLsInSafari:[subresults valueForKey:@"url"]];

    //mark as read the items fetched
    [subresults makeObjectsPerformSelector:@selector(markAsRead)];

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
    if (self.isCountingdown) return;

    //look for the prize 'buildReadingList' before Proceeding

    ThingsApplication *things = [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
    ThingsTag *buildReadingListTag = [[things tags] objectWithName:@"buildReadingList"];
    SBElementArray *todos = [buildReadingListTag.toDos copy];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == %@", [NSAppleEventDescriptor descriptorWithEnumCode:ThingsStatusOpen]];

    NSSortDescriptor *dueDateSD = [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES];

    [todos filterUsingPredicate:pred];

    NSArray *sortedResults = [todos sortedArrayUsingDescriptors:@[dueDateSD]];

    if ([sortedResults count] == 0) {

        [NSApp activateIgnoringOtherApps:YES];
        NSRunAlertPanel(@"Prize Requirement",
                        @"You must have a 'buildReadingList' prize before you can proceed.",
                        @"Dismiss", nil, nil);

        return;
    } 
    ThingsToDo *buildReadingListPrize = [[sortedResults objectAtIndex:0] get];

    [buildReadingListPrize setStatus:ThingsStatusCompleted];



    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"LinkRollSite"];
    NSMutableArray *sites = [NSMutableArray array];

    //Important
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group == %@", @"Important"];
    [request setPredicate:predicate];
    [request setFetchLimit:0];
    [sites addObjectsFromArray:[self.managedObjectContext executeFetchRequest:request error:nil]];

    //News
    predicate = [NSPredicate predicateWithFormat:@"group == %@", @"News"];
    [request setPredicate:predicate];

    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"lastDateAccessed" ascending:YES];
    [request setSortDescriptors:@[sd]];

    [request setFetchLimit:3];
    [sites addObjectsFromArray:[self.managedObjectContext executeFetchRequest:request error:nil]];

    // General
    predicate = [NSPredicate predicateWithFormat:@"group == %@", @"General"];
    [request setPredicate:predicate];

    /*

     NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"lastDateAccessed" ascending:YES];
     [request setSortDescriptors:@[sd]];*/

    [request setFetchLimit:5];

    [sites addObjectsFromArray:[self.managedObjectContext executeFetchRequest:request error:nil]];
    //open
    [self openURLsInSafari:[sites valueForKey:@"url"]];
    //mark as read
    [sites makeObjectsPerformSelector:@selector(read)];



    [self startCountdown];




    
}

- (void) startCountdown {

    self.isCountingdown = YES;

    remainingTicks = 30 * 60; //30 minute

    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(tick)
                                                     userInfo:nil
                                                      repeats:YES];

    [[NSRunLoop currentRunLoop]  addTimer:_countdownTimer forMode:NSEventTrackingRunLoopMode];


    
}


- (void) tick {

    remainingTicks--;

    DJAppDelegate *appDelegate = (DJAppDelegate *)[NSApp delegate];
    NSStatusItem *item = appDelegate.statusItem;

    if (remainingTicks > 0) {

        NSUInteger seconds = remainingTicks % 60;
        NSUInteger minutes = (remainingTicks - seconds) / 60;

        item.title = [NSString stringWithFormat:@"%.2lu:%.2lu", minutes, seconds];
        

        

    } else {

        [_countdownTimer invalidate];
        _countdownTimer = nil;
        NSRunAlertPanel(@"RED", @"Please stop.", @"Done", nil, nil);
        item.title = @"RED";
        self.isCountingdown = NO;
        
    }
}

- (void) viewOnlinePorn {

    if (self.isCountingdown) return;

    //look for the prize 'buildReadingList' before Proceeding

    ThingsApplication *things = [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
    ThingsTag *viewOnlinePorn = [[things tags] objectWithName:@"viewOnlinePorn"];
    SBElementArray *todos = [viewOnlinePorn.toDos copy];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == %@", [NSAppleEventDescriptor descriptorWithEnumCode:ThingsStatusOpen]];

    NSSortDescriptor *dueDateSD = [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES];

    [todos filterUsingPredicate:pred];

    NSArray *sortedResults = [todos sortedArrayUsingDescriptors:@[dueDateSD]];


    if ([sortedResults count] == 0) {

        [NSApp activateIgnoringOtherApps:YES];
        NSRunAlertPanel(@"Prize Requirement",
                        @"You must have a 'viewOnlinePorn' prize before you can proceed.",
                        @"Dismiss", nil, nil);

        return;
    }

    ThingsToDo *viewOnlinePornPrize = [[sortedResults objectAtIndex:0] get];
    [viewOnlinePornPrize setStatus:ThingsStatusCompleted];

    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"LinkRollSite"];

    //Porn
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group == %@", @"Porn"];
    [request setPredicate:predicate];
    [request setFetchLimit:5];


    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"lastDateAccessed" ascending:YES];
    [request setSortDescriptors:@[sd]];


    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    

    [self openURLsInSafari:[results valueForKey:@"url"]];
    //mark as read
    [results makeObjectsPerformSelector:@selector(read)];

    [self startCountdown];

    // countdown
    // prizes
}
@end
