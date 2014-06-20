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
		NSDictionary * hit = [resultsDataSource getHitAtIndex:indexInts[i]];
		
		NSXMLElement * book = [hit objectForKey:@"xmldata"];
		
		[book detach];
		
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
	
	NSString * scriptName = [bundle objectForInfoDictionaryKey:@"BooksScriptName"];
	NSString * scriptPath = [bundle pathForResource:[scriptName stringByDeletingPathExtension] 
		ofType:[scriptName pathExtension]];

	NSTask * task = [[NSTask alloc] init];

	[task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
	[task setLaunchPath:scriptPath];

	NSArray * arguments = [NSArray arrayWithObject:filePath];
	[task setArguments:arguments];
	
	NSPipe * stdinPipe = [NSPipe pipe];
	NSPipe * stdoutPipe = [NSPipe pipe];
	NSPipe * stderrPipe = [NSPipe pipe];
	
	[task setStandardError:stderrPipe];
	[task setStandardOutput:stdoutPipe];
	[task setStandardInput:stdinPipe];
	
	NSFileHandle * outHandle = [stdoutPipe fileHandleForReading];

	[progressMessage setStringValue:NSLocalizedString (@"Loading data from file. Please be patient.", nil)];
	[progressBar setUsesThreadedAnimation:YES];
	[progressWindow setTitle:NSLocalizedString (@"Loading Data", nil)];
	[progressWindow makeKeyAndOrderFront:self];
	[progressBar startAnimation:self];
	
	[task launch];
	
	NSData * outData = [outHandle readDataToEndOfFile];

	NSError * error = [[NSError alloc] init];
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithData:outData options:NSXMLDocumentTidyXML error:&error];

	[resultsDataSource addXMLContents:xml];

	[progressBar stopAnimation:self];
	[progressWindow orderOut:self];
	
	[resultsTable reloadData];
	
	[resultsTable selectAll:self];

	[window setTitle:[bundle objectForInfoDictionaryKey:@"CFBundleName"]];
	
	[window makeKeyAndOrderFront:nil];
}

@end
