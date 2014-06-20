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


#import "FieldsDataSource.h"
#import "BooksAppDelegate.h"

@implementation FieldsDataSource

- (FieldsDataSource *) init
{
	fields = nil;
	
	return self;
}

- (NSMutableArray *) getFields
{
	if (fields != nil)
		return fields;
	
	NSArray * defaultFields = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Display Fields"];

	NSArray * fieldTitles = [NSArray arrayWithObjects:NSLocalizedString (@"Title", nil), 
							NSLocalizedString (@"Series", nil), NSLocalizedString (@"Genre", nil), 
							NSLocalizedString (@"ISBN", nil), NSLocalizedString (@"Author(s)", nil), 
							NSLocalizedString (@"Date Published", nil),	NSLocalizedString (@"Keywords", nil), 
							NSLocalizedString (@"Publisher", nil), NSLocalizedString (@"Translator(s)", nil), 
							NSLocalizedString (@"Illustrator(s)", nil), NSLocalizedString (@"Editor(s)", nil), 
							NSLocalizedString (@"Place Published", nil), NSLocalizedString (@"Length", nil), 
							NSLocalizedString (@"Edition", nil), NSLocalizedString (@"Format", nil), 
							NSLocalizedString (@"Location", nil), NSLocalizedString (@"Rating", nil), 
							NSLocalizedString (@"Condition", nil), NSLocalizedString (@"Source", nil), 
							NSLocalizedString (@"Owner", nil), NSLocalizedString (@"Current Value", nil), 
							NSLocalizedString (@"Rating", nil), NSLocalizedString (@"Borrower", nil), 
							NSLocalizedString (@"Date Lent", nil), NSLocalizedString (@"Returned On", nil), 
							NSLocalizedString (@"Date Acquired", nil), NSLocalizedString (@"Date Finished", nil), 
							NSLocalizedString (@"Date Started", nil), nil];
	
	if (defaultFields != nil)
		fields = [NSMutableArray arrayWithArray:defaultFields];

	if (fields == nil || [fields count] != [fieldTitles count])
	{
		NSArray * fieldKeys = [NSArray arrayWithObjects:@"title", @"series", @"genre", @"isbn", @"authors", @"publishDate", 
			@"keywords", @"publisher", @"translators", @"illustrators", @"editors", @"publishPlace", 
			@"length", @"edition", @"format", @"location", @"rating", @"condition", @"source", @"owner", @"currentValue", 
			@"rating", @"borrower", @"dateLent", @"dateDue", @"dateAcquired", @"dateFinished", @"dateStarted", nil];
			
		// NSArray * fieldEnabled = [NSArray arrayWithObjects:@"YES", @"YES", @"YES", @"NO", nil];
		
		fields = [NSMutableArray array];
		
		int i = 0;
		
		for (i = 0; i < [fieldTitles count]; i++)
		{
			NSMutableDictionary * field = [NSMutableDictionary dictionary];
			
			[field setObject:[fieldTitles objectAtIndex:i] forKey:@"Title"];
			[field setObject:[fieldKeys objectAtIndex:i] forKey:@"Key"];
			// [field setObject:[fieldEnabled objectAtIndex:i] forKey:@"Enabled"];
		
			[fields addObject:field];
		}
	}
	
	return [fields retain];
}

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	return [[self getFields] count];
}

- (id) tableView: (NSTableView *) tableView objectValueForTableColumn: (NSTableColumn *) tableColumn row: (int) rowIndex
{
	NSMutableDictionary * field = [[self getFields] objectAtIndex:rowIndex];
	
	NSString * identifier = [tableColumn identifier];

	if ([identifier isEqualToString:@"Enabled"])
		return [field objectForKey:identifier];
	else
		return [field objectForKey:identifier];
}

- (BOOL) tableView: (NSTableView *) tableView
	     writeRowsWithIndexes: (NSIndexSet *) rowIndexes 
		 toPasteboard: (NSPasteboard *) pboard
{
	unsigned int indexes[1];

	NSRange range = NSMakeRange (0, 64);
	
	int count = [rowIndexes getIndexes:indexes maxCount:1 inIndexRange:&range];

	if (count > 0)
	{
		[tableView registerForDraggedTypes: [NSArray arrayWithObjects:@"NSGeneralPboardType", nil]];
		
		NSMutableDictionary * field = [[self getFields] objectAtIndex:indexes[0]];
		
		NSData * data = [NSArchiver archivedDataWithRootObject:field];
		
		[pboard declareTypes:[NSArray arrayWithObject:@"NSGeneralPboardType"] owner:self];
				
		return [pboard setData:data forType:@"NSGeneralPboardType"];
	}
	
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	return NSDragOperationMove;
}

- (BOOL) tableView: (NSTableView *) tableView acceptDrop: (id <NSDraggingInfo>) info row: (int) row 
	dropOperation: (NSTableViewDropOperation) operation
{
	NSMutableArray * fieldArray = [self getFields];
	
	NSPasteboard * pboard = [info draggingPasteboard];
	
	NSMutableDictionary * field = (NSMutableDictionary *) [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:@"NSGeneralPboardType"]];

	int i = 0;
	for (i = 0; i < [fieldArray count]; i++)
	{
		NSMutableDictionary * f = [fieldArray objectAtIndex:i];
		
		if ([[f objectForKey:@"Title"] isEqualToString:[field objectForKey:@"Title"]])
			[fieldArray removeObjectAtIndex:i];
	}
	
	if (row >= [fieldArray count])
		[fieldArray addObject:field];
	else
		[fieldArray insertObject:field atIndex:row];
	
	[[NSUserDefaults standardUserDefaults] setObject:fieldArray forKey:@"Display Fields"];
	[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) updateBooksTable:self];

	[tableView reloadData];
	
	return YES;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] isEqualToString:@"Enabled"])
	{
		NSMutableDictionary * field = [NSMutableDictionary dictionaryWithDictionary:[[self getFields] objectAtIndex:rowIndex]];
		
		[field setObject:anObject forKey:@"Enabled"];
		
		[[self getFields] replaceObjectAtIndex:rowIndex withObject:field];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[self getFields] forKey:@"Display Fields"];
	[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) updateBooksTable:self];
}

@end
