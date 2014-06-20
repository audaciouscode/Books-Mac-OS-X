//
//  PeopleArrayController.m
//  Books
//
//  Created by Chris Karr on 4/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PeopleArrayController.h"
#import <AddressBook/AddressBook.h>

@implementation PeopleArrayController

- (id) arrangedObjects
{
	if (people == nil)
	{
		people = [[NSMutableArray alloc] init];
		
		NSArray * abPeople = [[ABAddressBook sharedAddressBook] people];
		
		int i = 0;
		for (i = 0; i < [abPeople count]; i++)
		{
			ABPerson * person = [abPeople objectAtIndex:i];
			
			NSString * firstName = [person valueForProperty:kABFirstNameProperty];
			NSString * lastName = [person valueForProperty:kABLastNameProperty];
			
			NSString * name = [NSString stringWithFormat:@"%@ %@", firstName, lastName, nil];

			if (firstName != nil && lastName != nil)
			{
				NSMutableDictionary * p = [NSMutableDictionary dictionary];
				[p setValue:name forKey:@"name"];
				
				NSData * data = [person imageData];
				
				if (data != nil)
					[p setValue:data forKey:@"image"];
				
				[people addObject:p];
			}
		}
	}
	
	[people sortUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
	
	return people;
}

- (BOOL) canInsert
{	
	return NO;
}

/*- (void) setMugshotImage:(NSString *) selected
{
	if (mugshot == nil || people == nil)
		return;
	
	int i = 0;
	for (i = 0; i < [people count]; i++)
	{
		NSDictionary * p = [people objectAtIndex:i];
	
		if ([[p valueForKey:@"name"] isEqual:selected])
		{
			if ([p valueForKey:@"image"] != nil)
			{
				NSImage * image = [mugshot image];
			
				[mugshot setImage:[[NSImage alloc] initWithData:[p valueForKey:@"image"]]];
				
				if (image != nil)
					[image release];
				
				return;
			}
		}
	}
	
	[mugshot setImage:nil];
}

- (void) comboBoxSelectionDidChange: (NSNotification *) notification
{
	NSComboBox * combobox = [notification object];

	NSString * selected = [combobox objectValueOfSelectedItem];

	[self setMugshotImage:selected];
}

- (void) controlTextDidChange: (NSNotification *) notification
{
	NSComboBox * combobox = [notification object];

	NSString * selected = [combobox stringValue];
	
	[self setMugshotImage:selected];
}

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification
{
	NSTableView * table = [aNotification object];
	
	int index = [table selectedRow];
	
	if (index != -1)
	{
		NSManagedObject * row = [[lendingRecords arrangedObjects] objectAtIndex:index];
		
		NSString * name = [row valueForKey:@"borrower"];
		
		if (name != nil)
			[self setMugshotImage:name];
		else
			[self setMugshotImage:@"nil name"];
	}
}

- (void)tableView:(NSTableView *)table willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	int index = [table selectedRow];
	
	if (index == -1)
		[mugshot setImage:nil];
}
*/
@end
