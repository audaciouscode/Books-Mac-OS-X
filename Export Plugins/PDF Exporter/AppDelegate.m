#import "AppDelegate.h"
#import "Book.h"

@implementation AppDelegate

- (NSString *) getAuthorString:(NSString *) authors
{
	NSArray * separators = [NSArray arrayWithObjects:@";", @",", @"/", nil];
	
	NSMutableString * sortString = [[NSMutableString alloc] initWithString:authors];

	NSRange range;

	int i = 0;
	for (i = 0; i < [separators count]; i++)
	{
		range = [sortString rangeOfString:[separators objectAtIndex:i]];
		
		if (range.location != NSNotFound)
			[sortString setString:[authors substringToIndex:range.location]];
	}

	range = [sortString rangeOfString:@" " options:NSBackwardsSearch];
	
	if (range.location != NSNotFound)
	{
		NSString * lastName = [sortString substringFromIndex:range.location + 1];
		[sortString deleteCharactersInRange:NSMakeRange (range.location, [lastName length] + 1)];
		[sortString insertString:@" " atIndex:0];
		[sortString insertString:lastName atIndex:0];
	}
	
	return sortString;
}

- (NSString *) getTitleString:(NSString *) title
{
	NSArray * ignoreWords = [NSArray arrayWithObjects:@"the ", @"an ", @"a ", nil];

	int i = 0; 
	for (i = 0; i < [ignoreWords count]; i++)
	{
		NSString * ignore = (NSString *) [ignoreWords objectAtIndex:i];

		if ([title length] > [ignore length])
		{
			NSRange range = [title rangeOfString:ignore options:NSCaseInsensitiveSearch range:NSMakeRange (0, [ignore length])];

			if (range.location == 0)
			{
				NSString * sortString = [[NSString alloc] initWithString:[title substringFromIndex:[ignore length]]];
				return sortString;
			}
		}
	}
	
	return title;
}


- (IBAction)exportPDF:(id)sender
{
	NSArray * books = [records arrangedObjects];
	
	NSXMLElement * root = [[NSXMLElement alloc] initWithName:@"exportData"];
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithRootElement:root];
	
	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		NSXMLElement * book = [[NSXMLElement alloc] initWithName:@"Book"];

		Book * entry = [books objectAtIndex:i];
		
		NSArray * keys = [entry allKeys];
		
		int j = 0;
		for (j = 0; j < [keys count]; j++)
		{
			NSString * key = [keys objectAtIndex:j];

			NSObject * value = [entry valueForKey:key];
			
			if (value != nil)
			{
				NSXMLElement * field = [[NSXMLElement alloc] initWithName:@"field"];

				[field addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[key description]]];
				[field setStringValue:[value description]];
				
				[book addChild:field];
			}
		}
		
		[root addChild:book];
	}

	NSString * xmlString = [xml description];

	[xmlString writeToFile:@"/tmp/books-export/export.xml" atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	
	NSString * selectedStyle = (NSString *) [stylesMenu titleOfSelectedItem];
	
	NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
	
	NSTask * task = [[NSTask alloc] init];
	
	[task setCurrentDirectoryPath:resourcePath];
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"run" ofType:@"sh"]];
	
	NSMutableArray * arguments  = [NSMutableArray array];
	[arguments addObject:[stylesTable valueForKey:selectedStyle]];
	[arguments addObject:@"/tmp/books-export/export.xml"];
	[arguments addObject:@"/tmp/books-export/export.pdf"];

	[task setArguments:arguments];
	
	[task launch];
	[task waitUntilExit];
	
	[task release];
}

- (IBAction)createPDF:(id)sender
{
	[status setStringValue:@"Generating document..."];
	[self exportPDF:sender];
	
	PDFDocument * doc = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:@"file:///tmp/books-export/export.pdf"]];
	[pdfView setDocument:doc];
	
	[pdfView setNeedsDisplay:YES];
	
	[save setEnabled:YES];
	[print setEnabled:YES];
	[status setStringValue:[NSString stringWithFormat:@"%d Pages", [doc pageCount]]];
	
	[pdfView setNeedsDisplay:YES];
}	

- (IBAction) printPDF:(id)sender
{
	[pdfView printWithInfo:[NSPrintInfo sharedPrintInfo] autoRotate:YES];
}

- (IBAction) savePDF: (id) sender
{
	PDFDocument * doc = [pdfView document];
	
	NSSavePanel * panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"pdf"];
	
	if ([panel runModal] == NSFileHandlingPanelOKButton)
	{
		NSString * filename = [panel filename];

		[doc writeToFile:filename];
	}
}	

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];
	
	NSArray * columns = [recordTable tableColumns];
	
	int i = 0;
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
		
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}

	NSError * error;
	
	NSURL * url = [NSURL URLWithString:@"file:///tmp/books-export/books-export.xml"];
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:&error];

	if (xml != nil)
	{
		NSArray * books = [[xml rootElement] elementsForName:@"Book"];
		
		for (i = 0; i < [books count]; i++)
		{
			NSXMLElement * book = [books objectAtIndex:i];
			
			if (true) // [book 
			{
				NSArray * fields = [book elementsForName:@"field"];

				Book * bookObject = [[Book alloc] init];

				int j = 0;
				for (j = 0; j < [fields count]; j++)
				{
					NSXMLElement * field = [fields objectAtIndex:j];
				
					NSString * key = [[field attributeForName:@"name"] stringValue];
					NSString * value = [field stringValue];
				
					if ([key isEqualToString:@"title"])
						[bookObject setValue:[self getTitleString:value] forKey:@"smartTitle"];
					else if ([key isEqualToString:@"authors"])
						[bookObject setValue:[self getAuthorString:value] forKey:@"smartAuthors"];
				
					[bookObject setValue:value forKey:key];
				}
			
				[records addObject:bookObject];
			}
		}
		
		[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Smart Sort" options:NSKeyValueObservingOptionNew context:NULL];

		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Smart Sort"])
		{
			[authorsColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"smartAuthors" ascending:YES selector:@selector (compare:)]];
			[titleColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"smartTitle" ascending:YES selector:@selector (compare:)]];
		}
		else
		{
			[authorsColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"authors" ascending:YES selector:@selector (compare:)]];
			[titleColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector (compare:)]];
		}
	}
	else
	{
        NSRunAlertPanel (@"Error", @"Unable to locate book data. Check your Books installation.", @"Quit", nil, nil);
		
		[NSApp terminate:self];
	}
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
    if ([keyPath isEqual:@"Smart Sort"])
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Smart Sort"])
		{
			[authorsColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"smartAuthors" ascending:YES selector:@selector (compare:)]];
			[titleColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"smartTitle" ascending:YES selector:@selector (compare:)]];
		}
		else
		{
			[authorsColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"authors" ascending:YES selector:@selector (compare:)]];
			[titleColumn setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector (compare:)]];
		}
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[NSApp terminate:self];
}

- (NSArray *) getPrintStyles
{
	stylesTable = [[NSMutableDictionary alloc] init];
	
	NSString * appSupport = @"Library/Application Support/Books/Plugins/PDF Styles/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];
	
	NSString * path;
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"xsl"])
				[stylesTable setValue:[path stringByAppendingPathComponent:name] forKey:[name stringByDeletingPathExtension]];
		}
	}

	return [[stylesTable allKeys] retain];
}

- (void) setPrintStyles: (NSArray *) styles
{

}

/*
- (IBAction)customizeFields:(id)sender
{
	[panelWindow makeKeyAndOrderFront:self];
}

- (IBAction)doneSelectingFields:(id)sender
{
	[panelWindow orderOut:self];
}

*/

@end
