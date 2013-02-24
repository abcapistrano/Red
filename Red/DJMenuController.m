//
//  DJMenuController.m
//  Red
//
//  Created by Earl on 2/24/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "DJMenuController.h"

@implementation DJMenuController
- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item {
    NSString *title = [item title];
    if ([title isEqualToString:@"Recently Added"]) {




        
    }

    NSLog(@"highlighting");
}

- (void)menuWillOpen:(NSMenu *)menu {
    NSLog(@"open");

}

- (void) menuDidClose:(NSMenu *)menu {
    NSLog(@"close");
}
@end
