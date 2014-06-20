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

#import <QTKit/QTKit.h>

#import "BooksDefines.h"
#import "BooksAppDelegate.h"
#import "ImportPluginInterface.h"
#import "ExportPluginInterface.h"
#import "QuickfillPluginInterface.h"
#import "HtmlPageBuilder.h"
#import "SmartListManagedObject.h"
#import "BookManagedObject.h"
#import "MyBarcodeScanner.h"
#import "CoverWindowDelegate.h"
#import "NotificationInterface.h"
#import "BooksLibraryCompactor.h"
#import "BooksDataFolder.h"

#define CAMERA @"Camera"
#define CAMERA_ID @"Camera_ID"
#define CAMERA_NAME @"Camera_Name"

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

/* - (NSString *) applicationSupportFolder 
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
} */

- (BOOL) leopardOrBetter
{
	return leopardOrBetter;
}

- (BooksAppDelegate *) init
{
	if (self = [super init])
	{
		leopardOrBetter = NO;

		SInt32 MacVersion;
		
		if (Gestalt (gestaltSystemVersion, &MacVersion) == noErr)
		{
			if (MacVersion >= 0x1053)
				leopardOrBetter = YES;
		}
	}
	
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (NSManagedObjectContext *) managedObjectContext
{
    NSError * error = nil;
    NSString * applicationSupportFolder = nil;
    NSURL * url;
    NSFileManager * fileManager;
    NSPersistentStoreCoordinator * coordinator;
    
    if (managedObjectContext) 
	{
        return managedObjectContext;
    }
    
	fileManager = [NSFileManager defaultManager];
    // applicationSupportFolder = [self applicationSupportFolder];
    applicationSupportFolder = [BooksDataFolder booksDataFolder];
    
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
	[fetch release];
	
	if (results == nil || [results count] == 0)
	{
		NSEntityDescription * collectionDesc = [[[self managedObjectModel] entitiesByName] objectForKey:@"List"];
		NSEntityDescription * bookDesc = [[[self managedObjectModel] entitiesByName] objectForKey:@"Book"];

		[managedObjectContext lock];
		
		ListManagedObject * listObject = [[ListManagedObject alloc] initWithEntity:collectionDesc 
											insertIntoManagedObjectContext:managedObjectContext];

		[listObject setValue:NSLocalizedString (@"My Books", nil) forKey:@"name"];

		NSMutableSet * items = [listObject mutableSetValueForKey:@"items"];
		[listObject release];
		
		BookManagedObject * bookObject = [[BookManagedObject alloc] initWithEntity:bookDesc insertIntoManagedObjectContext:managedObjectContext];

		[bookObject setValue:NSLocalizedString (@"New Book", nil) forKey:@"title"];
		[items addObject:bookObject];
		[bookObject release];

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
		NSLog (@"error %@", error);
		
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) sender 
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	[tableViewDelegate save];

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

    NSError *error = nil;
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
	
	ListManagedObject * list = [[collectionArrayController selectedObjects] objectAtIndex:0];
	
	NSArray * books = [bookArrayController selectedObjects];
	
	[defaults setObject:[[[list objectID] URIRepresentation] description] forKey:@"Last Open List"];

	NSMutableArray * openBooks = [NSMutableArray array];

	int i = 0;
	for (i = 0; i < [books count]; i++)
		[openBooks addObject:[[[[books objectAtIndex:i] objectID] URIRepresentation] description]];

	[defaults setObject:openBooks forKey:@"Last Open Books"];

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

- (void) getInfoWindow
{
	[self getInfoWindow:self];
}

- (IBAction) getInfoWindow: (id) sender
{
	if ([infoWindow isKeyWindow])
	{
		[infoWindow orderOut:sender];
		[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Get Info", nil)];
	}
	else
	{
		[infoWindow makeKeyAndOrderFront:sender];
		[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Hide Info", nil)];
	}
}


- (IBAction) getCoverWindow: (id) sender
{
	if ([coverWindow isVisible])
	{
		[coverWindow orderOut:sender];
		[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Show Cover", nil)];
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
				
				NSImageRep * rep = [cover bestRepresentationForDevice:nil];

				NSSize size = NSMakeSize ([rep pixelsWide], [rep pixelsHigh]);
				[coverWindow setContentSize:size];
				[coverWindow setContentAspectRatio:size];
				[coverWindow setContentMaxSize:NSMakeSize(size.width * 2, size.height * 2)];
				
				[cover release];
				
				[coverWindow center];
				[coverWindow makeKeyAndOrderFront:sender];
				[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Hide Cover", nil)];
			}
		}
	}
}


- (IBAction) doExport:(id) sender
{
	ExportPluginInterface * export = [[ExportPluginInterface alloc] init];
	
	NSBundle * exportPlugin = nil;
	
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"ExportToBundle") toTarget:export withObject:exportPlugin];
	[export release];
}

- (void) setControlsView: (NSNotification *) msg
{
	ViewControls * controls = [msg object];

	if (controls == nil)
		controls = defaultViewControls;
	
	NSView * view = [controls view];
	NSRect viewRect = [view frame];
	
	NSRect oldRect = [[controlsPanel contentView] frame];
	NSRect newRect = [controlsPanel frameRectForContentRect:viewRect];
	newRect.origin = [controlsPanel frame].origin;

	if ([controlsPanel contentView] != nil)
		newRect.origin.y -= viewRect.size.height - oldRect.size.height;
	
	[controlsPanel setContentView:view];
	[controlsPanel setFrame:newRect display:YES animate:YES];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener
{
	if ([[[request URL] scheme] isEqual:@"file"] || [[[request URL] host] isEqual:@"localhost"])
	{
		[listener use];
	}
	else 
	{
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
}

- (void) awakeFromNib
{
	[detailsPane setPolicyDelegate:self];
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSToolbar * tb = [[NSToolbar alloc] initWithIdentifier:@"main"];
	
	[tb setDelegate:toolbarDelegate];
	[tb setAllowsUserCustomization:YES];
	[tb setAutosavesConfiguration:YES];
	
	[mainWindow setToolbar:tb];
	
	[tb release];
	
	[tableViewDelegate updateBooksTable];
	[tableViewDelegate restore];

	NSString * dateFormat = [self getDateFormatString];
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:YES];
	[[datePublished cell] setFormatter:formatter];
	[[dateAcquired cell] setFormatter:formatter];
	[[dateStarted cell] setFormatter:formatter];
	[[dateFinished cell] setFormatter:formatter];
	[[dateLent cell] setFormatter:formatter];
	[[dateReturned cell] setFormatter:formatter];
	[[finishedColumn dataCell] setFormatter:formatter];
	[[lentColumn dataCell] setFormatter:formatter];
	[[returnedColumn dataCell] setFormatter:formatter];
	[formatter release];
	
	dateFormat = [self getDateLentFormatString];

	if (dateFormat != nil)
	{
		formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:YES];

		[[dateLent cell] setFormatter:formatter];
		[[dateReturned cell] setFormatter:formatter];
		[formatter release];
	}

	/* Resize Main Scroller */
	
	NSArray * viewRects = [defaults objectForKey:@"Main Scroller Sizes"];
	
	if (viewRects != nil)
	{
		NSArray * views = [splitView subviews];
        int i, count;

        count = MIN ([viewRects count], [views count]);

        for (i = 0; i < count; i++)
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

	NSString * filePath = [NSString stringWithFormat:@"%@%@", [BooksDataFolder booksDataFolder], @"/Files/", nil];

	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
		[[NSFileManager defaultManager] createDirectoryAtPath:filePath attributes:nil];

	[imageView setTarget:self];
	[imageView setAction:@selector(getCoverWindow:)];

	[mainWindow setShowsResizeIndicator:NO];
	[mainWindow setMovableByWindowBackground:YES];
	
	[coverWindow setReleasedWhenClosed:NO];
	[coverWindow setCanHide:YES];
	
	CoverWindowDelegate * cwd = [[CoverWindowDelegate alloc] init];
	[coverWindow setDelegate:cwd];
	
	[mainWindow makeKeyAndOrderFront:self];
	
	[summary setFieldEditor:NO];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"startUpdateTimer") 
		name:BOOK_DID_UPDATE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"getInfoWindow") 
		name:BOOKS_SHOW_INFO object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"updateMainPane") 
		name:BOOKS_UPDATE_DETAILS object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"stopQuickfill") 
		name:BOOKS_STOP_QUICKFILL object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"startProgress:") 
		name:BOOKS_START_PROGRESS_WINDOW object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"endProgressWindow") 
		name:BOOKS_END_PROGRESS_WINDOW object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"orderCoverWindowOut") 
		name:BOOKS_HIDE_COVER object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"setControlsView:") 
		name:BOOKS_SET_CONTROL_VIEW object:nil];

	timer = nil;

	[NotificationInterface start];
	
	[mainWindow setTitle:NSLocalizedString (@"Books - Loading...", nil)];

	[bookArrayController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:NULL];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Gallery"])
	{
		NSNotification * notification = [NSNotification notificationWithName:BOOKS_SET_CONTROL_VIEW object:galleryViewControls];
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	}
	else
	{
		NSNotification * notification = [NSNotification notificationWithName:BOOKS_SET_CONTROL_VIEW object:nil];
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	}

	[self updateMainPane];
	
	iSight = nil;
	
	if (cameras != nil)
	{
		NSArray * devices = [QTCaptureDevice inputDevices];
		
		NSDictionary * selected = [[NSUserDefaults standardUserDefaults] objectForKey:CAMERA];
		
		unsigned i = 0;
		
		for (i = 0; i < [devices count]; i++)
		{
			QTCaptureDevice * device = [devices objectAtIndex:i];
		
			NSLog (@"device = %@", [device localizedDisplayName]);
			
			if ([device hasMediaType:QTMediaTypeVideo] || [device hasMediaType:QTMediaTypeMuxed])
			{
				NSMutableDictionary * deviceDict = [NSMutableDictionary dictionary];
				
				[deviceDict setValue:[device localizedDisplayName] forKeyPath:CAMERA_NAME];
				[deviceDict setValue:[device uniqueID] forKey:CAMERA_ID];
				
				[cameras addObject:deviceDict];
			}
		}
		
		if (selected != nil)
			[cameras setSelectedObjects:[NSArray arrayWithObject:selected]];
	}
}


- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
	if ([keyPath isEqual:@"selectedObjects"])
		[self updateMainPane];
	else if ([keyPath isEqual:@"arrangedObjects"])
	{
		[bookArrayController removeObserver:self forKeyPath:@"selectedObjects"];
		[bookArrayController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	}
}

- (void) startProgress: (NSNotification *) msg
{
	[self startProgressWindow:[msg object]];
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
		
		NSData * data = [object valueForKey:@"coverImage"];

		if (data != nil)
		{
			NSSize boxSize = [imageBox frame].size;
			
			NSImage * image = [[NSImage alloc] initWithData:data];
			
			NSSize size = [image size];
			
			float scale = boxSize.width / size.width;
			boxSize.height = size.height * scale;

			[imageBox setFrameSize:boxSize];
			[[imageBox superview] display];
			
			[image release];
		}
	}
	else if ([selectedObjects count] > 1)
		htmlString = [pageBuilder buildPageForArray:selectedObjects];

	[mainFrame loadHTMLString:htmlString baseURL:localhost];
}


- (void) startUpdateTimer
{
	if (timer != nil)
	{
		[timer invalidate];
		[timer release];
		timer = nil;
	}

	timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:NSSelectorFromString(@"refreshUI:") 
				userInfo:nil repeats:NO] retain];
}


- (void) refreshUI:(NSTimer *) theTimer
{
	[self updateMainPane];

	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[self managedObjectContext]]];

	NSError * error = nil;
	NSArray * books = [[self managedObjectContext] executeFetchRequest:fetch error:&error];
		
	[fetch release];
	NSMutableSet * userFieldNames = [NSMutableSet set];

	[tokenDelegate updateTokens];
	[comboBoxDelegate updateTokens];

	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];
		
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

	NSArray * lists = [NSArray arrayWithObjects: userFieldNames, nil];
	NSArray * listCombos = [NSArray arrayWithObjects: userFieldCombo, nil];

	for (i = 0; i < [lists count] && i < [listCombos count]; i++)
	{
		[[listCombos objectAtIndex:i] removeAllItems];

		NSMutableArray * array = [NSMutableArray arrayWithArray:[[lists objectAtIndex:i] allObjects]];

		[array sortUsingSelector:@selector(compare:)];
			
		[[listCombos objectAtIndex:i] addItemsWithObjectValues:array];
	}
}

- (IBAction)preferences:(id)sender
{
	if ([preferencesWindow isVisible])
		[preferencesWindow orderOut:sender];
	else
	{
		[preferencesWindow center];
		[preferencesWindow makeKeyAndOrderFront:sender];
	}
}

- (IBAction)showViewControls:(id)sender
{
	if ([controlsPanel isVisible])
		[controlsPanel orderOut:sender];
	else
	{
		[controlsPanel center];
		[controlsPanel makeKeyAndOrderFront:sender];
	}
}


- (NSArray *) getQuickfillPlugins
{
	if (quickfillPlugins == nil)
		[self initQuickfillPlugins];
	
	if ([self leopardOrBetter])
		return [[quickfillPlugins allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	else 
		return [[quickfillPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) setQuickfillPlugins: (NSArray *) list
{

}

- (void) initQuickfillPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [[BooksDataFolder booksDataFolder] stringByAppendingPathComponent:@"/Plugins"];
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
					[pluginName release];
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

	if ([infoWindow isVisible])
	{
		[NSApp endSheet:quickfillWindow];

		[quickfillWindow orderOut:self];
		[quickfillProgress stopAnimation:self];
	}
}

- (void) stopQuickfill
{
	[quickfill killTask];
	
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

	if ([self leopardOrBetter])
		return [[importPlugins allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	else
		return [[importPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) initImportPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [[BooksDataFolder booksDataFolder] stringByAppendingPathComponent:@"/Plugins"];
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
					[pluginName release];
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
	[import release];
}

- (NSArray *) getExportPlugins
{
	if (exportPlugins == nil)
		[self initExportPlugins];
	
	if ([self leopardOrBetter])
		return [[exportPlugins allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	else
		return [[exportPlugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void) setExportPlugins: (NSArray *) list
{

}

- (void) initExportPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [[BooksDataFolder booksDataFolder] stringByAppendingPathComponent:@"/Plugins"];
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
					[pluginName release];
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
		[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Get Info", nil)];
	else if (window == coverWindow)
		[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Show Cover", nil)];
}

- (IBAction) save: (id)sender
{
	[self saveAction:sender];
}

- (IBAction)newSmartList:(id)sender
{
	[collectionArrayController rearrangeObjects];

	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"SmartList"];

	SmartListManagedObject * sc = [[SmartListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];
	[sc setValue:NSLocalizedString (@"New Smart List", nil) forKey:@"name"];
	
	[collectionArrayController addObject:sc];
	[sc release];
	
	[self editSmartList:sender];

	NSNotification * notification = [NSNotification notificationWithName:BOOKS_EDIT_LIST_NAME object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (IBAction) newList:(id) sender
{
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"List"];
	ListManagedObject * object = [[ListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];
	[object setValue:NSLocalizedString (@"New List", nil) forKey:@"name"];

	[collectionArrayController addObject:object];
	
	NSSortDescriptor * sort = nil;
	
	if ([self leopardOrBetter])
		sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	else
		sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];

	[collectionArrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];
	
	[object release];
	
	[self save:sender];

	NSNotification * notification = [NSNotification notificationWithName:BOOKS_EDIT_LIST_NAME object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
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
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
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
			
			[object addNewCopy];
			
			[object release];
			
			[context unlock];

			[tableViewDelegate reloadBooksTable];

			if (![infoWindow isVisible])
			{
				[self getInfoWindow:nil];
			}

			[infoWindow makeFirstResponder:responder];

			[self save:sender];
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
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
		{

		}
		else
		{
			NSArray * selects = [bookArrayController selectedObjects];
			
			int choice = -1;
			
			if ([selects count] == 1)
			{
				choice = NSRunAlertPanel (NSLocalizedString (@"Delete Selected Book?", nil), 
							NSLocalizedString (@"Are you sure you want to delete the selected book?", nil), NSLocalizedString (@"No", nil), 
							NSLocalizedString (@"Yes", nil), nil);
			}
			else
			{
				choice = NSRunAlertPanel (NSLocalizedString (@"Delete Selected Books?", nil), 
							NSLocalizedString (@"Are you sure you want to delete the selected books?", nil), NSLocalizedString (@"No", nil), 
							NSLocalizedString (@"Yes", nil), nil);
			}
			
			if (choice == NSAlertAlternateReturn)
				[bookArrayController remove:self];

			[self save:sender];
		}
	}
}

- (IBAction) removeList:(id) sender
{
	[toolbarDelegate cancelSearch];
	
	NSArray * lists = [collectionArrayController arrangedObjects];
	
	int listCount = 0;
	
	int i = 0;
	for (i = 0; i < [lists count]; i++)
	{
		NSObject * list = [lists objectAtIndex:i];
		
		if (![list isKindOfClass:[SmartListManagedObject class]])
			listCount = listCount + 1;
	}

	NSArray * objects = [collectionArrayController selectedObjects];
	ListManagedObject * list = [objects objectAtIndex:0];

	if (listCount > 1 || [list isKindOfClass:[SmartListManagedObject class]])
	{
		if ([objects count] == 1)
		{
			if ([list isKindOfClass:[SmartListManagedObject class]])
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
		
		[self save:sender];
	}
	else
		NSRunAlertPanel (NSLocalizedString (@"Can Not Remove List", nil),  NSLocalizedString (@"The remaining list can not be removed.", nil), NSLocalizedString (@"OK", nil), nil, nil);
}

- (IBAction) editSmartList:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
		{
			[[smartListEditorWindow delegate] setPredicate:[((SmartListManagedObject *) list) getPredicate]];

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
		
		if ([list isKindOfClass:[SmartListManagedObject class]])
		{
			NSPredicate * p = [[smartListEditorWindow delegate] getPredicate];
			
			[((SmartListManagedObject *) list) setPredicate:p];
		}
		
		[list didChangeValueForKey:@"items"];

		NSIndexSet * selection = [collectionArrayController selectionIndexes];

		[collectionArrayController setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
		[collectionArrayController setSelectionIndexes:selection];
	}

	[tableViewDelegate reloadBooksTable];
	
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
	
	[fetch release];

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
	[fetch release];
	int i = 0;
	for (i = 0; i < [fetchedItems count]; i++)
	{
		if (![[fetchedItems objectAtIndex:i] isKindOfClass:[SmartListManagedObject class]])
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
	[fetch release];

	return [results retain];
}

- (void) selectListsTable: (id) sender
{
	[mainWindow makeFirstResponder:[tableViewDelegate getListsTable]];
}

- (void) selectBooksTable: (id) sender
{
	[mainWindow makeFirstResponder:[tableViewDelegate getBooksTable]];
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

	[tableViewDelegate reloadListsTable];

	return [object autorelease];
}

- (id) asCreateNewSmartList:(NSString *) listName
{
	NSManagedObjectContext * context = [self managedObjectContext];
	NSManagedObjectModel * model = [self managedObjectModel];

	NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"SmartList"];

	[context lock];
	SmartListManagedObject * object = [[SmartListManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

	if (listName != nil)
		[object setValue:listName forKey:@"name"];	
	else
		[object setValue:@"New Smart List" forKey:@"name"];
		
	[collectionArrayController addObject:object];
	
	[context unlock];

	[tableViewDelegate reloadListsTable];

	return [object autorelease];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	NSNotification * notification = [NSNotification notificationWithName:BOOKS_OPEN_BOOK object:filename];
	[[NSNotificationCenter defaultCenter] postNotification:notification];

	[spotlightInterface openFile:filename];
	
	return YES;
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

	batchArray = [[NSMutableArray arrayWithArray:[bookArrayController selectedObjects]] retain];
	
	if ([batchArray count] == 0)
		[batchArray addObjectsFromArray:[bookArrayController arrangedObjects]];

	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];

	NSString * message = [NSString stringWithFormat:NSLocalizedString (@"Batch quickfilling %d items...", nil), [batchArray count], nil];

	[progressText setStringValue:message];
	
	[[NSApplication sharedApplication] beginSheet:progressView modalForWindow:mainWindow
		modalDelegate:self didEndSelector:nil contextInfo:NULL];
	
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(batch:) userInfo:
				[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:code] forKey:@"code"] repeats:NO];
				
	[self startQuickfill];
}

- (void) batch:(NSTimer *) theTimer
{
	NSDictionary * userInfo = [theTimer userInfo];
	
	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Quickfill Plugin"];
	
	if (pluginKey == nil || [pluginKey isEqualToString:@""])
		NSRunAlertPanel (NSLocalizedString (@"No Quickfill Plugin Selected", nil),  NSLocalizedString (@"No quickfill plugins have been selected. Select one in the preferences.", nil), NSLocalizedString (@"OK", nil), nil, nil);
	else if (batchArray != nil && [batchArray count] > 0)
	{

		NSBundle * quickfillPlugin = (NSBundle *) [quickfillPlugins objectForKey:pluginKey];

		quickfill = [[QuickfillPluginInterface alloc] init];

		BOOL replace = NO;
		
		if ([[userInfo valueForKey:@"code"] intValue] == NSAlertOtherReturn)
			replace = YES;

		BookManagedObject * book = (BookManagedObject *) [batchArray objectAtIndex:0];

		NSString * message = [NSString stringWithFormat:NSLocalizedString (@"Quickfilling items. %d remaining...", nil), [batchArray count], nil];
		[progressText setStringValue:message];
		[progressText setNeedsDisplay:YES];
		[progressView display];

		[quickfill batchImportFromBundle:quickfillPlugin forBook:book replace:replace];
			
		[batchArray removeObjectAtIndex:0];
		
		[quickfill release];
		
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(batch:) userInfo:userInfo repeats:NO];
		
		return;
	}

	[[NSApplication sharedApplication] endSheet:progressView];
	[progressView orderOut:self];
	[progressIndicator stopAnimation:self];
		
	[batchArray release];
	batchArray = nil;
}

- (IBAction) openFiles: (id) sender
{
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1)
	{
		NSArray * selectedFiles = [fileArrayController selectedObjects];

		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		NSString * filePath = [NSString stringWithFormat:@"%@%@%@/", [BooksDataFolder booksDataFolder], @"/Files/", [book getObjectIdString], nil];
	
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
//	NSString * sourceFile = [fileLocation stringValue];
	NSString * sourceName = [fileTitle stringValue];
	NSString * sourceDesc = [fileDescription stringValue];
	
	NSArray * books = [self getSelectedBooks];
	
	if (books != nil && [books count] == 1 && fullLocation != nil)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:0];

		[book addNewFile:fullLocation title:sourceName description:sourceDesc];
		
		[fullLocation release];
		
		fullLocation = nil;
		[fileLocation setStringValue:@""];
		[fileTitle setStringValue:@""];
		[fileDescription setStringValue:@""];
		[fileIcon setImage:nil];
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
		fullLocation = [[openPanel filename] retain];
		
		[fileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFile:fullLocation]];
		[fileLocation setStringValue:[fullLocation lastPathComponent]];
		[fileTitle setStringValue:[fullLocation lastPathComponent]];
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
			if (siteUrl != nil)
			{
				NSMutableString * urlString = [NSMutableString stringWithString:siteUrl];
			
				[urlString replaceOccurrencesOfString:@"*isbn*" withString:isbn options:NSCaseInsensitiveSearch 
					range:NSMakeRange (0, [urlString length])];
				
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
			}
		}
	}
}

- (QuickfillSearchWindow *) getQuickfillResultsWindow;
{
	return quickfillResultsWindow;
}

- (IBAction) isight: (id)sender
{
	if (iSight == nil)
		iSight = [[MyBarcodeScanner sharedInstance] retain];
	
	[iSight setStaysOpen:NO];
	[iSight setDelegate:self];
	
	[iSight setMirrored:YES];
	
	[iSight scanForBarcodeWindow:nil];
}


- (void) gotBarcode:(NSString *)barcode 
{
	if (([barcode length] == 13 || [barcode length] == 18) && [barcode rangeOfString:@"?"].location == NSNotFound)
	{
		NSArray * selected = [self getSelectedBooks];
		
		if ([selected count] == 1)
		{
			BookManagedObject * book = (BookManagedObject *) [selected objectAtIndex:0];
			
			[book setValue:barcode forKey:@"isbn"];

			[infoWindow makeKeyAndOrderFront:nil];
			[toolbarDelegate setGetInfoLabel:NSLocalizedString (@"Hide Info", nil)];
		}
	}
	else
		NSRunAlertPanel (NSLocalizedString (@"Unable To Process Barcode", nil), NSLocalizedString (@"Books is unable to process the scanned barcode. Please try again.", nil), NSLocalizedString (@"OK", nil), nil, nil);
}

- (IBAction) duplicateRecords:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if (![list isKindOfClass:[SmartListManagedObject class]])
		{
			NSArray * books = [bookArrayController selectedObjects];

			NSManagedObjectContext * context = [self managedObjectContext];
			NSManagedObjectModel * model = [self managedObjectModel];
			NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"Book"];
			NSEntityDescription * fieldDesc = [[model entitiesByName] objectForKey:@"UserDefinedField"];
			
			NSArray * props = [desc properties];

			int i = 0;

			for (i = 0; i < [books count]; i++)
			{
				BookManagedObject * record = [books objectAtIndex:i];

				[context lock];
				BookManagedObject * object = [[BookManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

				int j = 0;
				for (j = 0; j < [props count]; j++)
				{
					NSPropertyDescription * propDesc = (NSPropertyDescription *) [props objectAtIndex:j];
					NSString * name = [propDesc name];
					
					if ([propDesc isMemberOfClass:[NSAttributeDescription class]])
						[object setValue:[record valueForKey:name] forKey:name];
					else if ([name isEqualToString:@"userFields"])
					{
						NSArray * userFields = [[record valueForKey:@"userFields"] allObjects];
						
						NSMutableSet * objectFields = [object mutableSetValueForKey:@"userFields"];
						
						int k = 0;
						for (k = 0; k < [userFields count]; k++)
						{
							NSManagedObject * fieldPair = [userFields objectAtIndex:k];
							NSManagedObject * fieldObject = [[NSManagedObject alloc] initWithEntity:fieldDesc 
								insertIntoManagedObjectContext:context];

							[fieldObject setValue:[fieldPair valueForKey:@"key"] forKey:@"key"];
							[fieldObject setValue:[fieldPair valueForKey:@"value"] forKey:@"value"];
	
							[objectFields addObject:fieldObject];
							[fieldObject release];
						}
					}
				}

				CFUUIDRef uuid = CFUUIDCreate (kCFAllocatorDefault);
				NSString * uuidString = (NSString *) CFUUIDCreateString (kCFAllocatorDefault, uuid);
		
				[object setValue:uuidString forKey:@"id"];
				
				[uuidString release];
				CFRelease (uuid);

				NSData * cover = [record getCoverImage];
				[object setCoverImage:[cover copyWithZone:NULL]];

				[context insertObject:object];

				[bookArrayController addObject:object];
				[object release];
				[context unlock];
			}
			
			[tableViewDelegate reloadBooksTable];
		}
	}
}

- (IBAction) donate: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://books.aetherial.net/donate/"]];
}	

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	if (aSelector == @selector(insertNewline:))
	{
		[aTextView insertNewlineIgnoringFieldEditor:nil];
		return YES;
	}
	else if (aSelector == @selector(insertTab:))
	{
		[infoWindow selectNextKeyView:nil];
		return YES;
	}	
	else if (aSelector == @selector(insertBacktab:))
	{
		[infoWindow selectPreviousKeyView:nil];
		return YES;
	}
		
	return NO;
} 

- (void) orderCoverWindowOut
{
	[toolbarDelegate setGetCoverLabel:NSLocalizedString (@"Show Cover", nil)];

	[coverWindow orderOut:self];
}

- (void) setDateFormatString:(NSString *) format
{
    [self willChangeValueForKey:@"now"];

	[[NSUserDefaults standardUserDefaults] setValue:format forKey:@"Custom Date Format"];
	
    [self didChangeValueForKey:@"now"];

	NSDateFormatter * formatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:YES];
	
	[tableViewDelegate updateBooksTable];
	[[datePublished cell] setFormatter:formatter];
	[[dateAcquired cell] setFormatter:formatter];
	[[dateStarted cell] setFormatter:formatter];
	[[dateFinished cell] setFormatter:formatter];
	[[dateLent cell] setFormatter:formatter];
	[[dateReturned cell] setFormatter:formatter];
	
	[formatter release];
}

- (NSString *) getDateFormatString
{
	NSString * format = [[NSUserDefaults standardUserDefaults] stringForKey:@"Custom Date Format"];
	
	if (format == nil)
		format = @"%B %e, %Y";
	
	return format;
}

- (NSString *) getDateLentFormatString
{
	NSString * format = [[NSUserDefaults standardUserDefaults] stringForKey:BOOKS_LENT_DATE_FORMAT];
	
	return format;
}


- (NSString *) getNow
{
	NSString * dateFormat = [self getDateFormatString];
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:YES];

	NSString * dateString = [formatter stringFromDate:[NSDate date]];
	
	[formatter release];
	
	return dateString;
}

- (void) setNow: (NSString *) now
{

}

- (IBAction) print:(id) sender
{
	if (exportPlugins == nil)
		[self initExportPlugins];

	NSBundle * exportPlugin = [exportPlugins objectForKey:@"PDF Exporter"];
	
	if (exportPlugin != nil)
	{
		ExportPluginInterface * export = [[ExportPluginInterface alloc] init];
		[NSThread detachNewThreadSelector:NSSelectorFromString(@"exportToBundle:") toTarget:export withObject:exportPlugin];
		[export release];
	}
	else
	{
		NSRunAlertPanel (NSLocalizedString (@"Unable To Print", nil), NSLocalizedString (@"Please install the PDF Exporter from the Plugin Manager to enable printing.", nil), NSLocalizedString (@"OK", nil), nil, nil);
		[pluginManager toggleVisible:sender];
	}
}

- (IBAction) compact:(id) sender
{
	BooksLibraryCompactor * compactor = [[BooksLibraryCompactor alloc] init];
	
	[compactor compact];
	
	[compactor release];
}

- (IBAction) copy:(id) sender
{
	NSMutableArray * uuids = [NSMutableArray array];
		
	NSArray * books = [bookArrayController selectedObjects];
			
	NSEnumerator * iter = [books objectEnumerator];
	BookManagedObject * book = nil;
			
	while ((book = [iter nextObject]) != nil)
		[uuids addObject:[book valueForKey:@"id"]];

	NSData * data = [NSArchiver archivedDataWithRootObject:uuids];

	NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];

	NSMutableArray * types = [NSMutableArray arrayWithArray:[pasteboard types]];
	[types addObject:BOOKS_COPY_TYPE];

	[pasteboard declareTypes:types owner:nil];
	
	[pasteboard setData:[data retain] forType:BOOKS_COPY_TYPE];
}


- (IBAction) paste:(id) sender
{
	NSArray * objects = [collectionArrayController selectedObjects];
	
	if ([objects count] == 1)
	{
		ListManagedObject * list = [objects objectAtIndex:0];
		
		if (![list isKindOfClass:[SmartListManagedObject class]])
		{
			NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];

			NSArray * types = [NSArray arrayWithObject:BOOKS_COPY_TYPE];
			NSString * bestType = [pasteboard availableTypeFromArray:types];
			
			if (bestType != nil)
			{
				NSData * data = [pasteboard dataForType:BOOKS_COPY_TYPE];

				NSArray * uuids = [NSUnarchiver unarchiveObjectWithData:data];

				if (uuids != nil)
				{
					NSManagedObjectContext * context = [self managedObjectContext];
					NSManagedObjectModel * model = [self managedObjectModel];
					NSEntityDescription * desc = [[model entitiesByName] objectForKey:@"Book"];
					NSEntityDescription * fieldDesc = [[model entitiesByName] objectForKey:@"UserDefinedField"];
					NSArray * props = [desc properties];

					NSEnumerator * iter = [uuids objectEnumerator];
					NSString * uuid = nil;
					
					while ((uuid = [iter nextObject]) != nil)
					{
						NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
						[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[self managedObjectContext]]];

						NSExpression * right = [NSExpression expressionForConstantValue:uuid];
						NSExpression * left = [NSExpression expressionForKeyPath:@"id"];

						NSPredicate * predicate = [NSComparisonPredicate predicateWithLeftExpression:left rightExpression:right
													modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType 
													options: (NSCaseInsensitivePredicateOption || NSDiacriticInsensitivePredicateOption)];


						[fetch setPredicate:predicate];

						NSError * error = nil;
						NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];
						
						[fetch release];
						
						if ([results count] > 0)
						{
							BookManagedObject * record = [results objectAtIndex:0];

							[context lock];
							BookManagedObject * object = [[BookManagedObject alloc] initWithEntity:desc insertIntoManagedObjectContext:context];

							int j = 0;
							for (j = 0; j < [props count]; j++)
							{
								NSPropertyDescription * propDesc = (NSPropertyDescription *) [props objectAtIndex:j];
								NSString * name = [propDesc name];
					
								if ([propDesc isMemberOfClass:[NSAttributeDescription class]])
									[object setValue:[record valueForKey:name] forKey:name];
								else if ([name isEqualToString:@"userFields"])
								{
									NSArray * userFields = [[record valueForKey:@"userFields"] allObjects];
						
									NSMutableSet * objectFields = [object mutableSetValueForKey:@"userFields"];
						
									int k = 0;
									for (k = 0; k < [userFields count]; k++)
									{
										NSManagedObject * fieldPair = [userFields objectAtIndex:k];
										NSManagedObject * fieldObject = [[NSManagedObject alloc] initWithEntity:fieldDesc 
											insertIntoManagedObjectContext:context];

										[fieldObject setValue:[fieldPair valueForKey:@"key"] forKey:@"key"];
										[fieldObject setValue:[fieldPair valueForKey:@"value"] forKey:@"value"];
	
										[objectFields addObject:fieldObject];
										[fieldObject release];
									}
								}
							}

							CFUUIDRef uuid = CFUUIDCreate (kCFAllocatorDefault);
							NSString * uuidString = (NSString *) CFUUIDCreateString (kCFAllocatorDefault, uuid);
		
							[object setValue:uuidString forKey:@"id"];
							
							[uuidString release];
							CFRelease (uuid);

							NSData * cover = [record getCoverImage];
							[object setCoverImage:[cover copyWithZone:NULL]];

							[context insertObject:object];

							[bookArrayController addObject:object];
							[object release];
							[context unlock];
						}
			
						[tableViewDelegate reloadBooksTable];
					}
				}
			}
		}
	}
}

- (IBAction) selectPrevious:(id) sender
{
	[bookArrayController selectPrevious:sender];
	[infoWindow makeFirstResponder:responder];
}

- (IBAction) selectNext:(id) sender
{
	[bookArrayController selectNext:sender];
	[infoWindow makeFirstResponder:responder];
}

- (void)windowDidUpdate:(NSNotification *)notification
{
	NSResponder * newResponder = [infoWindow firstResponder];

	if (responder == newResponder)
		return;
		
	if (![newResponder isKindOfClass:[NSButton class]])
	{
		responder = newResponder;
	}
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[infoWindow makeFirstResponder:responder];
}
@end
