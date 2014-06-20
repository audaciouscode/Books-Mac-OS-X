#import "BooksServerAppDelegate.h"

@implementation BooksServerAppDelegate

- (IBAction) browseForXml: (id) sender
{
	NSLog (@"find xml file");
	
	NSOpenPanel * open = [NSOpenPanel openPanel];
	
	if (NSOKButton == [open runModalForTypes:[NSArray arrayWithObject:@"xml"]])
	{
		NSString * openFile = [[open filenames] objectAtIndex:0];
		
		NSLog (@"open file %@", openFile);
		
		[xmlFile setStringValue:[openFile stringByDeletingLastPathComponent]];
	}
}

- (IBAction) showLog: (id) sender
{
	NSLog (@"log");
}

- (IBAction) startServer: (id)sender
{
	NSString * siteNameText = [siteName stringValue];
	NSString * tcpPortText = [tcpPort stringValue];
	NSString * xmlFileText = [xmlFile stringValue];

	if (![siteNameText isEqual:@""] && ![tcpPortText isEqual:@""] && ![xmlFileText isEqual:@""])
	{
		NSLog (@"start");
		
		NSString * serverPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/HTTP-Server"];
		
		serverTask = [[NSTask alloc] init];
		
		[serverTask setCurrentDirectoryPath:serverPath];
		[serverTask setLaunchPath:[serverPath stringByAppendingString:@"/run.sh"]];
		[serverTask setArguments:[NSArray arrayWithObjects:xmlFileText, tcpPortText, siteNameText, nil]];
		
		[serverTask launch];
		
		[stopButton setEnabled:YES];

		[startButton setEnabled:NO];
		[siteName setEnabled:NO];
		[tcpPort setEnabled:NO];
		[xmlFile setEnabled:NO];
		[browseButton setEnabled:NO];

		[progress startAnimation:self];
	}
}

- (IBAction) stopServer: (id)sender
{
	if (serverTask != nil && [serverTask isRunning])
	{
		NSLog (@"stop");

		[serverTask terminate];

		[serverTask waitUntilExit];
		
		[startButton setEnabled:YES];
		[siteName setEnabled:YES];
		[tcpPort setEnabled:YES];
		[xmlFile setEnabled:YES];
		[browseButton setEnabled:YES];

		[stopButton setEnabled:NO];

		[progress stopAnimation:self];
	}
}


- (BOOL) windowShouldClose: (id) sender
{
	[[NSApplication sharedApplication] terminate:sender];
	
	return YES;
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) sender
{
	[self stopServer:sender];
	
	return NSTerminateNow;
}

@end
