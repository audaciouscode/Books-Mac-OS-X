#import "TemplateImporterAppDelegate.h"

@implementation TemplateImporterAppDelegate

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction) export:(id) sender
{
	NSIndexSet * indexes = [resultsTable selectedRowIndexes];

	unsigned int indexInts[1024];
	
	NSRange range = NSMakeRange (0, 1024);
	
	int length = [indexes getIndexes:indexInts maxCount:1024 inIndexRange:&range];
	
	NSXMLElement * root = [[NSXMLElement alloc] initWithName:@"importedData"];
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithRootElement:root];
	
	NSXMLElement * collection = [[NSXMLElement alloc] initWithName:@"List"];
	[collection addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[searchQuery stringValue]]];
	
	[root addChild:collection];
	
	int i = 0;
	
	for (i = 0; i < length; i++)
	{
		NSDictionary * hit = [resultsDataSource getHitAtIndex:indexInts[i]];
		
		NSXMLElement * book = [hit objectForKey:@"xmldata"];
		
		[book detach];
		
		[collection addChild:book];
	}
	
	NSString * xmlString = [xml description];
	
	const char * utfData = [xmlString cStringUsingEncoding:NSUTF8StringEncoding];
	
	fprintf (stdout, "%s", utfData);
	fflush (stdout);
}

- (IBAction) quit:(id) sender
{
	NSApplication * sharedApplication = [NSApplication sharedApplication];
	
	[sharedApplication terminate:sender];
}

- (IBAction) search:(id) sender
{
	NSString * query = [searchQuery stringValue];
	NSString * field = [searchField titleOfSelectedItem];
	
	NSBundle * bundle = [NSBundle mainBundle];
	
	NSString * scriptName = [bundle objectForInfoDictionaryKey:@"BooksScriptName"];
	NSString * scriptPath = [bundle pathForResource:[scriptName stringByDeletingPathExtension] ofType:[scriptName pathExtension]];

	NSTask * task = [[NSTask alloc] init];
	
	[task setLaunchPath:scriptPath];
	
	NSArray * arguments = [NSArray arrayWithObjects:query, field, nil];
	[task setArguments:arguments];
	
	NSPipe * stdinPipe = [NSPipe pipe];
	NSPipe * stdoutPipe = [NSPipe pipe];
	NSPipe * stderrPipe = [NSPipe pipe];
	
	[task setStandardError:stderrPipe];
	[task setStandardOutput:stdoutPipe];
	[task setStandardInput:stdinPipe];
	
	NSFileHandle * outHandle = [stdoutPipe fileHandleForReading];
	NSMutableData * outData = [NSMutableData data];
	
	[task launch];

	while ([task isRunning])
	{
		NSData * availableData = [outHandle availableData];
		
		[outData appendData:availableData];
	}
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithData:outData options:NSXMLDocumentTidyXML error:nil];

	[resultsDataSource addXMLContents:xml];
	
	[resultsTable reloadData];
}

- (void) windowDidBecomeKey:(NSNotification *) aNotification
{
	NSBundle * mainBundle = [NSBundle mainBundle];
	NSString * title = [mainBundle objectForInfoDictionaryKey:@"BooksPluginName"];
	
	[mainWindow setTitle:title];
	[topMenuItem setTitle:title];
	[aboutMenuItem setTitle:[@"About " stringByAppendingString:title]];
	[quitMenuItem setTitle:[@"Quit " stringByAppendingString:title]];
	[helpMenuItem setTitle:[title stringByAppendingString:@" Help"]];
	[hideMenuItem setTitle:[@"Hide " stringByAppendingString:title]];
	[topMenuItem setTitle:title];
	
	NSString * fields = [mainBundle objectForInfoDictionaryKey:@"BooksPluginFields"];
	NSArray * fieldItems = [fields componentsSeparatedByString:@","];

	[searchField removeAllItems];
	[searchField addItemsWithTitles:fieldItems];
}

- (IBAction)clear:(id)sender
{
	[resultsDataSource clearHits];
	
	[resultsTable reloadData];
}

- (void) windowWillClose:(NSNotification *) aNotification
{
	[[NSApplication sharedApplication] terminate:self];
}

@end
