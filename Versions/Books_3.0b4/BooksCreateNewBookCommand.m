//
//  BooksCreateNewBookCommand.m
//  Books
//
//  Created by Chris Karr on 10/23/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BooksCreateNewBookCommand.h"


@implementation BooksCreateNewBookCommand

- (id) performDefaultImplementation
{
	NSDictionary * args = [self evaluatedArguments];
	NSLog (@"eval args %@", args);
	
//	NSString * listName = nil;
	
//	if ([args objectForKey:@"called"] != nil)
//		listName = [args objectForKey:@"called"];


//	ListManagedObject * obj = [(BooksAppDelegate *) [[NSApplication sharedApplication] delegate] 
//								asCreateNewList:listName];

//	return [obj objectSpecifier];

	return nil;
	// return obj;
}

@end
