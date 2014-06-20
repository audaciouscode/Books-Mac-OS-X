#include <stdio.h>

#import "AmazonImporterAppDelegate.h"

@implementation AmazonImporterAppDelegate

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)doSearch:(id)sender
{
	NSMutableString * fieldArguments = [NSMutableString string];
	
    if ([[fieldPulldown titleOfSelectedItem] isEqual:@"Title"])
		[fieldArguments appendString:@"keywords"];
    else if ([[fieldPulldown titleOfSelectedItem] isEqual:@"Authors"])
		[fieldArguments appendString:@"authors"];
	else
		[fieldArguments appendString:@"asin"];

	NSMutableString * localeArguments = [NSMutableString string];

    if ([[localePulldown titleOfSelectedItem] isEqual:@"Canada"])
		[localeArguments appendString:@"ca"];
    else if ([[localePulldown titleOfSelectedItem] isEqual:@"France"])
		[localeArguments appendString:@"fr"];
    else if ([[localePulldown titleOfSelectedItem] isEqual:@"Germany"])
		[localeArguments appendString:@"de"];
    else if ([[localePulldown titleOfSelectedItem] isEqual:@"Japan"])
		[localeArguments appendString:@"jp"];
    else if ([[localePulldown titleOfSelectedItem] isEqual:@"United Kingdom"])
		[localeArguments appendString:@"uk"];
	else
		[localeArguments appendString:@"us"];
	
	NSString * queryArgument = [searchField string];

	if ([fieldArguments isEqual:@""])
	{
		NSRunAlertPanel(@"Missing Fields", @"Please provide at least one field to search.", @"Ok", nil, nil);
		
		return;
	}

	if ([localeArguments isEqual:@""])
	{
		NSRunAlertPanel(@"Missing Locale", @"Please provide at least one locale to search.", @"Ok", nil, nil);
		
		return;
	}

	if ([queryArgument isEqual:@""])
	{
		NSRunAlertPanel(@"Missing Query", @"Please provide a query.", @"Ok", nil, nil);
		
		return;
	}
	
	NSArray * queries = [queryArgument componentsSeparatedByString:@"\n"];
	
	int i = 0;
	
	for (i = 0; i < [queries count]; i++)
	{
		NSString * query = [queries objectAtIndex:i];
		
		NSString * scriptPath = [[NSBundle mainBundle] pathForResource:@"amazonScript" ofType:@"py"];

		NSTask * task = [[NSTask alloc] init];
		
		[task setLaunchPath:scriptPath];
	
		NSArray * arguments = [NSArray arrayWithObjects:localeArguments, fieldArguments, query, nil];
		
		[task setArguments:arguments];
	
		NSPipe * stdinPipe = [NSPipe pipe];
		NSPipe * stdoutPipe = [NSPipe pipe];
		NSPipe * stderrPipe = [NSPipe pipe];
	
		[task setStandardError:stderrPipe];
		[task setStandardOutput:stdoutPipe];
		[task setStandardInput:stdinPipe];
	
		NSFileHandle * outHandle = [stdoutPipe fileHandleForReading];
		
		[task launch];

		NSData * outData = [outHandle readDataToEndOfFile];
		
		NSXMLDocument * xml = [[NSXMLDocument alloc] initWithData:outData options:NSXMLDocumentTidyXML error:nil];

		[resultsDataSource addXMLContents:xml];
	}
	
	[resultsTable reloadData];
}

- (IBAction) export:(id) sender
{
	NSFileHandle * fstdout = [NSFileHandle fileHandleWithStandardOutput];
	
	NSIndexSet * indexes = [resultsTable selectedRowIndexes];

	unsigned int indexInts[1024];
	
	NSRange range = NSMakeRange (0, 1024);
	
	int length = [indexes getIndexes:indexInts maxCount:1024 inIndexRange:&range];
	
	NSXMLElement * root = [[NSXMLElement alloc] initWithName:@"importedData"];
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithRootElement:root];
	
	NSXMLElement * collection = [[NSXMLElement alloc] initWithName:@"List"];
	[collection addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:@"Amazon Import"]];
	
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
	
	NSData * xmlData = [xmlString dataUsingEncoding:NSUTF8StringEncoding];

	[fstdout writeData:xmlData];
	
	fflush (stdout);
	fflush (stdout);
	
}

- (IBAction)quit:(id)sender
{
	[[NSApplication sharedApplication] terminate:sender];
}

- (IBAction)clear:(id)sender
{
	[resultsDataSource clearHits];
	[resultsTable reloadData];
}

- (IBAction) viewOnline:(id) sender
{
	NSIndexSet * selectedIndexes = [resultsTable selectedRowIndexes];
	
	unsigned int indexBuffer[128];
	
	NSRange range = NSMakeRange(0, 1024);
	
	int length = [selectedIndexes getIndexes:indexBuffer maxCount:128 inIndexRange:&range];
	
	int i = 0;
	
	for (i = 0; i < length; i++)
	{
		NSDictionary * selectedItem = [resultsDataSource getHitAtIndex:indexBuffer[i]];

		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[selectedItem objectForKey:@"url"]]];
	}
}

- (void) windowWillClose:(NSNotification *) aNotification
{
	[[NSApplication sharedApplication] terminate:self];
}

@end
