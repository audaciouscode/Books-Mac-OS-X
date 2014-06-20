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


#import "ListListArrayController.h"
#import "SmartList.h""
#import "BooksAppDelegate.h"

@implementation ListListArrayController

- (BOOL)tableView:(NSTableView *)tv
		writeRows:(NSArray*)rows
	 toPasteboard:(NSPasteboard*)pboard
{
	return NO;
}

- (NSDragOperation) tableView:(NSTableView*) tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row
	proposedDropOperation:(NSTableViewDropOperation) op
{
	if (row < 0)
		row = 0;
	if (row >= [[self arrangedObjects] count])
		row = [[self arrangedObjects] count] - 1;

	ListManagedObject * list = [[self arrangedObjects] objectAtIndex:row];
	
	if ([list isKindOfClass:[SmartList class]])
		return NSDragOperationNone;
		
    [tv setDropRow:row dropOperation:NSTableViewDropOn];

	return NSDragOperationMove;
}

- (BOOL) tableView:(NSTableView *) tableView acceptDrop:(id <NSDraggingInfo>) info row:(int) row 
	dropOperation:(NSTableViewDropOperation) operation
{
	ListManagedObject * list = [[self arrangedObjects] objectAtIndex:row];
	
	NSManagedObjectContext * context = [list managedObjectContext];
	
	[context lock];
	NSMutableSet * items = [list mutableSetValueForKey:@"items"];
	
	NSArray * array = [[info draggingPasteboard] propertyListForType:@"Books Book Type"];
	
	int i = 0;
	for (i = 0; i < [array count]; i++)
	{
		NSURL * book = [NSURL URLWithString:[array objectAtIndex:i]];

		NSManagedObjectID * objectId = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:book];

		if (objectId != nil)
		{
			BookManagedObject * object = (BookManagedObject *) [context objectWithID:objectId];

			[items addObject:object];
		}
	}

	[context unlock];
	
	return YES;
}

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	return [[self arrangedObjects] count];
}

@end
