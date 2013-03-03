//
//  DJReadingListController.h
//  Red
//
//  Created by Earl on 2/24/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DJReadingListController : NSWindowController <NSMenuDelegate>
@property (readonly) NSArray *dateSort;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSArrayController *arrayController;
- (IBAction) markAsUnread: (id) sender;
@end
