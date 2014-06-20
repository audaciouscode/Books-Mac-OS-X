//
//  MainWindowTableView.m
//  Books
//
//  Created by Chris Karr on 10/15/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MainWindowTableView.h"
#import "BooksAppDelegate.h"

@implementation MainWindowTableView

- (void) keyDown: (NSEvent *) event
{
	unichar arrow = [[event characters] characterAtIndex:0];
	
	if (arrow == NSLeftArrowFunctionKey)
		[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) selectListsTable:self];
	else if (arrow == NSRightArrowFunctionKey)
		[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) selectBooksTable:self];
	// else if (arrow == ' ')
	//	[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) pageContent:self];
	else
		[super keyDown:event];
}
@end
