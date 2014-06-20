#import "FileImporterAppDelegate.h"

@implementation FileImporterAppDelegate

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction) export:(id) sender
{
	NSBundle * bundle = [NSBundle mainBundle];

	[progressMessage setStringValue:NSLocalizedString (@"Importing data. Please be patient.", nil)];
	[progressBar setUsesThreadedAnimation:YES];
	[progressWindow setTitle:NSLocalizedString (@"Importing Data", nil)];
	[progressWindow makeKeyAndOrderFront:self];
	[progressBar startAnimation:self];

	NSIndexSet * indexes = [resultsTable selectedRowIndexes];

	unsigned int indexInts[4096];
	
	NSRange range = NSMakeRange (0, 4096);
	
	int length = [indexes getIndexes:indexInts maxCount:4096 inIndexRange:&range];
	
	NSXMLElement * root = [[NSXMLElement alloc] initWithName:@"importedData"];
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithRootElement:root];
	
	NSXMLElement * collection = [[NSXMLElement alloc] initWithName:@"List"];
	
	NSString * listName = [bundle objectForInfoDictionaryKey:@"BooksListName"];

	[collection addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:listName]];
	
	[root addChild:collection];
	
	int i = 0;
	
	for (i = 0; i < length; i++)
	{
		if (i > 0 && i % 500 == 0)
		{
			collection = [[NSXMLElement alloc] initWithName:@"List"];
			[collection addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:listName]];
			
			[root addChild:collection];
		}
		
		NSDictionary * hit = [resultsDataSource getHitAtIndex:indexInts[i]];

		NSXMLElement * book = [[NSXMLElement alloc] initWithName:@"Book"];

		NSArray * keys = [hit allKeys];

		int j = 0; 
		for (j = 0; j < [keys count]; j++)
		{
			NSString * key = [keys objectAtIndex:j];
			NSString * value = [hit valueForKey:key];

			NSXMLNode * att = [NSXMLNode attributeWithName:@"name" stringValue:key];
			
			NSXMLElement * field = [[NSXMLElement alloc] initWithName:@"field"];
		
			[field addAttribute:att];

			[field setStringValue:value];

			[book addChild:field];
		}
		
		[collection addChild:book];
	}
	
	NSString * xmlString = [xml description];
	
	const char * utfData = [xmlString cStringUsingEncoding:NSUTF8StringEncoding];
	
	fprintf (stdout, "%s", utfData);
	fflush (stdout);
	
	[progressBar stopAnimation:self];
	[progressWindow orderOut:self];

	[[NSApplication sharedApplication] terminate:sender];
}

- (void)applicationWillTerminate: (NSNotification *) aNotification
{
	fflush (stdout);
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
	NSBundle * bundle = [NSBundle mainBundle];

	NSOpenPanel * fileOpen = [NSOpenPanel openPanel];
	
	int results = [fileOpen runModalForTypes:[bundle objectForInfoDictionaryKey:@"BooksFileType"]];

	[quitMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString (@"Quit %@", nil), 
		[bundle objectForInfoDictionaryKey:@"CFBundleName"], nil]];

	if (results == NSCancelButton)
	{
		[[NSApplication sharedApplication] terminate:nil];
		
		return;
	}
	
	filePath = [[fileOpen filenames] objectAtIndex:0];

	NSDictionary * contents = (NSDictionary *) [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:filePath] 
		mutabilityOption:kCFPropertyListImmutable format:NULL errorDescription:nil];
	
	[resultsDataSource addContents:contents];

	[progressBar stopAnimation:self];
	[progressWindow orderOut:self];
	
	[resultsTable reloadData];
	
	[resultsTable selectAll:self];

	[window setTitle:[bundle objectForInfoDictionaryKey:@"CFBundleName"]];
	
	[window makeKeyAndOrderFront:nil];
}

@end
