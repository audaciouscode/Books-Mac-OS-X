#import "AppDelegate.h"

@implementation AppDelegate

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];

	NSString * base = @"/tmp/books-export/";
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@books-export.xml", base]];
	// NSURL * url = [NSURL URLWithString:@"file:///tmp/books-export/books-export.xml"];
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:nil];
	if (xml == nil)
	{
        NSRunAlertPanel (@"Error", @"Unable to locate book data. Check your Books installation.", @"Quit", nil, nil);
		
		[NSApp terminate:self];
		return;
	}
	
	NSMutableDictionary * lists = [NSMutableDictionary dictionary];

	NSArray * books = [[xml rootElement] elementsForName:@"Book"];
		
	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		NSXMLElement * book = [books objectAtIndex:i];
		NSArray * fields = [book elementsForName:@"field"];

		NSMutableDictionary * bookObject = [NSMutableDictionary dictionary];

		int j = 0;
		for (j = 0; j < [fields count]; j++)
		{
			NSXMLElement * field = [fields objectAtIndex:j];
				
			NSString * key = [[field attributeForName:@"name"] stringValue];
			NSString * value = [field stringValue];
				
			[bookObject setValue:value forKey:key];
		}

		NSString * listName = [bookObject valueForKey:@"listName"];
			
		NSMutableArray * list = [lists valueForKey:listName];
			
		if (list == nil)
		{
			list = [NSMutableArray array];
			[lists setValue:list forKey:listName];
		}
			
		[list addObject:bookObject];
	}

	[window center];
	[window makeKeyAndOrderFront:self];

	[progressIndicator setUsesThreadedAnimation:YES];

	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:(double) ([books count] - 1)];
	[progressIndicator setMinValue:0.0];
	[progressIndicator startAnimation:self];

	[window display];

	NSArray * listNames = [lists allKeys];
	for (i = 0; i < [listNames count]; i++)
	{
		NSString * listName = [listNames objectAtIndex:i];
		
		NSString * source = [NSString stringWithFormat:@"tell application \"iPhoto\"\n\
															if not (exists album \"Books: %@\") then\n\
															new album name \"Books: %@\"\n\
															end if\n\
															end tell", listName, listName];
		
		NSAppleScript * as = [[NSAppleScript alloc] initWithSource:source];
		
		NSDictionary * error;
		
		if ([as executeAndReturnError:&error] == nil)
			NSLog (@"error = %@", error);
			
		NSArray * list = [lists valueForKey:listName];
		
		int j = 0;
		for (j = 0; j < [list count]; j++)
		{
			NSDictionary * book = [list objectAtIndex:j];
			
			NSString * cover = [book valueForKey:@"coverImage"];

			[progressIndicator incrementBy:1.0];
			[progressText setStringValue:[NSString stringWithFormat:@"Adding book %d of %d...", 
																		((int) [progressIndicator doubleValue] + 1),
																		[books count]]];

			[window display];
			
			if (cover != nil)
			{

				NSString * title = [book valueForKey:@"title"];
				
				NSString * date = [book valueForKey:@"publishDate"];
				
				if (date == nil)
					date = @"1-1-1";

				NSArray * dateParts = [date componentsSeparatedByString:@"-"];
				
				NSString * year = [dateParts objectAtIndex:0];
				NSString * month = [dateParts objectAtIndex:1];
				NSString * day = [dateParts objectAtIndex:2];
				
				NSString * importSource = [NSString stringWithFormat:@"tell application \"iPhoto\"\n\
																			set valid to false\n\
																			import from \"%@%@\" with force copy to album \"Books: %@\"\n\
																			set p to last photo of album \"Books: %@\" whose image filename is \"%@\"\n\
																			repeat until valid\n\
																				try\n\
																					set the title of p to \"%@\" \n\
																					set d to current date\n\
																					set year of d to %@\n\
																					set month of d to %@\n\
																					set day of d to %@\n\
																					set the date of p to d\n\
																					set valid to true\n\
																				on error\n\
																					set p to last photo of album \"Books: %@\" whose image filename is \"%@\"\n\
																					delay 0.1\n\
																				end try\n\
																			end repeat\n\
																			end tell", base, cover, listName, listName, cover, title, year, month, day, listName, 
																			cover];
		
				NSAppleScript * is = [[NSAppleScript alloc] initWithSource:importSource];
		
				if ([is	executeAndReturnError:&error] == nil)
					NSLog (@"error = %@", error);
			}
		}
	}

	[progressIndicator stopAnimation:self];
	[NSApp terminate:self];
}

@end
