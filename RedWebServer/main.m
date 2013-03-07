//
//  main.m
//  f
//
//  Created by Earl on 3/6/13.
//
//

#include <Foundation/Foundation.h>
#import "ListenerDelegate.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

int main(int argc, const char *argv[])
{



    ListenerDelegate *delegate = [[ListenerDelegate alloc] init];

    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;

    [listener resume];
    return 0;

    
}
