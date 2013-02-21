//
//  DJAppDelegate.h
//  Red
//
//  Created by Earl on 2/19/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class HTTPServer;

@interface DJAppDelegate : NSObject <NSApplicationDelegate> {

    HTTPServer *httpServer;

}

@property (weak) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
