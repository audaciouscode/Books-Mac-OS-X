//
//  FieldsTableViewDelegate.m
//  Books
//
//  Created by Chris Karr on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "FieldsTableViewDelegate.h"

@implementation FieldsTableViewDelegate

- (void) dealloc
{
	if (listFields != nil)
		[listFields release];
	
	if (bookFields != nil)
		[bookFields release];
	
	[super dealloc];
}

- (void) setup
{
	NSArray * columns = [listFieldsTable tableColumns];
	
	int i = 0;
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
		
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}

	columns = [bookFieldsTable tableColumns];
	
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
		
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}
	
	inited = true;
}

- (FieldsTableViewDelegate *) init
{
	listFields = nil;
	bookFields = nil;
	
	inited = false;
	
	return self;
}

- (NSMutableArray *) getListFields
{
	if (listFields != nil)
		return listFields;
	
	NSArray * defaultFields = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Display Fields"];

	NSArray * fieldTitles = [NSArray arrayWithObjects:NSLocalizedString (@"Title", nil), NSLocalizedString (@"Summary", nil),
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
		listFields = [NSMutableArray arrayWithArray:defaultFields];

	if (listFields == nil || [listFields count] != [fieldTitles count])
	{
		NSArray * fieldKeys = [NSArray arrayWithObjects:@"title", @"summary", @"series", @"genre", @"isbn", @"authors", @"publishDate", 
			@"keywords", @"publisher", @"translators", @"illustrators", @"editors", @"publishPlace", 
			@"length", @"edition", @"format", @"location", @"rating", @"condition", @"source", @"owner", @"currentValue", 
			@"rating", @"borrower", @"dateLent", @"dateDue", @"dateAcquired", @"dateFinished", @"dateStarted", nil];
			
		// NSArray * fieldEnabled = [NSArray arrayWithObjects:@"YES", @"YES", @"YES", @"NO", nil];
		
		listFields = [NSMutableArray array];
		
		int i = 0;
		
		for (i = 0; i < [fieldTitles count]; i++)
		{
			NSMutableDictionary * field = [NSMutableDictionary dictionary];
			
			[field setObject:[fieldTitles objectAtIndex:i] forKey:@"Title"];
			[field setObject:[fieldKeys objectAtIndex:i] forKey:@"Key"];
			// [field setObject:[fieldEnabled objectAtIndex:i] forKey:@"Enabled"];
		
			[listFields addObject:field];
		}
	}
	
	return [listFields retain];
}

- (NSMutableArray *) getBookFields
{
	if (bookFields != nil)
		return bookFields;
	
	NSArray * defaultFields = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Display Fields"];

	NSArray * fieldTitles = [NSArray arrayWithObjects:NSLocalizedString (@"Title", nil), NSLocalizedString (@"Summary", nil),
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
		bookFields = [NSMutableArray arrayWithArray:defaultFields];

	if (bookFields == nil || [bookFields count] != [fieldTitles count])
	{
		NSArray * fieldKeys = [NSArray arrayWithObjects:@"title", @"summary", @"series", @"genre", @"isbn", @"authors", @"publishDate", 
			@"keywords", @"publisher", @"translators", @"illustrators", @"editors", @"publishPlace", 
			@"length", @"edition", @"format", @"location", @"rating", @"condition", @"source", @"owner", @"currentValue", 
			@"rating", @"borrower", @"dateLent", @"dateDue", @"dateAcquired", @"dateFinished", @"dateStarted", nil];
			
		// NSArray * fieldEnabled = [NSArray arrayWithObjects:@"YES", @"YES", @"YES", @"NO", nil];
		
		bookFields = [NSMutableArray array];
		
		int i = 0;
		
		for (i = 0; i < [fieldTitles count]; i++)
		{
			NSMutableDictionary * field = [NSMutableDictionary dictionary];
			
			[field setObject:[fieldTitles objectAtIndex:i] forKey:@"Title"];
			[field setObject:[fieldKeys objectAtIndex:i] forKey:@"Key"];
			// [field setObject:[fieldEnabled objectAtIndex:i] forKey:@"Enabled"];
		
			[bookFields addObject:field];
		}
	}
	
	return [bookFields retain];
}

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	if (aTableView == listFieldsTable)
		return [[self getListFields] count];
	else if (aTableView == bookFieldsTable)
		return [[self getBookFields] count];
		
	return 0;
}

- (id) tableView: (NSTableView *) tableView objectValueForTableColumn: (NSTableColumn *) tableColumn row: (int) rowIndex
{
	if (!inited)
		[self setup];
		
	NSMutableDictionary * field = nil;

	if (tableView == listFieldsTable)
		field = [[self getListFields] objectAtIndex:rowIndex];
	if (tableView == bookFieldsTable)
		field = [[self getBookFields] objectAtIndex:rowIndex];
	
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
		
		NSMutableDictionary * field = nil;
		
		if (tableView == listFieldsTable)
			field = [[self getListFields] objectAtIndex:indexes[0]];
		else if (tableView == bookFieldsTable)
			field = [[self getBookFields] objectAtIndex:indexes[0]];
		
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
	NSMutableArray * fieldArray = nil;

	if (tableView == listFieldsTable)
		fieldArray = [self getListFields];
	if (tableView == bookFieldsTable)
		fieldArray = [self getBookFields];
	
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
	
	if (tableView == listFieldsTable)
		[[NSUserDefaults standardUserDefaults] setObject:fieldArray forKey:@"Display Fields"];
	else if (tableView == bookFieldsTable)
		[[NSUserDefaults standardUserDefaults] setObject:fieldArray forKey:@"Detail Fields"];

	[tableViewDelegate updateBooksTable];

	[tableView reloadData];
	
	return YES;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn identifier] isEqualToString:@"Enabled"])
	{
		NSMutableDictionary * field = nil;
		
		if (tableView == listFieldsTable)
			field = [NSMutableDictionary dictionaryWithDictionary:[[self getListFields] objectAtIndex:rowIndex]];
		else if (tableView == bookFieldsTable)
			field = [NSMutableDictionary dictionaryWithDictionary:[[self getBookFields] objectAtIndex:rowIndex]];
		
		[field setObject:anObject forKey:@"Enabled"];
		
		if (tableView == listFieldsTable)
			[[self getListFields] replaceObjectAtIndex:rowIndex withObject:field];
		else if (tableView == bookFieldsTable)
			[[self getBookFields] replaceObjectAtIndex:rowIndex withObject:field];
	}
	
	if (tableView == listFieldsTable)
		[[NSUserDefaults standardUserDefaults] setObject:[self getListFields] forKey:@"Display Fields"];
	else if (tableView == bookFieldsTable)
		[[NSUserDefaults standardUserDefaults] setObject:[self getBookFields] forKey:@"Detail Fields"];

	[tableViewDelegate updateBooksTable];
}


@end
