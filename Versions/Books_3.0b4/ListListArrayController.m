//
//  ListListArrayController.m
//  Books
//
//  Created by Chris Karr on 10/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

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
