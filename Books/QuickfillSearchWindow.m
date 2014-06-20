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

#import "QuickfillSearchWindow.h"
#import "BooksAppDelegate.h"

@implementation QuickfillSearchWindow

- (IBAction) doCancel:(id)sender
{
	[[NSApplication sharedApplication] endSheet:panel];
	[panel orderOut:nil];
}

- (void) dealloc
{
	[super dealloc];
}

- (IBAction) doSave:(id)sender
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
			NSObject * value = [dict valueForKey:key];
		
			if (value != nil && ![key isEqualToString:@"coverData"])
			{
				BOOL replace = NO;
				
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Replace Existing Values"])
					replace = YES;
					
				[book setValueFromString:((NSString *) value) forKey:key replace:replace];
			}
			else
				[book setCoverImage:((NSData *) value)];
		}
	}
	
	[[NSApplication sharedApplication] endSheet:panel];
	[panel orderOut:nil];
}

- (IBAction) doSearch:(id)sender
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
		
	[NSApp beginSheet:panel modalForWindow:[((BooksAppDelegate *)[NSApp delegate]) infoWindow] 
		modalDelegate:[NSApp delegate] 
	   didEndSelector:@selector(sheetDidEnd: returnCode: contextInfo:) contextInfo:NULL];
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
		NSString * publisher = [dict valueForKey:@"publisher"];
		NSString * date = [dict valueForKey:@"publishDate"];

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

		if (publisher != nil)
		{
			[htmlString appendString:NSLocalizedString (@"<p>Publisher: ", nil)];
			[htmlString appendString:publisher];
			[htmlString appendString:@"<p>"];
		}

		if (date != nil)
		{
			[htmlString appendString:NSLocalizedString (@"<p>Date: ", nil)];
			[htmlString appendString:date];
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
