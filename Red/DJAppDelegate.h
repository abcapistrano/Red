//
//  DJAppDelegate.h
//  Red
//
//  Created by Earl on 2/19/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DJReadingListController;
@class DJQueueManager;
@interface DJAppDelegate : NSObject <NSApplicationDelegate> {

    DJReadingListController *readingListController;
    DJQueueManager *queueManager;
    

}

@property (weak) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *statusMenu;
@property (strong) id observer;


- (IBAction)saveAction:(id)sender;
- (void) activateStatusMenu;
- (IBAction) importReadingListItems :(id)sender;
- (IBAction) readItems:(id)sender;
- (IBAction) buildReadingList:(id)sender;
- (IBAction) showReadingList:(id)sender;

@end
