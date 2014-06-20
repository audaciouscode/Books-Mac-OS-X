#import "AppDelegate.h"
#import "Book.h"

@implementation AppDelegate

- (IBAction) createApp: (id) sender
{
	NSArray * books = [exportRecords arrangedObjects];
	
	if ([books count] == 0)
	{
		NSRunAlertPanel(@"Please select select some records", @"No records selected for export. Choose some to export.", @"Ok", nil, nil, nil);
	}
	else
	{
		NSError * error = nil;

		NSString * path = @"/tmp/books-export";
//		NSString * path = @"/tmp/";

		NSFileManager * manager = [NSFileManager defaultManager];
		
		NSXMLDocument * xml = [[NSXMLDocument alloc] initWithXMLString:@"<exportData />" options:NSXMLDocumentTidyXML error:&error];
		
		NSXMLElement * root = [xml rootElement];
		
		int i = 0;
		for (i = 0; i < [books count]; i++)
		{
			Book * book = [books objectAtIndex:i];
			NSXMLElement * element = [[NSXMLElement alloc] initWithXMLString:@"<Book />" error:&error];

			if ([book getTitle] != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
				NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:@"title"];

				[field addAttribute:nameAttribute];
				[field setStringValue:[book getTitle]];

				[element addChild:field];
			}

			if ([book getAuthors] != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
				NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:@"authors"];

				[field addAttribute:nameAttribute];
				[field setStringValue:[book getAuthors]];

				[element addChild:field];
			}

			if ([book getIsbn] != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
				NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:@"isbn"];

				[field addAttribute:nameAttribute];
				[field setStringValue:[book getIsbn]];

				[element addChild:field];
			}

			if ([book getPublisher] != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
				NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:@"publisher"];

				[field addAttribute:nameAttribute];
				[field setStringValue:[book getPublisher]];

				[element addChild:field];
			}

			if ([book getPublishDate] != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
				NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:@"publishDate"];

				[field addAttribute:nameAttribute];
				[field setStringValue:[[book getPublishDate] description]];

				[element addChild:field];
			}

			if ([book getGenre] != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
				NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:@"genre"];

				[field addAttribute:nameAttribute];
				[field setStringValue:[book getGenre]];

				[element addChild:field];
			}

			[root addChild:element];
		}
		
		[xml setCharacterEncoding:@"UTF-8"];
		
		NSData * xmlData = [xml XMLData];

		NSString * exportPath = [NSString stringWithFormat:@"%@/books-export-slim.xml", path, nil];

		[manager createFileAtPath:exportPath contents:xmlData attributes:nil];
		
		NSBundle * bundle = [NSBundle mainBundle];
		NSString * execPath = [bundle pathForResource:@"build-jar" ofType:@"sh" inDirectory:@"Books-J2ME"];

		NSLog (@"exec: %@", execPath);

		NSTask * exportTask = [[NSTask alloc] init];
		[exportTask setLaunchPath:execPath];
		[exportTask setCurrentDirectoryPath:[execPath stringByDeletingLastPathComponent]];
		[exportTask setArguments:[NSArray arrayWithObject:exportPath]];
		
		[exportTask launch];
		[exportTask waitUntilExit];
	}
}

- (IBAction) exportItems: (id) sender
{
	NSArray * selectedObjects = [allRecords selectedObjects];
	
	int i = 0;
	for (i = 0; i < [selectedObjects count]; i++)
	{
		Book * book = [selectedObjects objectAtIndex:i];
		
		[exportRecords removeObject:book];
		
		[exportRecords addObject:book];
	}
}

- (IBAction) previewItems: (id) sender
{
	NSMutableString * string = [NSMutableString stringWithString:@"The selected records will appear like this on your device:\n\n"];

	NSArray * selectedObjects = [allRecords selectedObjects];

	int i = 0;
	for (i = 0; i < [selectedObjects count]; i++)
	{
		Book * book = [selectedObjects objectAtIndex:i];

		if ([book getTitle] != nil)
		{
			[string appendString:@"Title: "];
			[string appendString:[[book getTitle] stringByAppendingString:@"\n"]];
		}
		else if ([book getAuthors] != nil)
		{
			[string appendString:@"Authors: "];
			[string appendString:[[book getAuthors] stringByAppendingString:@"\n"]];
		}
		if ([book getIsbn] != nil)
		{
			[string appendString:@"ISBN: "];
			[string appendString:[[book getIsbn] stringByAppendingString:@"\n"]];
		}
		if ([book getPublishDate] != nil)
		{
			[string appendString:@"Publish Date: "];
			[string appendString:[[[book getPublishDate] description] stringByAppendingString:@"\n"]];
		}
		if ([book getPublisher] != nil)
		{
			[string appendString:@"Publisher: "];
			[string appendString:[[book getTitle] stringByAppendingString:@"\n"]];
		}
		
		[string appendString:@"\n"];
	}
	
	[previewText setString:string];

	[previewWindow makeKeyAndOrderFront:sender];
}

- (IBAction)removeItems:(id)sender
{
	NSArray * selectedObjects = [exportRecords selectedObjects];
	
	[exportRecords removeObjects:selectedObjects];
}

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];
}

- (void) errorMessage
{
	NSRunAlertPanel(@"Unable to load data", @"No data could be loaded. Please check the export process.", @"Quit", nil, nil, nil);

	[NSApp terminate:self];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
	NSArray * columns = [allRecordsTable tableColumns];
	
	int i = 0;
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
		
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}

	columns = [exportRecordsTable tableColumns];
	
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
		
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}


	NSError * error = nil;
	
	NSURL * url = [NSURL URLWithString:@"file:///tmp/books-export/books-export.xml"];
//	NSURL * url = [NSURL URLWithString:@"file:///Users/cjkarr/Desktop/books-export/books-export.xml"];
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithContentsOfURL:url options: NSXMLDocumentTidyXML error:&error];
	
	if (error != nil)
		[self errorMessage];
		
	NSXMLElement * exportData = [xml rootElement];
	NSArray * bookElements = [exportData elementsForName:@"Book"];
	
	if (bookElements != nil)
	{
		int i = 0;
		for (i = 0; i < [bookElements count]; i++)
		{
			NSXMLElement * book = (NSXMLElement *) [bookElements objectAtIndex:i];
			
			NSArray * fields = [book elementsForName:@"field"];
			
			Book * bookRecord = [[Book alloc] init];
			
			int j = 0;
			for (j = 0; j < [fields count]; j++)
			{
				NSXMLElement * field = [fields objectAtIndex:j];
				
				NSString * name = [[field attributeForName:@"name"] stringValue];

				if ([name isEqualToString:@"title"])
					[bookRecord setTitle:[field stringValue]];
				else if ([name isEqualToString:@"authors"])
					[bookRecord setAuthors:[field stringValue]];
				else if ([name isEqualToString:@"publisher"])
					[bookRecord setPublisher:[field stringValue]];
				else if ([name isEqualToString:@"genre"])
					[bookRecord setGenre:[field stringValue]];
				else if ([name isEqualToString:@"isbn"])
					[bookRecord setIsbn:[field stringValue]];
				else if ([name isEqualToString:@"publishDate"])
				{
					[bookRecord setPublishDate:[NSDate dateWithNaturalLanguageString:[field stringValue]]];
				}
			}
			
			if ([bookRecord getTitle] != nil)
				[allRecords addObject:bookRecord];
		}
	}
	else
		[self errorMessage];
}

- (void) windowWillClose: (NSNotification *) aNotification
{
	NSObject * object = [aNotification object];
	
	if (object == appWindow)
		[NSApp terminate:self];
}

@end
