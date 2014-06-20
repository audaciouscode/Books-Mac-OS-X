//
//  BooksCreateNewSmartListCommand.m
//  Books
//
//  Created by Chris Karr on 10/23/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BooksCreateNewSmartListCommand.h"
#import "BooksAppDelegate.h"
#import "SmartList.h"

@implementation BooksCreateNewSmartListCommand

- (id) performDefaultImplementation
{
	NSDictionary * args = [self evaluatedArguments];
	NSLog (@"eval args %@", args);
	
	NSString * listName = nil;
	
	if ([args objectForKey:@"called"] != nil)
		listName = [args objectForKey:@"called"];

	SmartList * obj = [(BooksAppDelegate *) [[NSApplication sharedApplication] delegate] 
								asCreateNewSmartList:listName];

	if ([args objectForKey:@"withrules"] != nil)
	{
		NSString * rules = [args objectForKey:@"withrules"];
		
		[obj setPredicate:[NSPredicate predicateWithFormat:rules]];
	}

	return obj;
}

@end
