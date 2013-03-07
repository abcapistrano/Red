//
//  ListenerDelegate.m
//  Red
//
//  Created by Earl on 3/6/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "ListenerDelegate.h"
#import "DJReadingListQueue.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "DDLog.h"
#import "DDTTYLogger.h"


@implementation ListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {

    // SET UP NSXPCConnection


    // Configure our logging framework.
	// To keep things simple and fast, we're just going to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];

	// Create server using our custom MyHTTPServer class
	httpServer = [[HTTPServer alloc] init];

	// Tell server to use our custom MyHTTPConnection class.
	[httpServer setConnectionClass:[MyHTTPConnection class]];

	// Tell the server to broadcast its presence via Bonjour.
	// This allows browsers such as Safari to automatically discover our service.
	[httpServer setType:@"_http._tcp."];

	// Normally there's no need to run our server on any specific port.
	// Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
	// However, for easy testing you may want force a certain port so you can just hit the refresh button.


    // NSNumber *selectedPort= [[@[@52791, @52794, @52797, @52800, @52803] sample:1] lastObject];

    //[httpServer setPort:[selectedPort integerValue]];
    [httpServer setPort:49803];
	// Serve files from our embedded Web folder
	NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
	NSLog(@"Setting document root: %@", webPath);

	[httpServer setDocumentRoot:webPath];

	// Start the server (and check for problems)

	NSError *error;
	if(![httpServer start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}
 


    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(DJReadingListQueue)];
    newConnection.exportedObject = self;
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(Agent)];

    connection = newConnection;
    [newConnection resume];


    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    observer1 = [nc addObserverForName:@"WebsocketConnected"
                                object:nil
                                 queue:[NSOperationQueue mainQueue]
                            usingBlock:^(NSNotification *note) {
                                NSLog(@"websocket connected");
                                [[connection remoteObjectProxy] websocketConnected];

                                                                 
}];

    observer2 = [[NSNotificationCenter defaultCenter] addObserverForName:@"MessageReceived"
                                                                  object:nil
                                                                   queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) {
                                                                      NSLog(@"message received");

                                                                  NSDictionary *userInfo = [note userInfo];

                                                                  NSString *command = userInfo[@"command"];
                                                                  NSDictionary *payload = userInfo[@"payload"];

                                                                  if ([command isEqualToString:@"addReadingListItem"]) {

                                                                      [[connection remoteObjectProxy] addReadingListItemWithInfoDictionary:payload];
                                                                      NSBeep();

                                                                      
                                                                  }

                                                                  }];




    return YES;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:observer1];
    [[NSNotificationCenter defaultCenter] removeObserver:observer2];

}

- (void) wake {
    NSLog(@"connection is awaken");

}
@end
