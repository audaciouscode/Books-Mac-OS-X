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


#import "BooksAppDelegate.h"
#import "ImportPluginInterface.h"
#import "ExportPluginInterface.h"
#import "QuickfillPluginInterface.h"
#import "HtmlPageBuilder.h"
#import "FieldsDataSource.h"
#import "SmartList.h"
#import "BooksToolbarItem.h"
#import "BookManagedObject.h"
#import "MyBarcodeScanner.h"

typedef struct _monochromePixel
{ 
	unsigned char grayValue; 
	unsigned char alpha; 
} monochromePixel;
	
@implementation BooksAppDelegate

- (NSManagedObjectModel *) managedObjectModel 
{
    if (managedObjectModel) 
		return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];

    [allBundles release];
    
    return managedObjectModel;
}

- (NSString *) applicationSupportFolder 
{
    NSString * applicationSupportFolder = nil;
    FSRef foundRef;
    OSErr err = FSFindFolder (kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);

    if (err != noErr) 
	{
        NSRunAlertPanel (NSLocalizedString (@"Alert", nil), NSLocalizedString (@"Can't find application support folder", nil), 
							NSLocalizedString (@"Quit", nil), nil, nil);
        [[NSApplication sharedApplication] terminate:self];
    }
	else 
	{
        unsigned char path[1024];
        FSRefMakePath (&foundRef, path, sizeof(path));
        applicationSupportFolder = [NSString stringWithUTF8String:(char *) path];
        applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"Books"];
    }
	
    return applicationSupportFolder;
}

- (NSManagedObjectContext *) managedObjectContext
{
    NSError * error;
    NSString * applicationSupportFolder = nil;
    NSURL * url;
    NSFileManager * fileManager;
    NSPersistentStoreCoordinator * coordinator;
    
    if (managedObjectContext) 
	{
        return managedObjectContext;
    }
    
	fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    
	if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) 
	{
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
	NSString * filePath = [applicationSupportFolder stringByAppendingPathComponent: @"Books.books-data"];
	
    url = [NSURL fileURLWithPath:filePath];
    
	coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
	else
	{
        [[NSApplication sharedApplication] presentError:error];
    }
	    
    [coordinator release];

	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];

	NSEntityDescription * entity = [NSEntityDescription entityForName:@"List" inManagedObjectContext:managedObjectContext];

	[fetch setEntity:entity];
	[fetch setPredicate:[NSPredicate predicateWithFormat:@"name != \"\""]];

	NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	if (results == nil || [results count] == 0)
	{
		NSEntityDescription * collectionDesc = [[[self managedObjectModel] entitiesByName] objectForKey:@"List"];
		NSEntityDescription * bookDesc = [[[self managedObjectModel] entitiesByName] objectForKey:@"Book"];

		[managedObjectContext lock];
		
		ListManagedObject * listObject = [[ListManagedObject alloc] initWithEntity:collectionDesc 
											insertIntoManagedObjectContext:managedObjectContext];

		[listObject setValue:NSLocalizedString (@"My Books", nil) forKey:@"name"];

		NSMutableSet * items = [listObject mutableSetValueForKey:@"items"];
		
		BookManagedObject * bookObject = [[BookManagedObject alloc] initWithEntity:bookDesc insertIntoManagedObjectContext:managedObjectContext];

		[bookObject setValue:NSLocalizedString (@"New Book", nil) forKey:@"title"];
		[items addObject:bookObject];

		[managedObjectContext unlock];
	}

    return managedObjectContext;
}

- (NSUndoManager *) windowWillReturnUndoManager: (NSWindow *) window 
{
    return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id) sender 
{
    NSError *error = nil;

    if (![[self managedObjectContext] save:&error]) 
	{
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) sender 
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	int i = 0;

	NSArray * tableColumns = [booksTable tableColumns];

	NSMutableArray * columnWidths = [NSMutableArray array];
	
	NSMutableArray * columns = [NSMutableArray arrayWithArray:[defaults objectForKey:@"Display Fields"]];
	
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

	NSMutableArray * viewRects = [NSMutableArray array];
	NSEnumerator * viewEnum = [[splitView subviews] objectEnumerator];
	NSView * view;

	while ((view = [viewEnum nextObject]) != nil)
	{
		NSRect frame;
		
		if ([splitView isSubviewCollapsed: view])
			frame = NSZeroRect;
		else
			frame = [view frame];

		[viewRects addObject:NSStringFromRect (frame)];
	}

	[defaults setObject:viewRects forKey:@"Main Scroller Sizes"];

	viewRects = [NSMutableArray array];
	viewEnum = [[leftView subviews] objectEnumerator];

	while ((view = [viewEnum nextObject]) != nil)
	{
		NSRect frame;
		
		if ([leftView isSubviewCollapsed:view])
			frame = NSZeroRect;
		else
			frame = [view frame];

		[viewRects addObject:NSStringFromRect (frame)];
	}

	[defaults setObject:viewRects forKey:@"Left Scroller Sizes"];

	viewRects = [NSMutableArray array];
	viewEnum = [[rightView subviews] objectEnumerator];

	while ((view = [viewEnum nextObject]) != nil)
	{
		NSRect frame;
		
		if ([rightView isSubviewCollapsed:view])
			frame = NSZeroRect;
		else
			frame = [view frame];

		[viewRects addObject:NSStringFromRect (frame)];
	}

	[defaults setObject:viewRects forKey:@"Right Scroller Sizes"];

    NSError *error;
    NSManagedObjectContext *context;
    int reply = NSTerminateNow;
    
    context = [self managedObjectContext];

    if (context != nil) 
	{
		if ([context commitEditing])
		{
			if (![context save:&error]) 
			{
				// This default error handling implementation should be changed to make sure the error presented 
				// includes application specific error recovery. For now, simply display 2 panels.
                
				BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
				if (errorResult == YES)
				{
					// Then the error was handled
					reply = NSTerminateCancel;
				} 
				else 
				{
					// Error handling wasn't implemented. Fall back to displaying a "quit anyway" panel.
					int alertReturn = NSRunAlertPanel (nil, NSLocalizedString (@"Could not save changes while quitting. Quit anyway?", nil) , 
													NSLocalizedString (@"Quit anyway", nil), NSLocalizedString (@"Cancel", nil), nil);
					
					if (alertReturn == NSAlertAlternateReturn)
					{
						reply = NSTerminateCancel;	
					}
				}
			}
        }
		else 
		{
            reply = NSTerminateCancel;
        }
    }
	
	if (reply != NSTerminateCancel)
	{
		BOOL isDir;

		NSFileManager * manager = [NSFileManager defaultManager];

		if ([manager fileExistsAtPath:@"/tmp/books-export" isDirectory:&isDir])
			[manager removeFileAtPath:@"/tmp/books-export" handler:nil];

		if ([manager fileExistsAtPath:@"tmp/books-quickfill.xml" isDirectory:&isDir])
			[manager removeFileAtPath:@"tmp/books-quickfill.xml" handler:nil];
	}

    return reply;
}

- (NSWindow *) mainWindow
{
	return mainWindow;
}

- (NSWindow *) infoWindow
{
	return infoWindow;
}

- (IBAction) getInfoWindow: (id) sender
{
	if ([infoWindow isVisible])
	{
		[infoWindow orderOut:sender];
		[getInfo setLabel:NSLocalizedString (@"Get Info", nil)];
	}
	else
	{
		[infoWindow makeKeyAndOrderFront:sender];
		[getInfo setLabel:NSLocalizedString (@"Hide Info", nil)];
	}
}


- (IBAction) getCoverWindow: (id) sender
{
	if ([coverWindow isVisible])
	{
		[coverWindow orderOut:sender];
		[getCover setLabel:NSLocalizedString (@"Show Cover", nil)];
	}
	else
	{
		NSArray * books = [self getSelectedBooks];
		
		if ([books count] == 1)
		{
			BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];
			
			NSData * coverData = [book getCoverImage];
		
			if (coverData != nil)
			{
				NSImage * cover = [[NSImage alloc] initWithData:coverData];
				
				NSSize size = [cover size];
				
				if (size.height <= 10)
					return;
					
				float newHeight = size.height;
				float newWidth = size.width;
				
				float bound = 400;
				
				if (newHeight > bound)
				{
					newWidth = newWidth * (bound / newHeight);
					newHeight = bound;
				}

				if (newWidth > bound)
				{
					newHeight = newHeight * (bound / newWidth);
					newWidth = bound;
				}
				
				[coverWindow setContentSize:NSMakeSize (newWidth, newHeight)];
				
				// [coverWindow makeKeyAndOrderFront:sender];
				[coverWindow orderFront:sender];
				[getCover setLabel:NSLocalizedString (@"Hide Cover", nil)];
			}
		}
	}
}


- (IBAction) doExport:(id) sender
{
	ExportPluginInterface * export = [[ExportPluginInterface alloc] init];
	
	NSBundle * exportPlugin = nil;
	
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"ExportToBundle") toTarget:export withObject:exportPlugin];
}

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar itemForItemIdentifier: (NSString *) itemIdentifier willBeInsertedIntoToolbar: (BOOL) flag
{
	NSToolbarItem * item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	[item setLabel:itemIdentifier];
	
	if ([itemIdentifier isEqualToString:@"new-list"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"newList:")];

		[item setImage:[NSImage imageNamed:@"new-list"]];
		[item setLabel:NSLocalizedString (@"New List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"New List", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"new-smartlist"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"newSmartList:")];

		[item setImage:[NSImage imageNamed:@"new-smartlist"]];
		[item setLabel:NSLocalizedString (@"New Smart List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"New Smart List", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"edit-smartlist"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"editSmartList:")];

		[item setImage:[NSImage imageNamed:@"edit-smartlist"]];
		[item setLabel:NSLocalizedString (@"Edit Smart List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Edit Smart List", nil)];
		
		editSmartList = item;
	}
	else if ([itemIdentifier isEqualToString:@"remove-list"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"removeList:")];

		[item setImage:[NSImage imageNamed:@"remove-list"]];
		[item setLabel:NSLocalizedString (@"Remove List", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Remove List", nil)];

		removeList = item;
	}
	else if ([itemIdentifier isEqualToString:@"remove-book"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"removeBook:")];

		[item setImage:[NSImage imageNamed:@"remove-book"]];
		[item setLabel:NSLocalizedString (@"Remove Book", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Remove Book", nil)];

		removeBook = item;
	}
	else if ([itemIdentifier isEqualToString:@"new-book"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"newBook:")];

		[item setImage:[NSImage imageNamed:@"new-book"]];
		[item setLabel:NSLocalizedString (@"New Book", nil)];
		[item setPaletteLabel:NSLocalizedString (@"New Book", nil)];

		newBook = item;
	}
	else if ([itemIdentifier isEqualToString:@"preferences"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"preferences:")];

		[item setImage:[NSImage imageNamed:@"preferences"]];
		[item setLabel:NSLocalizedString (@"Preferences", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Preferences", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"get-info"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"getInfoWindow:")];

		[item setImage:[NSImage imageNamed:@"get-info"]];
		[item setLabel:NSLocalizedString (@"Get Info", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Get Info", nil)];
		
		getInfo = item;
	}
	else if ([itemIdentifier isEqualToString:@"get-cover"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"getCoverWindow:")];

		[item setImage:[NSImage imageNamed:@"get-cover"]];
		[item setLabel:NSLocalizedString (@"Show Cover", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Show Cover", nil)];
		
		getCover = item;
	}
	else if ([itemIdentifier isEqualToString:@"import"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"import:")];

		[item setImage:[NSImage imageNamed:@"import"]];
		[item setLabel:NSLocalizedString (@"Import Data", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Import Data", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"export"])
	{
//		[item setTarget:self];
//		[item setAction:NSSelectorFromString(@"getCoverWindow:")];

		[item setImage:[NSImage imageNamed:@"export"]];
		[item setLabel:NSLocalizedString (@"Export Data", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Export Data", nil)];
	}
	else if ([itemIdentifier isEqualToString:@"isight"])
	{
		[item setTarget:self];
		[item setAction:NSSelectorFromString(@"isight:")];

		[item setImage:[NSImage imageNamed:@"camera"]];
		[item setLabel:NSLocalizedString (@"Open Camera", nil)];
		[item setPaletteLabel:NSLocalizedString (@"Open Camera", nil)];
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

	
	return item;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:@"new-list", @"new-smartlist", @"edit-smartlist", @"new-book", @"remove-book", @"remove-list", @"preferences", 
		@"get-info", @"get-cover", @"import", @"export", @"search", @"isight", NSToolbarSeparatorItemIdentifier, 
		NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects:@"new-list", @"new-smartlist", @"edit-smartlist", @"new-book", @"remove-book", @"remove-list", NSToolbarSpaceItemIdentifier, 
	@"get-info", @"get-cover", NSToolbarFlexibleSpaceItemIdentifier, @"search", nil];
}

- (void) awakeFromNib
{
	NSToolbar * tb = [[NSToolbar alloc] initWithIdentifier:@"main"];
	
	[tb setDelegate:self];
	[tb setAllowsUserCustomization:YES];
	[tb setAutosavesConfiguration:YES];
	
	[mainWindow setToolbar:tb];
	
	NSButtonCell * checkbox = [[NSButtonCell alloc] init];
	[checkbox setButtonType:NSSwitchButton];
	[checkbox setTitle:@""];
	[checkbox setControlSize:NSSmallControlSize];
	
	[enabledColumn setDataCell:checkbox];

	NSArray * prefColumns = [prefFieldsTable tableColumns];
	
	int i = 0;
	for (i = 0; i < [prefColumns count]; i++)
	{
		NSTableColumn * column = [prefColumns objectAtIndex:i];
		
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}
	
	[self updateBooksTable:self];

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
		
		if ([[dict objectForKey:@"ascending"] isEqual:@"yes"])
			descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
		else
			descriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:NO];
	
		[sortDescriptors addObject:descriptor];
	}

	[booksTable setSortDescriptors:sortDescriptors];
	
	/* Resize Main Scroller */
	
	NSArray * viewRects = [defaults objectForKey:@"Main Scroller Sizes"];
	
	if (viewRects != nil)
	{
		NSArray * views = [splitView subviews];
        int i, count;

        count = MIN ([viewRects count], [views count]);

        for(i = 0; i < count; i++)
        {
			NSRect frame = NSRectFromString ([viewRects objectAtIndex:i]);

			if (NSIsEmptyRect (frame))
			{
				frame = [[views objectAtIndex:i] frame];
                        
				if([splitView isVertical])
					frame.size.width = 0;
				else
					frame.size.height = 0;
			}

			[[views objectAtIndex:i] setFrame:frame];
		}
	}

	viewRects = [defaults objectForKey:@"Left Scroller Sizes"];
	
	if (viewRects != nil)
	{
		NSArray * views = [leftView subviews];
        int i, count;

        count = MIN ([viewRects count], [views count]);

        for(i = 0; i < count; i++)
        {
			NSRect frame = NSRectFromString ([viewRects objectAtIndex:i]);

			if (NSIsEmptyRect (frame))
			{
				frame = [[views objectAtIndex:i] frame];
                        
				if([leftView isVertical])
					frame.size.width = 0;
				else
					frame.size.height = 0;
			}

			[[views objectAtIndex:i] setFrame:frame];
		}
	}

	viewRects = [defaults objectForKey:@"Right Scroller Sizes"];
	
	if (viewRects != nil)
	{
		NSArray * views = [rightView subviews];
        int i, count;

        count = MIN ([viewRects count], [views count]);

        for(i = 0; i < count; i++)
        {
			NSRect frame = NSRectFromString ([viewRects objectAtIndex:i]);

			if (NSIsEmptyRect (frame))
			{
				frame = [[views objectAtIndex:i] frame];
                        
				if([rightView isVertical])
					frame.size.width = 0;
				else
					frame.size.height = 0;
			}

			[[views objectAtIndex:i] setFrame:frame];
		}
	}

	NSString * filePath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory (),
								@"/Library/Application Support/Books/Files/", nil];

	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
		[[NSFileManager defaultManager] createDirectoryAtPath:filePath attributes:nil];

	[listsTable registerForDraggedTypes:[NSArray arrayWithObject:@"Books Book Type"]];

	[imageView setTarget:self];
	[imageView setAction:@selector(getCoverWindow:)];

	[mainWindow makeKeyAndOrderFront:self];
	
	[self updateMainPane];
	
	[[[NSApplication sharedApplication] delegate] startProgressWindow:NSLocalizedString (@"Loading data from disk...", nil)];
}

- (void) startProgressWindow: (NSString *) message
{
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
	[progressText setStringValue:message];
	
	[[NSApplication sharedApplication] beginSheet:progressView modalForWindow:mainWindow
		modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (void) endProgressWindow
{
	[[NSApplication sharedApplication] endSheet:progressView];
	[progressView orderOut:self];

	[progressIndicator stopAnimation:self];
}

- (void) updateMainPane
{
//	[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"BooksRefreshView" object:booksTable]];

	WebFrame * mainFrame = [detailsPane mainFrame];

	NSArray * selectedObjects = [bookArrayController selectedObjects];
	NSURL * localhost = [NSURL URLWithString:@"http://localhost/"];
	
	if (pageBuilder == nil)
		pageBuilder = [[HtmlPageBuilder alloc] init];

	NSString * htmlString = [pageBuilder buildEmptyPage];		

	if ([selectedObjects count] == 1)
	{
		BookManagedObject * object = [selectedObjects objectAtIndex:0];
		
		htmlString = [pageBuilder buildPageForObject:object];
	}
	else if ([selectedObjects count] > 1)
		htmlString = [pageBuilder buildPageForArray:selectedObjects];

	[mainFrame loadHTMLString:htmlString baseURL:localhost];
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	NSTableView * table = [notification object];

	if (table == booksTable)
	{
		if (loadData != nil)
		{
			[self loadDataFromOutside];
			loadData = nil;
		}

		[self updateMainPane];
	}
	else if (table == listsTable)
	{
		if ([progressView isVisible])
		{
			if ([table selectedRow] != -1)
				[self endProgressWindow];
		}

		NSArray * selectedObjects = [collectionArrayController selectedObjects];

		if ([selectedObjects count] > 0)
		{
			ListManagedObject * list = [selectedObjects objectAtIndex:0];
			
			if ([list isKindOfClass:[SmartList class]])
			{
				[newBook setAction:nil];
				[editSmartList setAction:NSSelectorFromString(@"editSmartList:")];
				[removeBook setAction:nil];
				[removeList setAction:NSSelectorFromString(@"removeList:")];
			}
			else
			{
				[newBook setAction:NSSelectorFromString(@"newBook:")];
				[editSmartList setAction:nil];
				[removeBook setAction:NSSelectorFromString(@"removeBook:")];
				[removeList setAction:NSSelectorFromString(@"removeList:")];
			}
		}
		else
		{
			[newBook setAction:nil];
			[editSmartList setAction:nil];
			[removeBook setAction:nil];
			[removeList setAction:nil];
		}

		[collectionArrayController setSortDescriptors:
			[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
		
		[self refreshComboBoxes:nil];
	}

	/* Work Here */
	
/*	NSSize boxSize = [imageBox frame].size;
	
	if (boxSize.height > 10)
		boxSize = NSMakeSize (boxSize.width, boxSize.width);
*/
	NSArray * books = [self getSelectedBooks];
		
	if ([books count] == 1) // && boxSize.height > 1)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];
			
		NSData * coverData = [book getCoverImage];
		
		if (coverData != nil)
		{
/*			NSImage * cover = [[NSImage alloc] initWithData:coverData];
				
			NSSize size = [cover size];

			if (size.width > 32 && size.height > 32)
			{
				float height = size.height * (boxSize.width / size.width);
				float width = boxSize.width;

				if (height > 32 && width > 32)
					boxSize = NSMakeSize (width, height);
			}

			[cover release];
*/
			[getCover setAction:NSSelectorFromString (@"getCoverWindow:")];
		}
		else
			[getCover setAction:nil];

/*		NSRect leftFrame = [leftView frame];
		NSRect boxFrame = [imageBox frame];

		NSLog (@"box: x = %f, y = %f, w = %f, h = %f", boxFrame.origin.x, boxFrame.origin.y, boxFrame.size.width, boxFrame.size.height);
		
		float listHeight = leftFrame.size.height - [leftView dividerThickness] - boxSize.height;

		NSLog (@"height = %f, box height = %f, lh = %f", leftFrame.size.height, boxSize.height, listHeight);

		[imageBox setFrame:NSMakeRect (0.0, listHeight, boxSize.width, boxSize.height - (boxFrame.size.height - boxSize.height))];
		[leftView adjustSubviews];
*/	}


//	[leftView setNeedsDisplay:YES];
	
	[coverWindow orderOut:self];
	[getCover setLabel:NSLocalizedString (@"Show Cover", nil)];
	
//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Snappy"])
}

- (void) refreshComboBoxes: (NSArray *) books
{
	if (books == nil)
	{
		NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
		[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[self managedObjectContext]]];

		NSError * error = nil;
		NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];
		
		if (results != nil)
			[self refreshComboBoxes:results];
		
		return;
	}

	[genreCombo removeAllItems];
	[authorsCombo removeAllItems];
	[editorsCombo removeAllItems];
	[illustratorsCombo removeAllItems];
	[translatorsCombo removeAllItems];
	[publisherCombo removeAllItems];

	NSMutableSet * genres = [NSMutableSet set];
	NSMutableSet * authors = [NSMutableSet set];
	NSMutableSet * editors = [NSMutableSet set];
	NSMutableSet * illustrators = [NSMutableSet set];
	NSMutableSet * translators = [NSMutableSet set];
	NSMutableSet * publishers = [NSMutableSet set];
	NSMutableSet * userFieldNames = [NSMutableSet set];

	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
		
	NSNumber * useDefaultGenres = [defaults valueForKey:@"Use Default Genres"];

	if (useDefaultGenres == nil || [useDefaultGenres boolValue])
	{
		[genres addObject:NSLocalizedString (@"Biography", nil)];
		[genres addObject:NSLocalizedString (@"Fantasy", nil)];
		[genres addObject:NSLocalizedString (@"Fairy Tales", nil)];
		[genres addObject:NSLocalizedString (@"Historical Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Myths & Legends", nil)];
		[genres addObject:NSLocalizedString (@"Poetry", nil)];
		[genres addObject:NSLocalizedString (@"Science Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Folk Tales", nil)];
		[genres addObject:NSLocalizedString (@"Mystery", nil)];
		[genres addObject:NSLocalizedString (@"Non-Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Realistic Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Short Stories", nil)];
	}

	NSString * customGenres = [defaults valueForKey:@"Custom Genres"];
			
	if (customGenres != nil)
	{
		NSArray * genreStrings = [customGenres componentsSeparatedByString:@"\n"];
				
		int j = 0;
		for (j = 0; j < [genreStrings count]; j++)
			[genres addObject:[genreStrings objectAtIndex:j]];
	}
				
	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];
		
		NSString * genreString = [book valueForKey:@"genre"];
		NSString * authorString = [book valueForKey:@"authors"];
		NSString * editorString = [book valueForKey:@"editors"];
		NSString * illustratorString = [book valueForKey:@"illustrators"];
		NSString * translatorString = [book valueForKey:@"translators"];
		NSString * publisherString = [book valueForKey:@"publisher"];

		if (genreString != nil)
			[genres addObject:genreString];

		if (authorString != nil)
			[authors addObject:authorString];

		if (editorString != nil)
			[editors addObject:editorString];

		if (illustratorString != nil)
			[illustrators addObject:illustratorString];

		if (translatorString != nil)
			[translators addObject:translatorString];

		if (publisherString != nil)
			[publishers addObject:publisherString];

		NSMutableSet * userFields = [book mutableSetValueForKey:@"userFields"];
		NSArray * allFields = [userFields allObjects];
		
		int j = 0;
		for (j = 0; j < [allFields count]; j++)
		{
			NSManagedObject * field = [allFields objectAtIndex:j];
			
			NSString * fieldString = [field valueForKey:@"key"];
			
			if (fieldString != nil)
				[userFieldNames addObject:fieldString];
		}
		
	}

	NSArray * lists = [NSArray arrayWithObjects:genres, authors, editors, illustrators, translators, publishers, userFieldNames, nil];
	NSArray * listCombos = [NSArray arrayWithObjects:genreCombo, authorsCombo, editorsCombo, illustratorsCombo, 
								translatorsCombo, publisherCombo, userFieldCombo, nil];

	for (i = 0; i < [lists count] && i < [listCombos count]; i++)
	{
		NSMutableArray * array = [NSMutableArray arrayWithArray:[[lists objectAtIndex:i] allObjects]];
		[array sortUsingSelector:@selector(compare:)];
		
		int j = 0;
		for (j = 0; j < [array count]; j++)
			[[listCombos objectAtIndex:i] addItemWithObjectValue:[array objectAtIndex:j]];
	}
}

- (IBAction)preferences:(id)sender
{
	if ([preferencesWindow isVisible])
		[preferencesWindow orderOut:sender];
	else
		[preferencesWindow makeKeyAndOrderFront:sender];
}

- (NSArray *) getQuickfillPlugins
{
	if (quickfillPlugins == nil)
		[self initQuickfillPlugins];

	return [[quickfillPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) setQuickfillPlugins: (NSArray *) list
{

}

- (void) initQuickfillPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	quickfillPlugins = [[NSMutableDictionary alloc] init];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"plugin"])
			{
				NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
				
				NSDictionary * pluginDict = [plugin infoDictionary];
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Quickfill"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[quickfillPlugins setObject:plugin forKey:pluginName];
				}
			}
		}
	}
}

- (IBAction) quickfill: (id)sender
{
	if (quickfillPlugins == nil)
		[self initQuickfillPlugins];
		
	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Quickfill Plugin"];

	if (pluginKey == nil || [pluginKey isEqualToString:@""])
	{
		NSRunAlertPanel (NSLocalizedString (@"No Quickfill Plugin Selected", nil),  
			NSLocalizedString (@"No quickfill plugins have been selected. Select one in the preferences.", nil), NSLocalizedString (@"OK", nil), nil, nil);
		
		return;
	}

	NSArray * books = [self getSelectedBooks];

	if (books != nil && [books count] == 1)
	{
		[self startQuickfill];

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];
		NSBundle * quickfillPlugin = (NSBundle *) [quickfillPlugins objectForKey:pluginKey];

		if (quickfillPlugin == nil)
		{
			[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"Default Quickfill Plugin"];
			[self quickfill:sender];
			return;
		}

		quickfill = [[QuickfillPluginInterface alloc] init];

		[quickfill importFromBundle:quickfillPlugin forBook:book replace:NO];
	}
	else
		NSRunAlertPanel (NSLocalizedString (@"Too Many Books Selected", nil),  NSLocalizedString (@"Only one book may be quickfilled at a time.", nil), NSLocalizedString (@"OK", nil), nil, nil);
}

- (void) startQuickfill
{
	if ([infoWindow isVisible])
	{
		[quickfillProgress startAnimation:self];
		[NSApp beginSheet:quickfillWindow modalForWindow:infoWindow modalDelegate:self didEndSelector:nil contextInfo:NULL];
	}
}

- (IBAction) cancelQuickfill: (id) sender
{
	if (quickfill != nil)
		[quickfill killTask];
}

- (void) stopQuickfill
{
	[quickfill release];
	quickfill = nil;
	
	if ([infoWindow isVisible])
	{
		[NSApp endSheet:quickfillWindow];

		[quickfillWindow orderOut:self];
		[quickfillProgress stopAnimation:self];
	}
}

- (NSArray *) getImportPlugins
{
	if (importPlugins == nil)
		[self initImportPlugins];

	return [[importPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) initImportPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	importPlugins = [[NSMutableDictionary alloc] init];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"app"])
			{
				NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
				
				NSDictionary * pluginDict = [plugin infoDictionary];
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Import"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[importPlugins setObject:plugin forKey:pluginName];
				}
			}
		}
	}
}

- (void) setImportPlugins: (NSArray *) list
{

}

- (IBAction) import: (id)sender
{
	if (importPlugins == nil)
		[self initImportPlugins];
		
	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Import Plugin"];

	if (pluginKey == nil || [pluginKey isEqualToString:@""])
	{
		// NSAlert
		
		return;
	}

	NSBundle * importPlugin = (NSBundle *) [importPlugins objectForKey:pluginKey];
	
	ImportPluginInterface * import = [[ImportPluginInterface alloc] init];
	
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"importFromBundle:") toTarget:import withObject:importPlugin];
}

- (NSArray *) getExportPlugins
{
	if (exportPlugins == nil)
		[self initExportPlugins];
		
	return [[exportPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) setExportPlugins: (NSArray *) list
{

}

- (void) initExportPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	exportPlugins = [[NSMutableDictionary alloc] init];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"app"])
			{
				NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
				
				NSDictionary * pluginDict = [plugin infoDictionary];
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Export"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[exportPlugins setObject:plugin forKey:pluginName];
				}
			}
		}
	}
}


- (NSArray *) getDisplayStyles
{
	if (pageBuilder == nil)
		pageBuilder = [[HtmlPageBuilder alloc] init];

	NSArray * plugins = [[pageBuilder getDisplayPlugins] allKeys];
	
	return plugins;
}

- (void) setDisplayStyles: (NSArray *) list
{

}

- (void) windowWillClose: (NSNotification *) notification
{
	NSWindow * window = (NSWindow *) [notification object];

	if (window == mainWindow)
	{
		[self saveAction:self];

		[[NSApplication sharedApplication] terminate:self];
	}
	else if (window == infoWindow)
	{
		[getInfo setLabel:NSLocalizedString (@"Get Info", nil)];
	}
	else if (window == coverWindow)
	{
		[getCover setLabel:NSLocalizedString (@"Show Cover", nil)];
	}
}

- (IBAction)updateBooksTable:(id)sender;
{
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	
	NSArray * newColumns = [prefs arrayForKey:@"Display Fields"];

	NSArray * oldColumns = [NSArray arrayWithArray:[listsTable tableColumns]];

	if ([oldColumns count] == 0)
	{
		NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:@"icon"];
		[[column headerCell] setStringValue:@""];
		[column setDataCell:[[NSImageCell alloc] init]];
		[column bind:@"data" toObject:collectionArrayController withKeyPath:@"arrangedObjects.icon" options: nil];
		[column setWidth:16.0];
		[column setResizingMask:NSTableColumnNoResizing];
		
		[listsTable addTableColumn:column];

		column = [[NSTableColumn alloc] initWithIdentifier:@"name"];
		[[column headerCell] setStringValue:@"Lists"];
		[column bind:@"value" toObject:collectionArrayController withKeyPath:@"arrangedObjects.name" options: nil];
		[column setResizingMask:NSTableColumnAutoresizingMask];
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
		[listsTable addTableColumn:column];
		[column setWidth:([listsTable frame].size.width - 16)];
		[collectionArrayController setSortDescriptors:
			[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
	}

	[collectionArrayController setSortDescriptors:
		[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];

	oldColumns = [NSArray arrayWithArray:[booksTable tableColumns]];
	
	int i = 0;
	
	for (i = 0; i < [oldColumns count]; i++)
		[booksTable removeTableColumn:[oldColumns objectAtIndex:i]];

	if ([newColumns count] == 0)
	{
		NSMutableDictionary * title = [NSMutableDictionary dictionary];
		[title setValue:@"title" forKey:@"Key"];
		[title setValue:NSLocalizedString (@"Title", nil) forKey:@"Title"];
		[title setValue:[NSNumber numberWithInt:1] forKey:@"Enabled"];

		newColumns = [NSArray arrayWithObject:title];
	}
	
	NSString * dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"Custom Date Format"];

	for (i = 0; i < [newColumns count]; i++)
	{
		NSDictionary * dict = [newColumns objectAtIndex:i];

		NSString * key = [dict objectForKey:@"Key"];
		NSString * title = NSLocalizedString ([dict objectForKey:@"Title"], nil);
		NSString * enabled = [[dict objectForKey:@"Enabled"] description];

		if ([enabled isEqualToString:@"1"])
		{
			NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:key];
		
			[[column headerCell] setStringValue:title];
			[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
			
			[column bind:@"value" toObject:bookArrayController withKeyPath:[@"arrangedObjects." stringByAppendingString:key] 
			options: nil];
			
			if ([key isEqualToString:@"publishDate"] || 
				[key isEqualToString:@"dateLent"] ||
				[key isEqualToString:@"dateDue"] ||
				[key isEqualToString:@"dateFinished"] ||
				[key isEqualToString:@"dateAcquired"] ||
				[key isEqualToString:@"dateStarted"] )
			{
				[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];

				NSDateFormatter * formatter;
				
				if (dateFormat != nil)
					formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:NO];
				else
				{
					formatter = [[NSDateFormatter alloc] init];
					[formatter setDateStyle:NSDateFormatterLongStyle];
				}
				
				[[column dataCell] setFormatter:formatter];

				NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
				
				[column setSortDescriptorPrototype:sortDescriptor];
			}
			else
			{
				NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
				
				[column setSortDescriptorPrototype:sortDescriptor];
			}

			[column setEditable:NO];
			
			[booksTable addTableColumn:column];
		}
	}

	
	NSString * customString = [prefs objectForKey:@"Custom User Display Fields"];

	if (customString != nil && ![customString isEqual:@""])
	{
		NSArray * fields = [customString componentsSeparatedByString:@"\n"];

		for (i = 0; i < [fields count]; i++)
		{
			NSString * field = [fields objectAtIndex:i];

			NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:field];
		
			[[column headerCell] setStringValue:field];
			[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
			
			[column bind:@"value" toObject:bookArrayController 
				withKeyPath:[@"arrangedObjects." stringByAppendingString:field] options: nil];
			
			NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:field ascending:YES];
				
			[column setSortDescriptorPrototype:sortDescriptor];

			[column setEditable:NO];
			
			[booksTable addTableColumn:column];
		}
	}		
	
	[booksTable setDoubleAction:@selector(getInfoWindow:)];
}

- (IBAction) save: (id)sender
{
    NSError *error = nil;

    if (![[self managedObjectContext] save:&error]) 
	{
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)newSmartList:(id)sender
{
	[collectionArrayController rearrangeObjects];

	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"SmartList"];

	SmartList * sc = [[SmartList alloc] initWithEntity:desc insertIntoManagedObjectContext:context];
	[sc setValue:NSLocalizedString (@"New Smart List", nil) forKey:@"name"];
	
	[context lock];
	[context insertObject:sc];
	[context unlock];

	[listsTable reloadData];

	NSPredicate * newPredicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] \"Book\""];
	NSString * name = @"New Smart List";

	NSArray * lists = [collectionArrayController arrangedObjects];
	
	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		NSString * listName = [[lists objectAtIndex:i] valueForKey:@"name"];
		
		if ([[lists objectAtIndex:i] isMemberOfClass:[SmartList class]])
		{
			SmartList * list = [lists objectAtIndex:i];
			
			if ([newPredicate isEqual:[list getPredicate]]  && [name isEqual:listName])
				[collectionArrayController setSelectedObjects:[NSArray arrayWithObject:list]];
		}
	}
	
	[self editSmartList:sender];
}

- (IBAction) newList:(id) sender
{
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"List"];

	[context lock];
	ListManagedObject * object = [[ListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

	[object setValue:NSLocalizedString (@"New List", nil) forKey:@"name"];
			
	[context insertObject:object];

	[context unlock];

	[collectionArrayController setSortDescriptors:
		[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];

	[listsTable reloadData];
}

- (IBAction) newBook:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] < 1)
	{

	}
	else if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartList class]])
		{

		}
		else
		{
			NSManagedObjectContext * context = [self managedObjectContext];
			NSManagedObjectModel * model = [self managedObjectModel];

			NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"Book"];

			[context lock];
			BookManagedObject * object = [[BookManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

			[object setValue:NSLocalizedString (@"New Book", nil) forKey:@"title"];
			
			[context insertObject:object];

			[bookArrayController addObject:object];
			[context unlock];

			[booksTable reloadData];

			if (![infoWindow isVisible])
			{
				[self getInfoWindow:nil];
			}

			[self refreshComboBoxes:nil];
		}
	}
	else
	{

	}
}

- (IBAction) removeBook:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] < 1)
	{

	}
	else if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartList class]])
		{

		}
		else
		{
			int choice = NSRunAlertPanel (NSLocalizedString (@"Delete Selected Books?", nil), 
							NSLocalizedString (@"Are you sure you want to delete the selected books?", nil), NSLocalizedString (@"No", nil), 
							NSLocalizedString (@"Yes", nil), nil);

			if (choice == NSAlertAlternateReturn)
				[bookArrayController remove:self];
		}
	}
}

- (IBAction) removeList:(id) sender
{
	[[[searchTextField cell] cancelButtonCell] performClick:self];
	
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartList class]])
			[collectionArrayController remove:self];
		else
		{
			NSMutableSet * items = [list mutableSetValueForKey:@"items"];

			if ([items count] != 0)
			{
				int choice = NSRunAlertPanel (NSLocalizedString (@"Delete Non-Empty List?", nil), 
								NSLocalizedString (@"Are you sure you want to delete this list? It still contains items.", nil), 
								NSLocalizedString (@"No", nil), NSLocalizedString (@"Yes", nil), nil);
					
				if (choice == NSAlertAlternateReturn)
				{
					[bookArrayController setSelectedObjects:[bookArrayController arrangedObjects]];
					[bookArrayController remove:self];
					
					[collectionArrayController remove:self];
				}
			}
			else
				[collectionArrayController remove:self];
		}
	}
}

- (IBAction) editSmartList:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartList class]])
		{
			[[smartListEditorWindow delegate] setPredicate:[((SmartList *)list) getPredicate]];

			[[NSApplication sharedApplication] beginSheet:smartListEditorWindow modalForWindow:mainWindow
					modalDelegate:self didEndSelector:nil contextInfo:NULL];
		}
	}
}

- (IBAction) saveSmartList:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];

		[list willChangeValueForKey:@"items"];
		
		if ([list isKindOfClass:[SmartList class]])
		{
			NSPredicate * p = [[smartListEditorWindow delegate] getPredicate];
			
			[((SmartList *)list) setPredicate:p];
		}
		
		[list didChangeValueForKey:@"items"];

		NSIndexSet * selection = [collectionArrayController selectionIndexes];

		[collectionArrayController setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
		[collectionArrayController setSelectionIndexes:selection];
	}

	[booksTable reloadData];
	
//	[[NSApplication sharedApplication] endModalSession:session];
	[[NSApplication sharedApplication] endSheet:smartListEditorWindow];
	[smartListEditorWindow orderOut:self];
}

- (IBAction) cancelSmartList:(id) sender
{
	[[NSApplication sharedApplication] endSheet:smartListEditorWindow];
	[smartListEditorWindow orderOut:self];
}


- (NSArray *) getSelectedBooks
{
	NSArray * selectedObjects = [bookArrayController selectedObjects];
	
	if ([selectedObjects count] > 0)
		return selectedObjects;
		
	return [bookArrayController arrangedObjects];
}

- (NSArray *) getAllBooks
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"title != \"\""];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[self managedObjectContext]]];
	[fetch setPredicate:predicate];

	NSError * error = nil;
	NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	return [results retain];
}

- (NSArray *) getAllLists
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"name != \"\""];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"List" inManagedObjectContext:[self managedObjectContext]]];
	[fetch setPredicate:predicate];

	NSError * error = nil;
	NSMutableArray * results = [NSMutableArray array];
	
	NSArray * fetchedItems = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	int i = 0;
	for (i = 0; i < [fetchedItems count]; i++)
	{
		if (![[fetchedItems objectAtIndex:i] isKindOfClass:[SmartList class]])
			[results addObject:[fetchedItems objectAtIndex:i]];
	}
	
	return [results retain];
}

- (NSArray *) getAllSmartLists
{
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"name != \"\""];
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"SmartList" inManagedObjectContext:[self managedObjectContext]]];
	[fetch setPredicate:predicate];

	NSError * error = nil;
	NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];

	return [results retain];
}

- (void) selectListsTable: (id) sender
{
	[mainWindow makeFirstResponder:listsTable];
}

- (void) selectBooksTable: (id) sender
{
	[mainWindow makeFirstResponder:booksTable];
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
	if ([key isEqualToString:@"selectedList"])
		return YES;

	if ([key isEqualToString:@"booklists"])
		return YES;

	if ([key isEqualToString:@"selectedBooks"])
		return YES;
	
	return NO;
}

- (ListManagedObject *) getSelectedList
{
	return [[collectionArrayController selectedObjects] objectAtIndex:0];
}

- (void) setSelectedList: (ListManagedObject *) list
{
	[collectionArrayController setSelectedObjects:[NSArray arrayWithObject:list]];
}

- (NSArray *) getBooklists
{
	return [collectionArrayController arrangedObjects];
}

- (id) asCreateNewList:(NSString *) listName
{
	NSLog (@" creating as new list");
	
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"List"];

	[context lock];
	ListManagedObject * object = [[ListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

	if (listName != nil)
		[object setValue:listName forKey:@"name"];	
	else
		[object setValue:@"New List" forKey:@"name"];
		
	[collectionArrayController addObject:object];
	
	[context unlock];

	[listsTable reloadData];

	return object;
}

- (id) asCreateNewSmartList:(NSString *) listName
{
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"SmartList"];

	[context lock];
	SmartList * object = [[SmartList alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

	if (listName != nil)
		[object setValue:listName forKey:@"name"];	
	else
		[object setValue:@"New Smart List" forKey:@"name"];
		
	[collectionArrayController addObject:object];
	
	[context unlock];

	[listsTable reloadData];

	return object;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	loadData = [[NSData dataWithContentsOfFile:filename] retain];
	
	[self loadDataFromOutside];
	
	return YES;
}

- (void) loadDataFromOutside
{
	NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;

	NSString * error = nil;
	
	NSDictionary * metadata = [NSPropertyListSerialization propertyListFromData:loadData mutabilityOption:NSPropertyListImmutable 
									format:&format errorDescription:&error];

	NSArray * lists = [collectionArrayController arrangedObjects];
	
	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		NSString * name = [[lists objectAtIndex:i] valueForKey:@"name"];
		
		if ([name isEqualToString:[metadata valueForKey:@"listName"]])
		{
			[collectionArrayController setSelectedObjects:[NSArray arrayWithObject:[lists objectAtIndex:i]]];
		}
	}
	
	NSArray * books = [bookArrayController arrangedObjects];
	
	for (i = 0; i < [books count]; i++)
	{
		NSString * id = [[books objectAtIndex:i] valueForKey:@"id"];
		
		if ([id isEqualToString:[metadata valueForKey:@"id"]])
		{
			[bookArrayController setSelectedObjects:[NSArray arrayWithObject:[books objectAtIndex:i]]];
		}
	}
}

- (IBAction) updateSpotlightIndex: (id) sender
{
	[self startProgressWindow:NSLocalizedString (@"Updating Spotlight index...", nil)];

	NSArray * lists = [collectionArrayController arrangedObjects];
	
	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		ListManagedObject * list = [lists objectAtIndex:i];
		
		if (![list isKindOfClass:[SmartList class]])
		{
			NSArray * books = [list getBooks];
	
			int j = 0;
			for (j = 0; j < [books count]; j++)
			{
				BookManagedObject * book = [books objectAtIndex:j];
				
				[book writeSpotlightFile];
			}
		}
	}

	[self endProgressWindow];
}

- (IBAction) clearSpotlightIndex: (id) sender
{
	BOOL isDir;
	NSString * path = [NSString stringWithFormat:@"%@%@", NSHomeDirectory (),
						@"/Library/Caches/Metadata/Books"];

	NSFileManager * manager = [NSFileManager defaultManager];

	if ([manager fileExistsAtPath:path isDirectory:&isDir])
		[manager removeFileAtPath:path handler:nil];
}

- (IBAction) listQuickfill: (id)sender
{
	int code = NSRunInformationalAlertPanel (NSLocalizedString (@"Batch Quickfill", nil), 
				NSLocalizedString (@"Keep or overwrite existing values?", nil), 
				NSLocalizedString (@"Keep", nil), NSLocalizedString (@"Cancel", nil), 
				NSLocalizedString (@"Overwrite", nil));

	if (code == NSAlertAlternateReturn)
	{
		return;
	}

	[self save:sender];
	
	if (quickfillPlugins == nil)
		[self initQuickfillPlugins];

	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Quickfill Plugin"];

	if (pluginKey == nil || [pluginKey isEqualToString:@""])
	{
		NSRunAlertPanel (NSLocalizedString (@"No Quickfill Plugin Selected", nil),  NSLocalizedString (@"No quickfill plugins have been selected. Select one in the preferences.", nil), NSLocalizedString (@"OK", nil), nil, nil);
		
		return;
	}

	NSBundle * quickfillPlugin = (NSBundle *) [quickfillPlugins objectForKey:pluginKey];
	
	NSArray * books = [bookArrayController arrangedObjects];

	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];

	NSString * message = [NSString stringWithFormat:NSLocalizedString (@"Batch quickfilling %d items...", nil), [books count], nil];

	[progressText setStringValue:message];
	
	[[NSApplication sharedApplication] beginSheet:progressView modalForWindow:mainWindow
		modalDelegate:self didEndSelector:nil contextInfo:NULL];

	quickfill = [[QuickfillPluginInterface alloc] init];

	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		[self startQuickfill];

		BOOL replace = NO;
		
		if (code == NSAlertOtherReturn)
			replace = YES;

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];

		message = [NSString stringWithFormat:NSLocalizedString (@"Quickfilling item %d of %d...", nil), i + 1, [books count], nil];
		[progressText setStringValue:message];
		[progressText setNeedsDisplay:YES];
		[progressView display];

		[quickfill batchImportFromBundle:quickfillPlugin forBook:book replace:replace];
	}

	[[NSApplication sharedApplication] endSheet:progressView];
	[progressView orderOut:self];
	[progressIndicator stopAnimation:self];
}

- (IBAction) openFiles: (id) sender
{
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1)
	{
		NSArray * selectedFiles = [fileArrayController selectedObjects];

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		NSString * filePath = [NSString stringWithFormat:@"%@%@%@/", NSHomeDirectory (),
								@"/Library/Application Support/Books/Files/", [book getObjectIdString], nil];
	
		int i = 0;
		for (i = 0; i < [selectedFiles count]; i++)
		{
			NSDictionary * entry = [selectedFiles objectAtIndex:i];

			if (![[NSWorkspace sharedWorkspace] openFile:[entry valueForKey:@"Location"]])
				[[NSWorkspace sharedWorkspace] openFile:[filePath stringByAppendingPathComponent:[entry valueForKey:@"Location"]]];
		}
	}
}

- (IBAction) trashFiles: (id) sender
{
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1)
	{
		NSArray * selectedFiles = [fileArrayController selectedObjects];

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		int i = 0;
		for (i = 0; i < [selectedFiles count]; i++)
		{
			NSDictionary * entry = [selectedFiles objectAtIndex:i];
			
			[book removeFile:entry];
		}
	}
}

- (IBAction) uploadFile: (id) sender
{
	NSString * sourceFile = [fileLocation stringValue];
	NSString * sourceName = [fileTitle stringValue];
	NSString * sourceDesc = [fileDescription stringValue];
	
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		[book addNewFile:sourceFile title:sourceName description:sourceDesc];
		
		[fileLocation setStringValue:@""];
		[fileTitle setStringValue:@""];
		[fileDescription setStringValue:@""];
	}
}

- (IBAction) browseFile: (id) sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:nil];
	[openPanel setAllowsMultipleSelection:NO];
	
	int result = [openPanel runModalForTypes:nil];
	
	if (result == NSOKButton)
	{
		NSString * filename = [openPanel filename];
		
		[fileLocation setStringValue:filename];
	}
}

- (IBAction) viewOnline:(id) sender
{
	NSArray * books = [self getSelectedBooks];

	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSString * siteUrl = [defaults objectForKey:@"Site URL"];
	
	if (siteUrl == nil)
		siteUrl = NSLocalizedString (@"http://www.google.com/search?q=*isbn*", nil);
	
	int i = 0;
	
	if ([books count] > 10)
		NSRunAlertPanel (NSLocalizedString (@"Too Many Books Selected", nil), 
			NSLocalizedString (@"More than ten books have been selected. Only opening the first ten...", nil), 
			NSLocalizedString (@"OK", nil), nil, nil);

	for (i = 0; i < [books count] && i < 10; i++)
	{
		NSString * isbn = [[books objectAtIndex:i] valueForKey:@"isbn"];
		
		if (isbn != nil)
		{
			NSMutableString * urlString = [NSMutableString stringWithString:siteUrl];
			
			[urlString replaceOccurrencesOfString:@"*isbn*" withString:isbn options:NSCaseInsensitiveSearch 
				range:NSMakeRange (0, [urlString length])];
				
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
		}
	}
}

- (QuickfillSearchWindow *) getQuickfillResultsWindow;
{
	return quickfillResultsWindow;
}

- (IBAction) isight: (id)sender
{
/*
	if (![iSightWindow isVisible])
	{
		[iSightWindow makeKeyAndOrderFront:sender];
		[iSightView startRendering];
	}
	else
	{
		NSArray * selected = [self getSelectedBooks];
	
		NSImage * image = [iSightView valueForOutputKey:@"ImageOutput"];
		
		if ([selected count] == 1)
			[((BookManagedObject *) [selected objectAtIndex:0]) setValue:[image TIFFRepresentation] forKey:@"coverImage"];

		NSSize mySize = [image size];
		
		int row, column, widthInPixels = mySize.width, heightInPixels = mySize.height;

		NSBitmapImageRep *blackAndWhiteRep = 
		[[NSBitmapImageRep alloc] 
			initWithBitmapDataPlanes: nil  // Nil pointer tells the kit to allocate the pixel buffer for us.
			pixelsWide: widthInPixels 
			pixelsHigh: heightInPixels
			bitsPerSample: 8
			samplesPerPixel: 2  
			hasAlpha: YES
			isPlanar: NO 
			colorSpaceName: NSCalibratedWhiteColorSpace // 0 = black, 1 = white in this color space.
			bytesPerRow: 0     // Passing zero means "you figure it out."
			bitsPerPixel: 16];  // This must agree with bitsPerSample and samplesPerPixel.
  
		monochromePixel * pixels = (monochromePixel *) [blackAndWhiteRep bitmapData];  // -bitmapData returns a void*, not an NSData object ;-)

		[image lockFocus]; // necessary for NSReadPixel() to work.
	
		for (row = 0; row < heightInPixels; row++)
		{
			for (column = 0; column < widthInPixels; column++)
			{
				monochromePixel * thisPixel = &(pixels[((widthInPixels * row) + column)]);
									
				NSColor  * pixelColor = NSReadPixel (NSMakePoint (column, heightInPixels - (row +1)));
							
				thisPixel->grayValue = rint (255 *   // use this line for positive...
					(0.299 * [pixelColor redComponent]
					+ 0.587 * [pixelColor greenComponent]
					+ 0.114 * [pixelColor blueComponent]));
									
				thisPixel->alpha = ([pixelColor alphaComponent]  * 255); // handle the transparency, too
			}
		}

		[image unlockFocus];

		float linePixels[320];
		float lineDeriv[320];

		float white = 0;
		float lastWhite = 0;

		for (column = 0; column < widthInPixels; column++)
		{
			NSColor * color = [blackAndWhiteRep colorAtX:column y:120];
	
			white = [color whiteComponent];

			linePixels[column] = white;
			lineDeriv[column] = lastWhite - white;

			NSLog (@"%3d %1.4f - %1.4f", column, linePixels[column], lineDeriv[column]);
			
			lastWhite = white;
		}

		NSLog (@"\n\n");

		[iSightWindow orderOut:sender];
		[iSightView stopRendering];
	}
*/
		
	MyBarcodeScanner *iSight = [MyBarcodeScanner sharedInstance];
	[iSight setStaysOpen:NO];
	[iSight setDelegate:self];
	
	[iSight setMirrored:YES];
	
	[iSight scanForBarcodeWindow:nil];
}


- (void)gotBarcode:(NSString *)barcode 
{
	if (([barcode length] == 13 || [barcode length] == 18) && [barcode rangeOfString:@"?"].location == NSNotFound)
	{
		NSArray * selected = [self getSelectedBooks];
		
		if ([selected count] == 1)
		{
			BookManagedObject * book = (BookManagedObject *) [selected objectAtIndex:0];
			
			[book setValue:barcode forKey:@"isbn"];
		}
	}
}


@end
