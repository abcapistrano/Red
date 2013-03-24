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
#import "Things.h"
#import "NSDate+MoreDates.h"
#import "MTRandom.h"
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


//- (void) awakeFromNib {
//
//    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReadingListItem"];
//    NSPredicate* predicate2 = [NSPredicate predicateWithFormat:@"isRead == NO"];
//    request.predicate = predicate2;
//
//    MTRandom *rand = [[MTRandom alloc] init];
//
//    NSDateComponents *dc = [NSDateComponents new];
//    dc.month = 1; 
//    dc.day = 1;
//    dc.year = 2013;
//    dc.hour = 0;
//    dc.minute = 0;
//    dc.second = 0;
//    dc.calendar = [NSCalendar currentCalendar];
//
//    NSTimeInterval startTimeInterval = [dc.date timeIntervalSinceReferenceDate];
//    NSTimeInterval max = 80 * 24 * 60 * 60; // 90 days, 24 hours, 60 minutes, 60 seconds
//
//    [[self.managedObjectContext executeFetchRequest:request error:nil] enumerateObjectsUsingBlock:^(ReadingListItem* item, NSUInteger idx, BOOL *stop) {
//        NSTimeInterval randomInterval = (NSTimeInterval)[rand randomUInt32From:0 to:max] + startTimeInterval;
//        item.dateAdded = [NSDate dateWithTimeIntervalSinceReferenceDate:randomInterval];
//        NSLog(@"%lu %@",idx, item.dateAdded);
//    }];
//
//    [[NSApp delegate] saveAction:self];
//
//
//
//
//}

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

#ifdef RELEASE
    if (![self consumePrizeWithTag:@"readArticles"]) return;
#endif
    
/*
 Objective: Get articles from 10 different dates to add variety to your reading experience
 
 */

    // fetch dates





    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ReadingListItem" inManagedObjectContext:self.managedObjectContext];

    request.entity = entity;
    request.propertiesToFetch = @[[entity propertiesByName][@"dateAdded"]];
    request.returnsDistinctResults = YES;
    request.resultType = NSDictionaryResultType;

    NSPredicate* predicate2 = [NSPredicate predicateWithFormat:@"isRead == NO"];
    request.predicate = predicate2;

    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:YES];
    request.sortDescriptors = @[sd];
    request.includesPendingChanges = YES;

    //request.fetchLimit = countOfLinksToShow;

    NSArray *dates = [[self.managedObjectContext executeFetchRequest:request error:nil] valueForKeyPath:@"dateAdded.dateJustBeforeMidnight"];
    NSOrderedSet *set = [NSOrderedSet orderedSetWithArray:dates];
    dates = [set array];

    

    NSUInteger countOfLinksToShow = 10;
    if ([dates count] < countOfLinksToShow) {

        NSRunAlertPanel(@"Highly Unlikely Error", @"It seems that not enough dates are available. Fix that.", @"Dismiss", nil, nil);
        return;
    }


    NSRange tophalf, bottomhalf;
    tophalf.location = 0;
    tophalf.length = [dates count]/2;

    bottomhalf.location = tophalf.length;
    bottomhalf.length = [dates count] - tophalf.length;
    
    NSMutableArray *earliestDates = [[dates subarrayWithRange:tophalf] mutableCopy];
    NSMutableArray *latestDates = [[dates subarrayWithRange:bottomhalf] mutableCopy];
    

    NSMutableArray *datesToShow = [NSMutableArray arrayWithCapacity:countOfLinksToShow];

    
    MTRandom *random = [MTRandom new];

    do {

        NSUInteger randomNumber = [random randomUInt32From:1 to:10];

        if (randomNumber < 9) { //if the number falls between 1-8 we get from the earliestDates to favor such dates

            [datesToShow addObject:[[earliestDates grab:1] lastObject]];

        } else {

            [datesToShow addObject:[[latestDates grab:1] lastObject]];


        }


    } while ([datesToShow count] != countOfLinksToShow);
   
        NSMutableArray *itemsToOpen = [NSMutableArray array];

        NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"dateAdded >= $startDate AND dateAdded <= $endDate"];
        NSFetchRequest *request2 = [[NSFetchRequest alloc] initWithEntityName:@"ReadingListItem"];

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];

        [datesToShow enumerateObjectsWithOptions:0 usingBlock:^(NSDate* midnightDate, NSUInteger idx, BOOL *stop) {

            NSPredicate *customDatePredicate = [datePredicate predicateWithSubstitutionVariables:@{@"startDate":midnightDate.dateAtDawn, @"endDate":midnightDate}];
            request2.predicate = customDatePredicate;
            request2.fetchLimit = 10;

            NSArray *results = [self.managedObjectContext executeFetchRequest:request2 error:nil];

            ReadingListItem *randomResult = [[results sample:1] lastObject];
            [itemsToOpen addObject:randomResult];






        }];



    [self openURLsInSafari:[itemsToOpen valueForKey:@"url"]];

#ifdef RELEASE
        [itemsToOpen makeObjectsPerformSelector:@selector(markAsRead)];
#endif




}

- (void) openURLsInSafari: (NSArray *) urls {

    SafariApplication *safari = [SBApplication applicationWithBundleIdentifier:@"com.apple.Safari"];
    [safari activate];
    
    SafariDocument *doc = [[safari classForScriptingClass:@"document"] new];
    [safari.documents addObject:doc];

    SafariWindow *window = [safari.windows objectAtIndex:0];

    Class tabClass = [safari classForScriptingClass:@"tab"];
    [urls enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {

        SafariTab *tab = [tabClass new];
        [window.tabs addObject:tab];
        tab.URL = url.absoluteString;

        
        
    }];

    //close the first tab coz its fake
    [[window.tabs objectAtIndex:0] closeSaving:0 savingIn:nil];

    
}



- (NSManagedObjectContext *) managedObjectContext {
    return [[NSApp delegate] managedObjectContext];
}

- (BOOL) consumePrizeWithTag:(NSString *) tag {

    


    ThingsApplication *things = [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
    ThingsTag *prizeTag = [[things tags] objectWithName:tag];
    SBElementArray *todos = [prizeTag.toDos copy];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == %@", [NSAppleEventDescriptor descriptorWithEnumCode:ThingsStatusOpen]];

    NSSortDescriptor *dueDateSD = [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES];

    [todos filterUsingPredicate:pred];

    NSArray *sortedResults = [todos sortedArrayUsingDescriptors:@[dueDateSD]];

    if ([sortedResults count] == 0) {

        [NSApp activateIgnoringOtherApps:YES];

        NSRunAlertPanel(@"Prize Requirement",
                        [NSString stringWithFormat:@"You must have a '%@' prize before you can proceed.", tag],
                        @"Dismiss",
                        nil,
                        nil);

        return NO;
    } else {

        NSInteger result = NSRunAlertPanel(@"Prize Requirement",
                        [NSString stringWithFormat:@"Are you sure that you want to use a '%@' prize?", tag],
                        @"Go Ahead",
                        @"Dismiss",
                        nil);

        
        if (result == NSAlertDefaultReturn) {
            ThingsToDo *prize = [[sortedResults objectAtIndex:0] get];
            [prize setStatus:ThingsStatusCompleted];
            return YES;
        } else {
            
            return NO;
            
        }

        
        
    }


    
}

- (void) buildReadingList {
    if (self.isCountingdown) return;
#ifdef RELEASE

    if (![self consumePrizeWithTag:@"buildReadingList"]) return;
#endif


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

#ifdef  RELEASE
    [sites makeObjectsPerformSelector:@selector(read)];
#endif


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
#ifdef RELEASE
    if (![self consumePrizeWithTag:@"viewOnlinePorn"]) return;
#endif
     
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"LinkRollSite"];

    //Porn
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group == %@", @"Porn"];
    [request setPredicate:predicate];
    [request setFetchLimit:3];


    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"lastDateAccessed" ascending:YES];
    [request setSortDescriptors:@[sd]];


    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    

    [self openURLsInSafari:[results valueForKey:@"url"]];
    //mark as read
#ifdef RELEASE
    [results makeObjectsPerformSelector:@selector(read)];
#endif

    [self startCountdown];

}
@end
