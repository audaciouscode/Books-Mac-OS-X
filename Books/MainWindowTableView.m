/*
   Copyright (c) 2006 Chris J. Karr

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


#import "MainWindowTableView.h"
#import "BooksAppDelegate.h"
#import "ListManagedObject.h"
#import "SmartListManagedObject.h"

@implementation MainWindowTableView

- (void) keyDown: (NSEvent *) event
{
	unichar arrow = [[event characters] characterAtIndex:0];
	
	if (self == [[self delegate] getListsTable])
	{
		if (arrow == NSBackspaceCharacter || arrow == NSDeleteCharacter)
		{
			[[NSApp delegate] removeList:nil];
		}
		else
			[super keyDown:event];
	}
	else if (self == [[self delegate] getBooksTable])
	{
		if (arrow == 13 || arrow == 3)
		{
			NSNotification * notification = [NSNotification notificationWithName:BOOKS_SHOW_INFO object:nil];
			[[NSNotificationCenter defaultCenter] postNotification:notification];
		}
		else if (arrow == NSBackspaceCharacter || arrow == NSDeleteCharacter)
		{
			[[NSApp delegate] removeBook:nil];
		}
		else
			[super keyDown:event];
	}
}

- (void) updateRowSize
{
	BOOL smallFonts = [[NSUserDefaults standardUserDefaults] boolForKey:@"Use Small Table Fonts"];

	if (smallFonts)
		[self setRowHeight:14];
	else
		[self setRowHeight:17];

	NSArray * columns = [self tableColumns];

	int i = 0;
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
		
		if (smallFonts)
			[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
		else
			[[column dataCell] setFont:[NSFont systemFontOfSize:12]];
	}
}

- (void) addTableColumn:(NSTableColumn *) aColumn
{
	[super addTableColumn:aColumn];
	[self updateRowSize];
}

- (void) awakeFromNib
{
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Use Small Table Fonts" options:NSKeyValueObservingOptionNew context:NULL];

	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"Use Small Table Fonts"] == nil)
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Use Small Table Fonts"];
	
	[self updateRowSize];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"Use Small Table Fonts"])
		[self updateRowSize];
}

- (NSMenu *) menuForEvent:(NSEvent *)theEvent
{
	if (self == [[self delegate] getListsTable])
	{
		// Code from http://lists.apple.com/archives/Cocoa-dev/2003/Aug/msg01442.html
	
		int row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];

		if (row != -1) 
			[self selectRow:row byExtendingSelection: NO];

		NSMenu * menu = [[NSMenu alloc] init];

		if ([self numberOfSelectedRows] > 0 && row != -1)
		{
			ListManagedObject * obj = [[[self dataSource] arrangedObjects] objectAtIndex:row];
			if ([obj isKindOfClass:[SmartListManagedObject class]])
				[menu addItemWithTitle:NSLocalizedString (@"Edit Smart List", nil) action:NSSelectorFromString(@"editSmartList:") keyEquivalent:@""];

			[menu addItemWithTitle:NSLocalizedString (@"Rename List", nil) action:NSSelectorFromString(@"renameList:") keyEquivalent:@""];
			[menu addItemWithTitle:NSLocalizedString (@"Delete List", nil) action:NSSelectorFromString(@"deleteList:") keyEquivalent:@""];

			[menu addItem:[NSMenuItem separatorItem]];
		}

		[menu addItemWithTitle:NSLocalizedString (@"New List", nil) action:NSSelectorFromString(@"newList:") keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString (@"New Smart List", nil) action:NSSelectorFromString(@"newSmartList:") keyEquivalent:@""];
		
		return menu;
	}
	else if (self == [[self delegate] getBooksTable])
	{
		int row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];

		if (row != -1) 
		{
			if (![self isRowSelected:row])
				[self selectRow:row byExtendingSelection: NO];
		}

		ListManagedObject * obj = [[[[[self delegate] getListsTable] dataSource] selectedObjects] objectAtIndex:0];

		NSMenu * menu = [[NSMenu alloc] init];

		if ([obj isKindOfClass:[SmartListManagedObject class]])
			[menu addItemWithTitle:NSLocalizedString (@"No operations available", nil) action:nil keyEquivalent:@""];
		else
		{
		
			if ([self numberOfSelectedRows] > 0)
			{
				[menu addItemWithTitle:NSLocalizedString (@"Duplicate", nil) action:NSSelectorFromString(@"duplicateRecords:") keyEquivalent:@""];
				[menu addItemWithTitle:NSLocalizedString (@"Delete", nil) action:NSSelectorFromString(@"deleteBook:") keyEquivalent:@""];
				[menu addItem:[NSMenuItem separatorItem]];
			}

			[menu addItemWithTitle:NSLocalizedString (@"New Book", nil) action:NSSelectorFromString(@"newBook:") keyEquivalent:@""];
		}

		return menu;
	}

	return nil;
}

- (IBAction) renameList: (id) sender
{
	if (self == [[self delegate] getListsTable])
	{
		int row = [self selectedRow];

		if (row != -1) 
			[self editColumn:1 row:row withEvent:nil select:YES];
	}
}

- (IBAction) deleteList: (id) sender
{
	if (self == [[self delegate] getListsTable])
		[((BooksAppDelegate *) [NSApp delegate]) removeList:(id) sender];
}

- (IBAction) deleteBook: (id) sender
{
	if (self == [[self delegate] getBooksTable])
		[((BooksAppDelegate *) [NSApp delegate]) removeBook:(id) sender];
}

- (IBAction) editSmartList: (id) sender
{
	[((BooksAppDelegate *) [NSApp delegate]) editSmartList:(id) sender];
}

- (IBAction) duplicateRecords: (id) sender
{
	[((BooksAppDelegate *) [NSApp delegate]) duplicateRecords:(id) sender];
}

- (IBAction) newBook: (id) sender
{
	[((BooksAppDelegate *) [NSApp delegate]) newBook:(id) sender];
}

- (IBAction) newList: (id) sender
{
	[((BooksAppDelegate *) [NSApp delegate]) newList:(id) sender];
}

- (IBAction) newSmartList: (id) sender
{
	[((BooksAppDelegate *) [NSApp delegate]) newSmartList:(id) sender];
}

@end
