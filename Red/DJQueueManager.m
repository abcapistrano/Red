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


   

    NSURLRequest *request = [NSURLRequest requestWithURL:item.url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {

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
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReadingListItem"];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isRead == NO"];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:YES];

    request.predicate = pred;
    request.sortDescriptors = @[sd];
    request.fetchLimit = 50;

    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    NSArray *subresults = [results sample:5];
    
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








    
}


@end
