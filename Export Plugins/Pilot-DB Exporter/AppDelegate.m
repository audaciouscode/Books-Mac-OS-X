//
//  AppDelegate.m
//  Pilot-DB Exporter
//
//  Created by Chris Karr on 7/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "WebKit/WebKit.h"

@implementation AppDelegate

-(void) awakeFromNib
{
	NSBundle * bundle = [NSBundle mainBundle];
	
	NSSavePanel * panel = [NSSavePanel savePanel];
	
	[panel setAccessoryView:accessoryView];
	[panel setRequiredFileType:@"pdb"];
	int results = [panel runModal];

	if (results == NSCancelButton)
	{
		[[NSApplication sharedApplication] terminate:nil];
		
		return;
	}
		
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSString * format = [defaults stringForKey:@"Database Format"];
	
	if (format == nil)
		format = @"Pilot-DB (Default)";

	[defaults setValue:format forKey:@"Database Format"];
		
	NSString * title = [defaults stringForKey:@"Database Title"];

	if (title == nil)
		title = @"My Books";

	[defaults setValue:title forKey:@"Database Title"];
	
	NSString * filePath = [panel filename];
	
	NSLog (@"%@ - %@ - %@", filePath, title, format);

	NSString * scriptPath = [bundle pathForResource:@"run" ofType:@"sh"];

	NSTask * task = [[NSTask alloc] init];
	[task setLaunchPath:scriptPath];
	[task setCurrentDirectoryPath:[scriptPath stringByDeletingLastPathComponent]];
	
	NSArray * arguments = [NSArray arrayWithObjects:title, format, filePath, nil];
	[task setArguments:arguments];
	
	NSError * error = nil;
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:@"/tmp/books-export/books-export.xml"]
							options:NSXMLDocumentTidyXML error:&error];
	
	NSXMLElement * root = [xml rootElement];
	
	NSMutableString * output = [NSMutableString string];
	
	NSArray * books = [root children];

	NSArray * outputFields = [NSArray arrayWithObjects:@"title", @"authors", @"publisher", @"genre", @"publishDate", @"format", @"edition",
								@"series", nil];
	
	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		NSXMLElement * book = [books objectAtIndex:i];
		
		if ([[book name] isEqualToString:@"Book"])
		{
			NSArray * fields = [book children];

			NSMutableDictionary * bookValues = [NSMutableDictionary dictionary];

			int j = 0;
			for (j = 0; j < [fields count]; j++)
			{
				NSXMLElement * field = [fields objectAtIndex:j];
			
				NSString * name = [[field attributeForName:@"name"] stringValue];
				NSString * value = [field stringValue];
			
				if (value != nil && name != nil)
					[bookValues setValue:value forKey:name];
			}
		
			for (j = 0; j < [outputFields count]; j++)
			{
				NSString * fieldName = [outputFields objectAtIndex:j];
				NSString * fieldValue = [bookValues valueForKey:fieldName];
			
				if (fieldValue == nil)
					fieldValue = @"";
				
				NSMutableString * value = [NSMutableString stringWithString:fieldValue];
				[value replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [value length])];
				
				[output appendFormat:@"\"%@\"", value];
			
				if (j != [outputFields count] - 1)
					[output appendString:@","];
			}
		
			[output appendString:@"\n"];
		}
	}
	
	[output writeToFile:@"/tmp/books-export/books.csv" atomically:YES encoding:NSUTF8StringEncoding error:&error];
	
	[task launch];
	[task waitUntilExit];
	
	NSString * htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
	
	[[webView mainFrame] loadData:[NSData dataWithContentsOfFile:htmlPath] MIMEType:@"text/html" textEncodingName:@"utf-8"
		baseURL:[NSURL URLWithString:[htmlPath stringByDeletingLastPathComponent]]];
	
	[webView setResourceLoadDelegate:self];
	
	[webViewWindow makeKeyAndOrderFront:self];
}

- (NSURLRequest *) webView: (WebView *) sender resource: (id) identifier willSendRequest: (NSURLRequest *) request 
	redirectResponse: (NSURLResponse *) redirectResponse fromDataSource: (WebDataSource *) dataSource
{
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	
	return nil;
}

- (void)windowWillClose:(NSNotification *)aNotification
{	
	[[NSApplication sharedApplication] terminate:nil];
}

@end
