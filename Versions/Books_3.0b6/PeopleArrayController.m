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
