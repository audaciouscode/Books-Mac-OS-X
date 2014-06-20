//
//  BooksCreateNewListCommand.m
//  Books
//
//  Created by Chris Karr on 10/22/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BooksCreateNewListCommand.h"
#import "BooksAppDelegate.h"

@implementation BooksCreateNewListCommand

- (id) performDefaultImplementation
{
	NSDictionary * args = [self evaluatedArguments];
	NSLog (@"eval args %@", args);
	
	NSString * listName = nil;
	
	if ([args objectForKey:@"called"] != nil)
		listName = [args objectForKey:@"called"];


	ListManagedObject * obj = [(BooksAppDelegate *) [[NSApplication sharedApplication] delegate] 
								asCreateNewList:listName];

	return [obj objectSpecifier];
	
	// return obj;
}

@end
