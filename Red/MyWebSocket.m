#import "MyWebSocket.h"
#import "HTTPLogging.h"
#import "DJQueueManager.h"

// Log levels: off, error, warn, info, verbose
// Other flags : trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN | HTTP_LOG_FLAG_TRACE;


@implementation MyWebSocket

- (void)didOpen
{
	HTTPLogTrace();
	
	[super didOpen];

    NSUserNotification *note = [NSUserNotification new];
    note.title = @"Connected to Red Server";
    note.actionButtonTitle = @"Close";

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
}

- (void)didReceiveMessage:(NSString *)msg
{

    NSData *jsonData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    NSString *command = info[@"command"];
    NSDictionary *payload = info[@"payload"];

    if ([command isEqualToString:@"addReadingListItem"] ) {

        
        [[DJQueueManager sharedQueueManager] addReadingListItemWithInfoDictionary:payload];


        
    }
    


}

- (void)didClose
{
	HTTPLogTrace();
	
	[super didClose];
}

@end
