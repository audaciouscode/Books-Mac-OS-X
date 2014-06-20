//
//  BooksTableViewDelegate.m
//  Books
//
//  Created by Chris Karr on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BooksTableViewDelegate.h"
#import "BooksAppDelegate.h"
#import "SmartListManagedObject.h"

@implementation BooksTableViewDelegate

- (void) dealloc
{
	[super dealloc];
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	NSTableView * table = [notification object];

	if (table == booksTable)
	{

	}
	else if (table == listsTable)
	{
		NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];

		if (openFilename != nil)
		{
			[spotlightInterface openFile:openFilename];
			[openFilename release];
			openFilename = nil;
			
			[prefs setValue:nil forKey:@"Last Open Books"];
			[prefs setValue:nil forKey:@"Last Open List"];
		}
		else
		{
			NSString * lastOpenList = [prefs valueForKey:@"Last Open List"];
			
			if (lastOpenList != nil)
			{
				NSArray * lists = [collectionArrayController arrangedObjects];

				int i = 0;
				for (i = 0; i < [lists count]; i++)
				{
					if ([lastOpenList isEqual:[[[[lists objectAtIndex:i] objectID] URIRepresentation] description]])
						[collectionArrayController setSelectionIndexes:[NSIndexSet indexSetWithIndex:i]];
				}
			
				NSArray * lastOpenBooks = [prefs valueForKey:@"Last Open Books"];
				
				if (lastOpenBooks != nil)
				{
					NSMutableArray * lastBooks = [NSMutableArray array];
				
					NSArray * books = [bookArrayController arrangedObjects];
					
					for (i = 0 ; i < [books count]; i++)
					{
						int j = 0;
						
						for (j = 0; j < [lastOpenBooks count]; j++)
						{
							if ([[lastOpenBooks objectAtIndex:j] isEqual:[[[[books objectAtIndex:i] objectID] URIRepresentation] description]])
								[lastBooks addObject:[books objectAtIndex:i]];
						}
					}
					
					[bookArrayController setSelectedObjects:lastBooks];

					[prefs setValue:nil forKey:@"Last Open Books"];
				}
				
				[prefs setValue:nil forKey:@"Last Open List"];
			}
		}
		
		NSSortDescriptor * sorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(compare:)];
		[collectionArrayController setSortDescriptors:[NSArray arrayWithObject:sorter]];
		[sorter release];
			
		NSArray * selectedObjects = [collectionArrayController selectedObjects];

		if ([selectedObjects count] > 0)
		{
			ListManagedObject * list = [selectedObjects objectAtIndex:0];

			NSDictionary * sorts = [prefs dictionaryForKey:@"Table Sorting"];
	
			if (sorts != nil)
			{
				NSArray * descs = [sorts objectForKey:[[[list objectID] URIRepresentation] absoluteString]];

				if (descs != nil)
				{
					NSMutableArray * sortDescs = [NSMutableArray array];
					
					int i = 0;
					for (i = 0; i < [descs count]; i++)
					{
						NSDictionary * sort = [descs objectAtIndex:i];
						
						BOOL ascend = NO;
				
						if ([[sort valueForKey:@"ascend"] isEqual:@"YES"])
							ascend = YES;

						NSSortDescriptor * sortDesc = nil;

						NSString * key = [sort valueForKey:@"key"];
						
						if ([key rangeOfString:@"date" options:NSCaseInsensitiveSearch].location != NSNotFound)
							sortDesc = [[NSSortDescriptor alloc] initWithKey:key ascending:ascend selector:@selector(compare:)];
						else if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
							sortDesc = [[NSSortDescriptor alloc] initWithKey:key ascending:ascend selector:@selector(localizedCaseInsensitiveCompare:)];
						else
							sortDesc = [[NSSortDescriptor alloc] initWithKey:key ascending:ascend selector:@selector(caseInsensitiveCompare:)];

						[sortDescs addObject:sortDesc];
						
						[sortDesc release];
					}

					[booksTable setSortDescriptors:sortDescs];
				}
			}
			
			if ([list isKindOfClass:[SmartListManagedObject class]])
			{
				[toolbarDelegate setNewBookAction:nil];
				[toolbarDelegate setEditSmartListAction:NSSelectorFromString(@"editSmartList:")];
				[toolbarDelegate setRemoveBookAction:nil];
				[toolbarDelegate setRemoveListAction:NSSelectorFromString(@"removeList:")];
			}
			else
			{
				[toolbarDelegate setNewBookAction:NSSelectorFromString(@"newBook:")];
				[toolbarDelegate setEditSmartListAction:nil];
				[toolbarDelegate setRemoveBookAction:NSSelectorFromString(@"removeBook:")];
				[toolbarDelegate setRemoveListAction:NSSelectorFromString(@"removeList:")];
			}
		}
		else
		{
			[toolbarDelegate setNewBookAction:nil];
			[toolbarDelegate setEditSmartListAction:nil];
			[toolbarDelegate setRemoveBookAction:nil];
			[toolbarDelegate setRemoveListAction:nil];
		}
	}

	NSArray * books = [((BooksAppDelegate *) booksAppDelegate) getSelectedBooks];
		
	if ([books count] == 1)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];
			
		NSData * coverData = [book getCoverImage];
		
		if (coverData != nil)
			[toolbarDelegate setGetCoverAction:NSSelectorFromString (@"getCoverWindow:")];
		else
			[toolbarDelegate setGetCoverAction:nil];
	}

	NSNotification * msg = [NSNotification notificationWithName:BOOKS_HIDE_COVER object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:msg];
}

- (void) tableView: (NSTableView *) tableView didClickTableColumn: (NSTableColumn *) tableColumn
{
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	
	NSDictionary * sorts = [prefs dictionaryForKey:@"Table Sorting"];
	
	if (sorts == nil)
		sorts = [NSDictionary dictionary];
	
	NSMutableDictionary * newSorts = [NSMutableDictionary dictionaryWithDictionary:sorts];
	
	NSArray * descs = [[tableColumn tableView] sortDescriptors];
	
	int selected = [collectionArrayController selectionIndex];
	
	ListManagedObject * currentList = [[collectionArrayController arrangedObjects] objectAtIndex:selected];
	
	if (currentList != nil)
	{
		NSMutableArray * savedSorts = [NSMutableArray array];
		
		int i = 0;
		for (i = 0; i < [descs count]; i++)
		{
			NSSortDescriptor * sort = [descs objectAtIndex:i];
		
			NSMutableDictionary * desc = [NSMutableDictionary dictionary];
		
			if ([sort ascending])
				[desc setValue:@"YES" forKey:@"ascend"];
			else
				[desc setValue:@"NO" forKey:@"ascend"];

			[desc setValue:[sort key] forKey:@"key"];

			[newSorts setObject:desc forKey:[[[currentList objectID] URIRepresentation] absoluteString]];
			
			[savedSorts addObject:newSorts];
		}
	
		[prefs setValue:savedSorts forKey:@"Table Sorting"];
	}
}

- (void) save
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSArray * tableColumns = [booksTable tableColumns];

	NSMutableArray * columnWidths = [NSMutableArray array];
	
	NSMutableArray * columns = [NSMutableArray arrayWithArray:[defaults objectForKey:@"Display Fields"]];

	int i = 0;
	for (i = [tableColumns count] - 1; i >=0 ; i--)
	{
		NSTableColumn * column = [tableColumns objectAtIndex:i];
		
		NSString * identifier = [column identifier];
		
		int j = 0;
		for (j = 0; j < [columns count]; j++)
		{
			NSDictionary * dict = [columns objectAtIndex:j];
			
			if ([[dict objectForKey:@"Key"] isEqual:identifier])
			{
				[columns removeObject:dict];
				
				[columns insertObject:dict atIndex:0];
			}
		}
		
		[columnWidths insertObject:[NSNumber numberWithFloat:[column width]] atIndex:0];
	}

	[defaults setObject:columnWidths forKey:@"Main Window Column Widths"];
	
	[defaults setObject:columns forKey:@"Display Fields"];

	NSArray * sortDescriptors = [booksTable sortDescriptors];
	NSMutableArray * savedSortDescriptors = [NSMutableArray array];
	
	for (i = 0; i < [sortDescriptors count]; i++)
	{
		NSSortDescriptor * descriptor = [sortDescriptors objectAtIndex:i];

		NSMutableDictionary * values = [NSMutableDictionary dictionary];
		[values setObject:[descriptor key] forKey:@"key"];
		
		if ([descriptor ascending])
			[values setObject:@"yes" forKey:@"ascending"];
		else
			[values setObject:@"no" forKey:@"ascending"];
		
		[savedSortDescriptors addObject:values];
	}

	[defaults setObject:savedSortDescriptors forKey:@"Books Table Sorting"];
}

- (void) restore
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	NSArray * columnWidths = [defaults arrayForKey:@"Main Window Column Widths"];
	NSArray * tableColumns = [booksTable tableColumns];
	
	if (columnWidths != nil)
	{
		int i = 0;
		for (i = 0; i < [columnWidths count] && i < [tableColumns count]; i++)
		{
			NSNumber * width = [columnWidths objectAtIndex:i];
			[[tableColumns objectAtIndex:i] setWidth:[width floatValue]];
		}
	}

	NSArray * booksSorting = [defaults arrayForKey:@"Books Table Sorting"];

	NSMutableArray * sortDescriptors = [NSMutableArray array];
	
	int j = 0;
	for (j = 0; j < [booksSorting count]; j++)
	{
		NSDictionary * dict = (NSDictionary *) [booksSorting objectAtIndex:j];
		
		NSSortDescriptor * descriptor = nil;
		
		NSString * key = (NSString *) [dict objectForKey:@"key"];

		// if ([key rangeOfString:@"date" options:NSCaseInsensitiveSearch].location != NSNotFound)
			descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:[[dict objectForKey:@"ascending"] isEqual:@"yes"] selector:@selector(compare:)];
		// else if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		// 	descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:[[dict objectForKey:@"ascending"] isEqual:@"yes"] selector:@selector(localizedCaseInsensitiveCompare:)];
		// else
		//	descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:[[dict objectForKey:@"ascending"] isEqual:@"yes"] selector:@selector(caseInsensitiveCompare:)];

		[sortDescriptors addObject:descriptor];
		
		[descriptor release];
	}

	[booksTable setSortDescriptors:sortDescriptors];

	[listsTable registerForDraggedTypes:[NSArray arrayWithObject:@"Books Book Type"]];
}	

- (void) updateBooksTable
{
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	
	NSArray * newColumns = [prefs arrayForKey:@"Display Fields"];

	NSArray * oldColumns = [NSArray arrayWithArray:[listsTable tableColumns]];

	if ([oldColumns count] == 0)
	{
		NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:@"icon"];
		[[column headerCell] setStringValue:@""];

		NSImageCell * cell = [[NSImageCell alloc] init];
		[column setDataCell:cell];
		[cell release];
		
		[column bind:@"data" toObject:collectionArrayController withKeyPath:@"arrangedObjects.icon" options: nil];
		[column setWidth:16.0];
		[column setResizingMask:NSTableColumnNoResizing];
		
		[listsTable addTableColumn:column];
		[column release];

		column = [[NSTableColumn alloc] initWithIdentifier:@"name"];
		[[column headerCell] setStringValue:@"Lists"];
		[column bind:@"value" toObject:collectionArrayController withKeyPath:@"arrangedObjects.name" options: nil];
		[column setResizingMask:NSTableColumnAutoresizingMask];
		[column setWidth:([listsTable frame].size.width - 16)];

		[listsTable addTableColumn:column];
		[column release];
		
		NSSortDescriptor * sort = nil;

		// if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		// 	sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
		// else
		// 	sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];

		sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(compare:)];
		
		[collectionArrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
		[sort release];
	}

	NSSortDescriptor * sort = nil;
	
	if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	else
		sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];

	[collectionArrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];
	
	oldColumns = [NSArray arrayWithArray:[booksTable tableColumns]];
	
	int i = 0;
	
	for (i = 0; i < [oldColumns count]; i++)
		[booksTable removeTableColumn:[oldColumns objectAtIndex:i]];

	NSArray * menuItems = [booksColumnMenu itemArray];
	
	for (i = 0; i < [menuItems count]; i++)
		[[menuItems objectAtIndex:i] setState:NSOffState];

	if ([newColumns count] == 0)
	{
		NSMutableDictionary * title = [NSMutableDictionary dictionary];
		[title setValue:@"title" forKey:@"Key"];
		[title setValue:NSLocalizedString (@"Title", nil) forKey:@"Title"];
		[title setValue:[NSNumber numberWithInt:1] forKey:@"Enabled"];

		newColumns = [NSArray arrayWithObject:title];
	}

	for (i = 0; i < [newColumns count]; i++)
	{
		NSDictionary * dict = [newColumns objectAtIndex:i];

		NSString * key = [dict objectForKey:@"Key"];
		NSString * title = NSLocalizedString ([dict objectForKey:@"Title"], nil);
		NSString * enabled = [[dict objectForKey:@"Enabled"] description];

		if ([enabled isEqualToString:@"1"])
		{
			[[booksColumnMenu itemWithTitle:title] setState:NSOnState];

			NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:key];
		
			[[column headerCell] setStringValue:title];

			[column bind:@"value" toObject:bookArrayController withKeyPath:[@"arrangedObjects." stringByAppendingString:key] 
				options: nil];

			NSString * dateFormat = [[NSApp delegate] getDateFormatString];
			[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
			NSDateFormatter * formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:YES];

			if ([key isEqualToString:@"publishDate"] || 
				[key isEqualToString:@"dateLent"] ||
				[key isEqualToString:@"dateDue"] ||
				[key isEqualToString:@"dateFinished"] ||
				[key isEqualToString:@"dateAcquired"] ||
				[key isEqualToString:@"dateStarted"] )
			{
				[[column dataCell] setFormatter:formatter];

				NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES selector:@selector(compare:)];
				
				[column setSortDescriptorPrototype:sortDescriptor];
				[sortDescriptor release];
			}
			else
			{
				NSSortDescriptor * sortDescriptor = nil;
				
				if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
					sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
				else
					sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES selector:@selector(caseInsensitiveCompare:)];
					
				[column setSortDescriptorPrototype:sortDescriptor];
				
				[sortDescriptor release];
			}

			[formatter release];
			[column setEditable:NO];
			
			[booksTable addTableColumn:column];
			[column release];
		}
	}
	
	NSString * customString = [prefs objectForKey:@"Custom List User Fields"];

	if (customString != nil && ![customString isEqual:@""])
	{
		NSArray * fields = [customString componentsSeparatedByString:@"\n"];

		for (i = 0; i < [fields count]; i++)
		{
			NSString * field = [fields objectAtIndex:i];
			if (field != nil && ![field isEqual:@""])
			{
				NSMutableString * fieldKey = [NSMutableString stringWithString:field];
				
				[fieldKey replaceOccurrencesOfString:@"." withString:@"" options:NSCaseInsensitiveSearch 
					range:NSMakeRange (0, [fieldKey length])];

				NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:fieldKey];
		
				[[column headerCell] setStringValue:field];
			
				[column bind:@"value" toObject:bookArrayController 
					withKeyPath:[@"arrangedObjects." stringByAppendingString:fieldKey] options: nil];
			
				NSSortDescriptor * sortDescriptor = nil;
				
				if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
					sortDescriptor = [[NSSortDescriptor alloc] initWithKey:fieldKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
				else
					sortDescriptor = [[NSSortDescriptor alloc] initWithKey:fieldKey ascending:YES selector:@selector(caseInsensitiveCompare:)];
				
				[column setSortDescriptorPrototype:sortDescriptor];
				[sortDescriptor release];

				[column setEditable:NO];
			
				[booksTable addTableColumn:column];
				[column release];
			}
		}
	}		

	[booksTable sizeToFit];
	[booksTable setDoubleAction:@selector(getInfoWindow:)];
}

- (void) reloadListsTable
{
	[listsTable reloadData];
}

- (void) reloadBooksTable
{
	[booksTable reloadData];
}

- (NSTableView *) getListsTable
{
	return listsTable;
}

- (NSTableView *) getBooksTable
{
	return booksTable;
}

- (void) setOpenFilename:(NSString *) filename
{
	openFilename = [filename retain];
}

- (IBAction) toggleColumns: (id) sender
{
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	NSArray * prefArray = [prefs arrayForKey:@"Display Fields"];
	
	if (prefArray == nil)
		prefArray = [NSArray array];
		
	NSMutableArray * columnArray = [NSMutableArray arrayWithArray:prefArray];
	
	NSString * title = [sender title];
	int index = [fieldTitles indexOfObject:title];
	NSString * key = [fieldKeys objectAtIndex:index];
	
	NSMenuItem * menuItem = [booksColumnMenu itemWithTitle:[sender title]];

	if ([menuItem state] == NSOnState)
	{
		int i = 0;
		for (i = 0; i < [columnArray count]; i++)
		{
			if ([[[columnArray objectAtIndex:i] valueForKey:@"Key"] isEqualTo:key])
				[columnArray removeObjectAtIndex:i];
		}
	}
	else 
	{
		NSMutableDictionary * dict = [NSMutableDictionary dictionary];
		[dict setValue:key forKey:@"Key"];
		[dict setValue:title forKey:@"Title"];
		[dict setValue:[NSNumber numberWithInt:1] forKey:@"Enabled"];
		
		[columnArray addObject:dict];
	}

	[prefs setObject:columnArray forKey:@"Display Fields"];
	[self updateBooksTable];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{

    if ([keyPath isEqual:@"Show Gallery"])
	{
		[self willChangeValueForKey:@"label"];

		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Gallery"])
			[box selectTabViewItemAtIndex:1];
		else
			[box selectTabViewItemAtIndex:0];

		[self didChangeValueForKey:@"label"];
	}
	else if ([keyPath isEqual:@"Custom List User Fields"])
		[self updateBooksTable];
}

- (int) getLabel
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Gallery"])
		return 1;
	else
		return 0;
}

- (void) setLabel:(int) label
{
	[self willChangeValueForKey:@"label"];

	if (label == 1)
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Show Gallery"];
	else
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Show Gallery"];

	[self didChangeValueForKey:@"label"];
}
		
- (void) awakeFromNib
{
	fieldTitles = [[NSArray alloc] initWithObjects:NSLocalizedString (@"Title", nil), 
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

	fieldKeys = [[NSArray alloc] initWithObjects:@"title", @"series", @"genre", @"isbn", @"authors", @"publishDate", 
			@"keywords", @"publisher", @"translators", @"illustrators", @"editors", @"publishPlace", 
			@"length", @"edition", @"format", @"location", @"rating", @"condition", @"source", @"owner", @"currentValue", 
			@"rating", @"borrower", @"dateLent", @"dateDue", @"dateAcquired", @"dateFinished", @"dateStarted", nil];

	[[booksTable headerView] setMenu:booksColumnMenu];

	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Show Gallery" options:NSKeyValueObservingOptionNew context:NULL];

	[listsTable setNextKeyView:booksTable];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Gallery"])
	{
		[listsTable setNextKeyView:gallery];
		[self setLabel:1];
	}
	else
	{
		[self setLabel:0];
	}
	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Custom List User Fields" options:NSKeyValueObservingOptionNew context:NULL];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"setControlsView:") 
		name:BOOKS_SET_CONTROL_VIEW object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"editListName:") 
		name:BOOKS_EDIT_LIST_NAME object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"openBook:") 
		name:BOOKS_OPEN_BOOK object:nil];
}

- (void) setControlsView: (NSNotification *) msg
{
	ViewControls * controls = [msg object];

	if (controls == nil)
		[listsTable setNextKeyView:booksTable];
	else
		[listsTable setNextKeyView:gallery];
}

- (NSImage *) getListIcon
{
	return [NSImage imageNamed:@"list-small"];
}

- (NSData *) getGalleryIcon
{
	return [NSImage imageNamed:@"gallery"];
}

- (void) openBook: (NSNotification *) msg
{
	openFilename = [[msg object] retain];
}

- (void) editListName: (NSNotification *) msg
{
	NSIndexSet * indexes = [collectionArrayController selectionIndexes];

	[listsTable editColumn:1 row:[indexes firstIndex] withEvent:nil select:YES];
}


@end
