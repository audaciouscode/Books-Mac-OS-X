//
//  BooksDataFolder.m
//  Books
//
//  Created by Chris Karr on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BooksDataFolder.h"

#define CUSTOM_FOLDER @"Books Data Folder"

@implementation BooksDataFolder

+ (NSString *) booksDataFolder
{
	NSString * customFolder = [[NSUserDefaults standardUserDefaults] stringForKey:CUSTOM_FOLDER];
	
	if (customFolder == nil)
	{
		NSString * applicationSupportFolder = nil;
		FSRef foundRef;
		OSErr err = FSFindFolder (kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);

		if (err != noErr) 
		{
			NSRunAlertPanel (NSLocalizedString (@"Alert", nil), NSLocalizedString (@"Can't find application support folder", nil), 
								NSLocalizedString (@"Quit", nil), nil, nil);
			[[NSApplication sharedApplication] terminate:self];
		}
		else 
		{
			unsigned char path[1024];
			FSRefMakePath (&foundRef, path, sizeof(path));
			applicationSupportFolder = [NSString stringWithUTF8String:(char *) path];
			applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"Books"];
		}
	
		return applicationSupportFolder;
	}
		
	return customFolder;
}

@end
