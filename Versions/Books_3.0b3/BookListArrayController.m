//
//  BookListArrayController.m
//  Books
//
//  Created by Chris Karr on 10/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BookListArrayController.h"
#import "SmartList.h""

@implementation BookListArrayController

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rows toPasteboard:(NSPasteboard*)pboard
{
	if ([[listController selectedObjects] count] != 1)
		return NO;

	selectedRows = rows;
	
	NSString * type = @"Books Book Type";
    NSArray * typesArray = [NSArray arrayWithObjects:type, nil];
	
	[pboard declareTypes:typesArray owner:self];

    return YES;
}

- (void) addObjects: (NSArray *) objects
{
	[super addObjects:objects];
}

- (void) pasteboard:(NSPasteboard *) pboard provideDataForType:(NSString *) type
{
	if ([type isEqualTo:@"Books Book Type"])
	{
		NSMutableArray * rowCopies = [NSMutableArray array];    

		unsigned int index = 0;

		while (NSNotFound != (index = [selectedRows indexGreaterThanOrEqualToIndex:index]))
		{
			NSURL * url = [[[[self arrangedObjects] objectAtIndex:index] objectID] URIRepresentation];
			
			[rowCopies addObject:[url description]];
			
			index++;
		}

		[pboard setPropertyList:rowCopies forType:type];
	}
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return NSDragOperationMove;
}

@end
