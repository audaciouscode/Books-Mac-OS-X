#import "AppDelegate.h"

@implementation AppDelegate

- (IBAction) doImport: (id) sender
{
	NSArray * rows = [dataSource getRows];
	
	NSXMLElement * root = [[NSXMLElement alloc] initWithName:@"importedData"];
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithRootElement:root];
	
	NSXMLElement * collection = [[NSXMLElement alloc] initWithName:@"List"];
	[collection addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:@"Tab-Delimited Text"]];

	int i = 0;
	for (i = 0; i < [rows count]; i++)
	{
		NSXMLElement * book = [[NSXMLElement alloc] initWithName:@"Book"];

		NSDictionary * entry = [rows objectAtIndex:i];
		
		NSArray * keys = [entry allKeys];
		
		int j = 0;
		for (j = 0; j < [keys count]; j++)
		{
			NSObject * key = [keys objectAtIndex:j];

			NSObject * value = [entry objectForKey:key];
			
			if (value != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithName:@"field"];

				[field addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[key description]]];
				[field setStringValue:[value description]];
				
				[book addChild:field];
			}
		}
		
		[collection addChild:book];
	}

	[root addChild:collection];

	NSString * xmlString = [xml description];
	
	const char * utfData = [xmlString cStringUsingEncoding:NSUTF8StringEncoding];
	
	fprintf (stdout, "%s", utfData);
	fflush (stdout);
	
	[NSApp terminate:self];
}

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
	NSOpenPanel * fileOpen = [NSOpenPanel openPanel];
	
	int results = [fileOpen runModalForTypes:[NSArray arrayWithObject:@"txt"]];

	if (results == NSCancelButton)
	{
		[[NSApplication sharedApplication] terminate:nil];
		
		return;
	}
	
	NSString * filePath = [[fileOpen filenames] objectAtIndex:0];
	
	NSMutableString * fileContents = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];

	if (fileContents == nil)
	{
		NSLog (@"mac roman");
		fileContents = [NSMutableString stringWithContentsOfFile:filePath encoding:NSMacOSRomanStringEncoding error:NULL];

		if (fileContents == nil)
		{
			NSLog (@"ascii");
			fileContents = [NSMutableString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error:NULL];

			if (fileContents == nil)
			{
		        NSRunAlertPanel (@"Error", @"Unable to determine file encoding. Check that your file is saved as a UTF-8, MacRoman, or ASCII document.", @"Quit", nil, nil);

				[NSApp terminate];
			}
		}
	}
	
	// NSLog (@"file contents = --%@--", fileContents);
	
	dataSource = [[TableDataSource alloc] init];
	
	[dataSource setStringContents:fileContents];

	int columnCount = [dataSource getColumnCount];
	
	int i = 0;
	
	for (i = 0; i < columnCount; i++)
	{
		NSNumber * index = [NSNumber numberWithInt:i];
		
		NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:[index description]];
		[[column headerCell] setStringValue:[index description]];
		[column setEditable:NO];
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
		
		[table addTableColumn:column];
	}
	
	[table setDataSource:dataSource];
	[table setDelegate:self];
	
	[fieldName setDelegate:self];
	
	[window makeKeyAndOrderFront:nil];
}

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification
{
	if ([table selectedColumn] != -1)
	{
		NSTableColumn * column = [[table tableColumns] objectAtIndex:[table selectedColumn]];
		
		[fieldName setStringValue:[[column identifier] description]];
		[fieldName setEnabled:YES];
	}
	else
	{
		[fieldName setEnabled:NO];
		[fieldName setStringValue:@""];
	}
}

- (void) comboBoxSelectionDidChange: (NSNotification *) notification
{
	[fieldName setStringValue:[[fieldName objectValueOfSelectedItem] description]];
	
	[self controlTextDidChange:notification];
}

- (void) controlTextDidChange: (NSNotification *) aNotification
{
	NSArray * columns = [table tableColumns];

	NSString * newName = [fieldName stringValue];
	
	if (newName == nil || [[newName description] isEqualToString:@""])
		return;
		
	NSTableColumn * column = [columns objectAtIndex:[table selectedColumn]];

	int count = 0;
	
	int i = 0;
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * oldColumn = [columns objectAtIndex:i];
		
		if (oldColumn != column && [[[oldColumn identifier] description] isEqualToString:newName])
			count++;
	}

	if (count > 0)
	{
		NSRunAlertPanel(@"Duplicate field name", @"A column with this field name already exists. Please choose another.", @"OK", nil, nil);

		[fieldName setStringValue:[[column identifier] description]];
			
		return;
	}

	[dataSource replaceKey:[column identifier] withKey:newName];
	[column setIdentifier:newName];
	[[column headerCell] setStringValue:newName];
	
	[table reloadData];
}

- (void) windowWillClose: (NSNotification *) aNotification
{
	[NSApp terminate:self];
}

@end
