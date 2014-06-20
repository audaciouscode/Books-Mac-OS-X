//
//  TemplateExporter.m
//  TemplateExporter
//
//  Created by Chris Karr on 10/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TemplateExporter.h"


@implementation TemplateExporter

- (void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:YES];
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
	NSBundle * bundle = [NSBundle mainBundle];

	NSSavePanel * fileSave = [NSSavePanel savePanel];
	[fileSave setAllowedFileTypes:[NSArray arrayWithObject:@""]];
	[fileSave setCanCreateDirectories:YES];
	
	int results = [fileSave runModal];

	[quitMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString (@"Quit %@", nil), 
		[bundle objectForInfoDictionaryKey:@"CFBundleName"], nil]];

	if (results == NSCancelButton)
	{
		[[NSApplication sharedApplication] terminate:nil];
		
		return;
	}
	
	[progressIndicator startAnimation:self];
    [progressWindow makeKeyAndOrderFront:self];

	NSString * filePath = [fileSave filename];
	
	NSString * scriptName = [bundle objectForInfoDictionaryKey:@"BooksScriptName"];
	NSString * scriptPath = [bundle pathForResource:[scriptName stringByDeletingPathExtension] 
		ofType:[scriptName pathExtension]];

	NSTask * task = [[NSTask alloc] init];
	
	[task setLaunchPath:scriptPath];
	[task setCurrentDirectoryPath:[scriptPath stringByDeletingLastPathComponent]];
	
	NSArray * arguments = [NSArray arrayWithObject:filePath];
	[task setArguments:arguments];
	
	[task launch];
	
	[task waitUntilExit];

    [progressWindow orderOut:self];
	[progressIndicator stopAnimation:self];
	
	int result = NSRunAlertPanel (@"Site Complete!", @"Your website has been successfully generated.", @"OK", @"View Site", nil);
	
	if (result == NSAlertAlternateReturn)
		[[NSWorkspace sharedWorkspace] openFile:[filePath stringByAppendingString:@"/index.html"]];
	
	[[NSApplication sharedApplication] terminate:nil];
}

@end
