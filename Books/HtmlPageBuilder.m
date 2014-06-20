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

#import "HtmlPageBuilder.h"
#import "BooksAppDelegate.h"
#import "BooksDataFolder.h"

@implementation HtmlPageBuilder

- (void) dealloc
{
	[super dealloc];
}

- (NSDictionary *) getDisplayPlugins
{	
	if (displayPlugins != nil)
		return displayPlugins;
		
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [[BooksDataFolder booksDataFolder] stringByAppendingString:@"/Plugins"];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	displayPlugins = [[NSMutableDictionary alloc] init];
 
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
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Display"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[displayPlugins setObject:plugin forKey:pluginName];
					[pluginName release];
				}
			}
		}
	}
	
	return displayPlugins;
}

- (NSBundle *) getDisplayPlugin
{
	NSString * pluginKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Display Plugin"];

	if (pluginKey == nil || [pluginKey isEqualToString:@""])
	{
		[[NSUserDefaults standardUserDefaults] setObject:@"Default Display" forKey:@"Default Display Plugin"];
		[[NSUserDefaults standardUserDefaults] setObject:@"Books 2.0 Importer" forKey:@"Default Import Plugin"];
		[[NSUserDefaults standardUserDefaults] setObject:@"Books Folder Exporter" forKey:@"Default Export Plugin"];
		[[NSUserDefaults standardUserDefaults] setObject:@"Amazon (US)" forKey:@"Default Quickfill Plugin"];

		return [self getDisplayPlugin];
	}

	return (NSBundle *) [[self getDisplayPlugins] objectForKey:pluginKey];
}

- (NSString *) getCssPath
{
	NSString * cssPath = [[self getDisplayPlugin] pathForResource:@"stylesheet" ofType:@"css"];
	
	if (cssPath != nil)
		return [[NSURL fileURLWithPath:cssPath] description];
	else
		return @"";
}

- (NSString *) getCsvPath
{
	NSString * csvPath = [[self getDisplayPlugin] pathForResource:@"fields" ofType:@"csv"];

	if (csvPath != nil)
		return csvPath;

	return @"";
}

- (NSString *) buildPageForObject: (BookManagedObject *) object
{
	NSBundle * bundle = [NSBundle mainBundle];

	NSError * error = nil;

	NSString * path = [bundle pathForResource:@"book" ofType:@"html"];
	NSMutableString * html = [NSMutableString stringWithString:[NSString stringWithContentsOfFile:path 
		encoding:NSUTF8StringEncoding error:&error]];
	
	NSString * cssPath = [self getCssPath];
		
	[html replaceOccurrencesOfString:@"-csslink-" withString:cssPath options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];

	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	
	NSNumber * customFields = [prefs objectForKey:@"Custom Detail Fields"];
	NSMutableArray * fields = [NSMutableArray array];
	NSString * customString = [prefs objectForKey:@"Custom Book User Fields"];
	
	if (customFields != nil && [customFields boolValue])
	{
		NSArray * detailFields = [prefs objectForKey:@"Detail Fields"];
		
		int i = 0;
		for (i = 0; i < [detailFields count]; i++)
		{
			NSDictionary * field = [detailFields objectAtIndex:i];
			
			NSNumber * enabled = [field valueForKey:@"Enabled"];
			
			if (enabled != nil && [enabled boolValue])
				[fields addObject:[field valueForKey:@"Key"]];
		}

		[fields addObjectsFromArray:[customString componentsSeparatedByString:@"\n"]];
	}
	else
	{
		NSString * fieldsPath = [self getCsvPath];
	
		NSString * fieldsString = [NSString stringWithContentsOfFile:fieldsPath 
			encoding:NSUTF8StringEncoding error:&error];

		[fields addObjectsFromArray:[fieldsString componentsSeparatedByString:@","]];
	}	
	
	NSMutableString * bookDef = [NSMutableString string];

	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSString * dateFormat = [[NSApp delegate] getDateFormatString];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:NO];
	
	int i = 0;
	for (i = 0; i < [fields count]; i++)
	{
		NSString * field = [fields objectAtIndex:i];
		NSObject * value = nil;
		
		NS_DURING
			value = [object valueForKey:field];
		NS_HANDLER
			value = [object customValueForKey:field];
		NS_ENDHANDLER

		if (value != nil)
		{
			if ([value isKindOfClass:[NSString class]])
			{
				NSString * stringValue = (NSString *) value;
			
				if (![stringValue isEqualToString:@""])
				{
					NSMutableString * printString = [NSMutableString stringWithString:stringValue];
					
					[printString replaceOccurrencesOfString:@"\n" withString:@"<br />" options:NSCaseInsensitiveSearch
						range:NSMakeRange (0, [printString length])];
					
					[bookDef appendString:@"\t<div class=\"book-"];
					[bookDef appendString:field];
					[bookDef appendString:@"\">"];
			
					if ([field isEqualToString:@"borrowers"])
						[printString replaceOccurrencesOfString:@"; " withString:@"<br />\n" 
							options:nil range:NSMakeRange (0, [printString length])];
						
					[bookDef appendString:printString];
			
					[bookDef appendString:@"</div>\n"];
				}
			}
			else if ([value isKindOfClass:[NSDate class]])
			{
				NSDate * date = (NSDate *) value;
				
				[bookDef appendString:@"\t<div class=\"book-"];
				[bookDef appendString:field];
				[bookDef appendString:@"\">"];
			
				[bookDef appendString:[formatter stringFromDate:date]];
			
				[bookDef appendString:@"</div>\n"];
			}
		}
	}
	
	[formatter release];

	[html replaceOccurrencesOfString:@"-bookdef-" withString:bookDef options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];
		
	return html;
}

- (NSString *) buildEmptyPage
{
	NSBundle * bundle = [NSBundle mainBundle];
	NSString * path = [bundle pathForResource:@"empty" ofType:@"html"];

	NSError * error = nil;

	NSMutableString * html = [NSMutableString stringWithString:[NSString stringWithContentsOfFile:path 
		encoding:NSUTF8StringEncoding error:&error]];

	NSString * cssPath = [self getCssPath];
	
	[html replaceOccurrencesOfString:@"-csslink-" withString:cssPath options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];

	return html;
}

- (NSString *) buildPageForArray:(NSArray *) array
{
	NSBundle * bundle = [NSBundle mainBundle];
	NSString * path = [bundle pathForResource:@"multiple" ofType:@"html"];

	NSError * error = nil;

	NSMutableString * html = [NSMutableString stringWithString:[NSString stringWithContentsOfFile:path 
		encoding:NSUTF8StringEncoding error:&error]];

	NSString * cssPath = [self getCssPath];
	
	[html replaceOccurrencesOfString:@"-csslink-" withString:cssPath options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];

	NSMutableString * bookList = [NSMutableString string];
	
	int i = 0;
	for (i = 0; i < [array count]; i++)
	{
		[bookList appendString:@"<p class=\"booklist-item\"><div class=\"booklist-title\">"];
		
		BookManagedObject * object = (BookManagedObject *) [array objectAtIndex:i];
		
		NSString * title = [object valueForKey:@"title"];
		
		if (title != nil && ![title isEqualToString:@""])
			[bookList appendString:title];
		else
			[bookList appendString:NSLocalizedString(@"Untitled Book", nil)];
			
		[bookList appendString:@"</div><div class=\"booklist-authors\">"];
		
		NSString * authors = [object valueForKey:@"authors"];
		
		if (authors != nil && ![authors isEqualToString:@""])
		{
			[bookList appendString:authors];
		}
		
		[bookList appendString:@"</div></p>\n"];
	}

	[html replaceOccurrencesOfString:@"-booklist-" withString:bookList options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];

	return html;
}

@end
