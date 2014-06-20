//
//  CoverImageDelegate.m
//  Books
//
//  Created by Chris Karr on 3/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CoverWindowDelegate.h"
#import "BooksAppDelegate.h"

@implementation CoverWindowDelegate

- (void) dealloc
{
	[super dealloc];
}

- (void) setTarget:(NSWindow *) window
{
	target = window;
}

- (BOOL)windowShouldClose:(id) sender
{
	[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) getCoverWindow:sender];
	
	return NO;
}

@end
