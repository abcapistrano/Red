//
//  DJReadingListController.m
//  Red
//
//  Created by Earl on 2/24/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "DJReadingListController.h"
#import "DJAppDelegate.h"
@interface DJReadingListController ()

@end

@implementation DJReadingListController
- (id)init
{
    self = [super initWithWindowNibName:@"DJReadingListController" owner:self];
    if (self) {
        _dateSort = @[[NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:NO]];

    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void) menuWillOpen:(NSMenu *)menu {
    // reconfigure selection
    NSInteger theClickedRow = [self.tableView   clickedRow];
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:theClickedRow];
    [self.tableView selectRowIndexes:thisIndexSet byExtendingSelection:YES];
    
}


@end
