//
//  HtmlPageBuilder.m
//  Books
//
//  Created by Chris Karr on 9/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "HtmlPageBuilder.h"
#import "BooksAppDelegate.h"

@implementation HtmlPageBuilder

- (NSDictionary *) getDisplayPlugins
{	
	if (displayPlugins != nil)
		return displayPlugins;
		
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
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
		int alertReturn = NSRunAlertPanel (NSLocalizedString (@"No Preferences Found", nil), NSLocalizedString (@"Is this your first time running Books? Please set your preferences", nil), 
							NSLocalizedString (@"OK", nil), nil, nil);
					
		if (alertReturn == NSAlertDefaultReturn)
		{
			[[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString (@"Default Display", nil) forKey:@"Default Display Plugin"];
			[[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString (@"Books 2.0 Importer", nil) forKey:@"Default Import Plugin"];
			[[NSUserDefaults standardUserDefaults] setObject:NSLocalizedString (@"Amazon (US)", nil) forKey:@"Default Quickfill Plugin"];
			[((BooksAppDelegate *) [[NSApplication sharedApplication] delegate]) preferences:self];
		}
		
		return nil;
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

	NSError * error;

	NSString * path = [bundle pathForResource:@"book" ofType:@"html"];
	NSMutableString * html = [NSMutableString stringWithString:[NSString stringWithContentsOfFile:path 
		encoding:NSUTF8StringEncoding error:&error]];
	
	NSString * cssPath = [self getCssPath];
		
	[html replaceOccurrencesOfString:@"-csslink-" withString:cssPath options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];

	NSArray * fields = nil;
	
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
	
	NSNumber * customFields = [prefs objectForKey:@"Custom Detail Fields"];
	NSString * customString = [prefs objectForKey:@"Detail Fields"];
	
	if (customString != nil && customFields != nil && [customFields boolValue])
		fields = [customString componentsSeparatedByString:@"\n"];
	else
	{
		NSString * fieldsPath = [self getCsvPath];
	
		NSString * fieldsString = [NSString stringWithContentsOfFile:fieldsPath encoding:NSUTF8StringEncoding
			error:&error];

		fields = [fieldsString componentsSeparatedByString:@","];
	}	
	
	NSMutableString * bookDef = [NSMutableString string];

	if (formatter == nil)
	{
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];

		NSString * dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"Custom Date Format"];
		
		if (dateFormat != nil)
			formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:NO];
		else
		{
			formatter = [[NSDateFormatter alloc] init];
			[formatter setDateStyle:NSDateFormatterLongStyle];
		}
	}
	
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

	[html replaceOccurrencesOfString:@"-bookdef-" withString:bookDef options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];
		
	return html;
}

- (NSString *) buildEmptyPage
{
	NSBundle * bundle = [NSBundle mainBundle];
	NSString * path = [bundle pathForResource:@"empty" ofType:@"html"];

	NSError * error;

	NSMutableString * html = [NSMutableString stringWithString:[NSString stringWithContentsOfFile:path 
		encoding:NSUTF8StringEncoding error:&error]];

	NSString * cssPath = [self getCssPath];
	
	[html replaceOccurrencesOfString:@"-csslink-" withString:cssPath options:NSCaseInsensitiveSearch 
		range:NSMakeRange (0, [html length])];

	return html;
}

- (NSString *) buildPageForArray: (NSArray *) array
{
	NSBundle * bundle = [NSBundle mainBundle];
	NSString * path = [bundle pathForResource:@"multiple" ofType:@"html"];

	NSError * error;

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
