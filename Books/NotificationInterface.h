//
//  NotificationInterface.h
//  Books
//
//  Created by Chris Karr on 6/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

@interface NotificationInterface : NSObject <GrowlApplicationBridgeDelegate>
{

}

- (NSDictionary *) registrationDictionaryForGrowl;
- (NSString *) applicationNameForGrowl;

+ (void) sendMessage:(NSString *) message withTitle:(NSString *) title;
+ (void) start;

@end
