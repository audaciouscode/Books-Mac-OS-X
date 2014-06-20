#import "QuickfillSearchWindow.h"
#import "BooksAppDelegate.h"

@implementation QuickfillSearchWindow

- (IBAction)doCancel:(id)sender
{
	[[NSApplication sharedApplication] endSheet:panel];
	[panel orderOut:nil];
}

- (IBAction)doSave:(id)sender
{
	if ([[quickfillResults selectedObjects] count] > 0)
	{
		NSDictionary * dict = [[quickfillResults selectedObjects] objectAtIndex:0];

		NSArray * selectedBooks = [((BooksAppDelegate *) [NSApp delegate]) getSelectedBooks];

		BookManagedObject * book = [selectedBooks objectAtIndex:0];
	
		NSArray * keys = [dict allKeys];
	
		int i = 0;
		for (i = 0; i < [keys count]; i++)
		{
			NSString * key = [keys objectAtIndex:i];
			NSString * value = [dict valueForKey:key];
		
			if (value != nil)
			{
				BOOL replace = NO;
				
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Replace Existing Values"])
					replace = YES;
					
				[book setValueFromString:value forKey:key replace:replace];
			}
		}
	}
	
	[[NSApplication sharedApplication] endSheet:panel];
	[panel orderOut:nil];
}

- (IBAction)doSearch:(id)sender
{
	[[NSApplication sharedApplication] endSheet:panel];
	[panel orderOut:nil];
	
	[((BooksAppDelegate *) [NSApp delegate]) quickfill:sender];
}

- (NSArrayController *) getArrayController
{
	return quickfillResults;
}

- (void) setPluginName: (NSString *) name
{
	pluginName = name;
}

- (void) showResults
{
	NSArray * columns = [list tableColumns];
	
	int i = 0;
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
	
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}

	[panel setTitle:pluginName];
		
	[NSApp beginSheet:panel modalForWindow:[((BooksAppDelegate *)[NSApp delegate]) infoWindow] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification
{
	NSMutableString * htmlString = [NSMutableString string];

	if ([[quickfillResults selectedObjects] count] > 0)
	{
		NSDictionary * dict = [[quickfillResults selectedObjects] objectAtIndex:0];
	
		NSString * title = [dict valueForKey:@"title"];
		NSString * authors = [dict valueForKey:@"authors"];
		NSString * isbn = [dict valueForKey:@"isbn"];
		NSString * summary = [dict valueForKey:@"summary"];
		NSString * format = [dict valueForKey:@"format"];

		if (title != nil)
		{
			[htmlString appendString:@"<p><b>"];
			[htmlString appendString:title];
			[htmlString appendString:@"</b><p>"];
		}
	
		if (authors != nil)
		{
			[htmlString appendString:NSLocalizedString (@"<p>Authors: ", nil)];
			[htmlString appendString:authors];
			[htmlString appendString:@"<p>"];
		}

		if (isbn != nil)
		{
			[htmlString appendString:NSLocalizedString (@"<p>ISBN: ", nil)];
			[htmlString appendString:isbn];
			[htmlString appendString:@"<p>"];
		}

		if (format != nil)
		{
			[htmlString appendString:NSLocalizedString (@"<p>Format: ", nil)];
			[htmlString appendString:format];
			[htmlString appendString:@"<p>"];
		}

		if (summary != nil)
		{
			[htmlString appendString:NSLocalizedString (@"<p>Summary: ", )];
			[htmlString appendString:summary];
			[htmlString appendString:@"<p>"];
		}
	}

	WebFrame * mainFrame = [details mainFrame];
	NSURL * localhost = [NSURL URLWithString:@"http://localhost/"];
	[mainFrame loadHTMLString:htmlString baseURL:localhost];
}

	
@end
