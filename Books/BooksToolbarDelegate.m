/*
   Copyright (c) 2007 Chris J. Karr

   Permission is hereby granted, free of charge, to any person 
   obtaining a copy of this software and associated documentation 
   files (the "Software"), to deal in the Software without restriction, 
   including without limitation the rights to use, copy, modify, merge, 
   publish, distribute, sublicense, and/or sell copies of the Software, 
   and to permit persons to whom the Software is furnished to do so, 
   subject to the following conditions:

   The above copyright notice and this permission notice shall be 
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
   SOFTWARE.
*/


#import "BooksToolbarDelegate.h"

@implementation BooksToolbarDelegate

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:@"new-list", @"new-smartlist", @"edit-smartlist", @"new-book", @"remove-book", @"remove-list", @"view-inspector", 
		@"get-info", @"get-cover", @"import", @"search", @"isight", @"duplicate", @"views", NSToolbarSeparatorItemIdentifier, 
		NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:@"views", @"new-book", @"new-list", @"new-smartlist", @"view-inspector",  
	NSToolbarFlexibleSpaceItemIdentifier, @"search", nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar itemForItemIdentifier: (NSString *) itemIdentifier willBeInsertedIntoToolbar: (BOOL) flag
{
	NSToolbarItem * item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	[item setLabel:itemIdentifier];
	
	if ([itemIdentifier isEqualToString:@"new-list"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"newList:")];

		[item setImage:[NSImage imageNamed:@"new-list"]];
		[item setLabel:NSLocalizedString (@"New List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"New List", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"new-smartlist"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"newSmartList:")];

		[item setImage:[NSImage imageNamed:@"new-smartlist"]];
		[item setLabel:NSLocalizedString (@"New Smart List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"New Smart List", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"edit-smartlist"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"editSmartList:")];

		[item setImage:[NSImage imageNamed:@"edit-smartlist"]];
		[item setLabel:NSLocalizedString (@"Edit Smart List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Edit Smart List", nil)];
		
		editSmartList = item;
	}
	else if ([itemIdentifier isEqualToString:@"remove-list"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"removeList:")];

		[item setImage:[NSImage imageNamed:@"remove-list"]];
		[item setLabel:NSLocalizedString (@"Remove List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Remove List", nil)];

		removeList = item;
	}
	else if ([itemIdentifier isEqualToString:@"remove-book"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"removeBook:")];

		[item setImage:[NSImage imageNamed:@"remove-book"]];
		[item setLabel:NSLocalizedString (@"Remove Book", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Remove Book", nil)];

		removeBook = item;
	}
	else if ([itemIdentifier isEqualToString:@"new-book"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"newBook:")];

		[item setImage:[NSImage imageNamed:@"new-book"]];
		[item setLabel:NSLocalizedString (@"New Book", nil)];
		[item setPaletteLabel:NSLocalizedString (@"New Book", nil)];

		newBook = item;
	}
	else if ([itemIdentifier isEqualToString:@"view-inspector"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"showViewControls:")];

		[item setImage:[NSImage imageNamed:@"controls"]];
		[item setLabel:NSLocalizedString (@"View Inspector", nil)];
		[item setPaletteLabel:NSLocalizedString (@"View Inspector", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"get-info"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"getInfoWindow:")];

		[item setImage:[NSImage imageNamed:@"get-info"]];
		[item setLabel:NSLocalizedString (@"Get Info", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Get Info", nil)];
		
		getInfo = item;
	}
	else if ([itemIdentifier isEqualToString:@"get-cover"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"getCoverWindow:")];

		[item setImage:[NSImage imageNamed:@"get-cover"]];
		[item setLabel:NSLocalizedString (@"Show Cover", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Show Cover", nil)];
		
		getCover = item;
	}
	else if ([itemIdentifier isEqualToString:@"import"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"import:")];

		[item setImage:[NSImage imageNamed:@"import"]];
		[item setLabel:NSLocalizedString (@"Import Data", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Import Data", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"isight"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"isight:")];

		[item setImage:[NSImage imageNamed:@"camera"]];
		[item setLabel:NSLocalizedString (@"Open Camera", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Open Camera", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"duplicate"])
	{
		[item setTarget:booksAppDelegate];
		[item setAction:NSSelectorFromString(@"duplicateRecords:")];

		[item setImage:[NSImage imageNamed:@"dupe"]];
		[item setLabel:NSLocalizedString (@"Duplicate Book", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Duplicate Book", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"search"])
	{
		NSRect fRect = [searchField frame];
		[item setView:searchField];

		[item setMinSize:fRect.size];
		[item setMaxSize:fRect.size];
		
		[item setLabel:NSLocalizedString (@"Search Selected List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Search Selected List", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"views"])
	{
		NSRect fRect = [viewsField frame];
		[item setView:viewsField];

		[item setMinSize:fRect.size];
		[item setMaxSize:fRect.size];
		
		[item setLabel:NSLocalizedString (@"View", nil)];
		[item setPaletteLabel:NSLocalizedString (@"View", nil)];
	}
	
	return [item autorelease];
}

- (void) dealloc
{
	[super dealloc];
}

- (void) setGetCoverLabel:(NSString *) label
{
	[getCover setLabel:label];
}

- (void) setGetInfoLabel:(NSString *) label
{
	[getInfo setLabel:label];
}

- (void) setNewBookAction:(SEL) action
{
	[newBook setAction:action];
}

- (void) setRemoveBookAction:(SEL) action;
{
	[removeBook setAction:action];
}

- (void) setEditSmartListAction:(SEL) action;
{
	[editSmartList setAction:action];
}

- (void) setRemoveListAction:(SEL) action;
{
	[removeList setAction:action];
}

- (void) setGetCoverAction:(SEL) action;
{
	[getCover setAction:action];
}

- (void) cancelSearch
{
	[[[searchTextField cell] cancelButtonCell] performClick:self];
}

@end
