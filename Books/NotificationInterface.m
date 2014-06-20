//
//  NotificationInterface.m
//  Books
//
//  Created by Chris Karr on 6/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NotificationInterface.h"

@implementation NotificationInterface

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	
	NSArray * all = [NSArray arrayWithObjects:NSLocalizedString (@"Lookup Complete", nil), 
					NSLocalizedString (@"Import Complete", nil), NSLocalizedString (@"Export Complete", nil), nil];
	NSArray * def = [NSArray arrayWithObjects:NSLocalizedString (@"Lookup Complete", nil),
					NSLocalizedString (@"Import Complete", nil), NSLocalizedString (@"Export Complete", nil), nil];
	
	[dict setValue:all forKey:GROWL_NOTIFICATIONS_ALL];
	[dict setValue:def forKey:GROWL_NOTIFICATIONS_DEFAULT];
	
	return dict;
}

- (NSString *) applicationNameForGrowl
{
	return @"Books";
}

+ (void) sendMessage:(NSString *) message withTitle:(NSString *) title
{
		[GrowlApplicationBridge
			notifyWithTitle:title
			description:message
			notificationName:title
			iconData:nil
			priority:0
			isSticky:NO
			clickContext:nil];
}

+ (void) start
{
	NotificationInterface * notify = [[NotificationInterface alloc] init];
	[GrowlApplicationBridge setGrowlDelegate:notify];
	[notify release];
}

@end
