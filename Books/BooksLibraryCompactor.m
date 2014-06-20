//
//  BooksLibraryCompactor.m
//  Books
//
//  Created by Chris Karr on 8/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BooksLibraryCompactor.h"
#import "BookManagedObject.h"
#import "BooksAppDelegate.h"
#import "BooksDataFolder.h"

@implementation BooksLibraryCompactor

- (void) compact
{
	NSNotification * msg = [NSNotification notificationWithName:BOOKS_START_PROGRESS_WINDOW object:NSLocalizedString (@"Compacting Data Files...", nil)];
	[[NSNotificationCenter defaultCenter] postNotification:msg];

	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[((BooksAppDelegate *) [NSApp delegate]) managedObjectContext]]];

	NSError * error = nil;
	NSArray * books = [[((BooksAppDelegate *) [NSApp delegate]) managedObjectContext] executeFetchRequest:fetch error:&error];

	[fetch release];
	
	NSMutableArray * ids = [NSMutableArray array];
	
	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		BookManagedObject * book = [books objectAtIndex:i];
		
		[ids addObject:[book getId]];
	}
	
	NSString * imagePath = [NSString stringWithFormat:@"%@%@", [BooksDataFolder booksDataFolder], @"/Images/", nil];
							
	NSArray * images = [[NSFileManager defaultManager] directoryContentsAtPath:imagePath];
	
	for (i = 0; i < [images count]; i++)
	{
		NSMutableString * image = [NSMutableString stringWithString:[images objectAtIndex:i]];
		
		[image replaceOccurrencesOfString:@".book-image" withString:@"" options:NSCaseInsensitiveSearch 
			range:NSMakeRange (0, [image length])];
		
		if (![ids containsObject:image])
		{
			NSString * path = [NSString stringWithFormat:@"%@%@.book-image", imagePath, image];
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		}
	}

	NSString * filePath = [NSString stringWithFormat:@"%@%@", [BooksDataFolder booksDataFolder], @"/Files/", nil];

	NSArray * files = [[NSFileManager defaultManager] directoryContentsAtPath:filePath];

	for (i = 0; i < [files count]; i++)
	{
		NSMutableString * file = [NSMutableString stringWithString:[files objectAtIndex:i]];

		if (![ids containsObject:file])
		{
			NSString * path = [NSString stringWithFormat:@"%@%@", filePath, file];
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		}
	}
	
	msg = [NSNotification notificationWithName:BOOKS_END_PROGRESS_WINDOW object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:msg];
}

@end
