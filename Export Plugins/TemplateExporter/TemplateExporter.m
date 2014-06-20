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
	[fileSave setRequiredFileType:nil];
	
	int results = [fileSave runModal];

	[quitMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString (@"Quit %@", nil), 
		[bundle objectForInfoDictionaryKey:@"CFBundleName"], nil]];

	if (results == NSCancelButton)
	{
		[[NSApplication sharedApplication] terminate:nil];
		
		return;
	}
	
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
	
	[[NSApplication sharedApplication] terminate:nil];
}

@end
