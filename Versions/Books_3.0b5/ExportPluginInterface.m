//
//  ExportPluginInterface.m
//  Books
//
//  Created by Chris Karr on 7/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ExportPluginInterface.h"
#import "BooksAppDelegate.h"
#import "BookManagedObject.h"
#import "ListManagedObject.h"
#import "SmartList.h"

@implementation ExportPluginInterface

- (void) exportToBundle: (NSBundle *) bundle
{
	NSNotificationCenter * noteCenter = [NSNotificationCenter defaultCenter];
	[noteCenter addObserver:self selector:NSSelectorFromString(@"exitThread:") name:NSApplicationWillTerminateNotification object:nil];
	
	NSObject * exportImages = [bundle objectForInfoDictionaryKey:@"ExportImages"];
	
	if (exportImages == nil)
		exportImages = @"YES";
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	BooksAppDelegate * delegate = [[NSApplication sharedApplication] delegate];

	NSArray * books = nil;
	NSArray * lists = nil;
	NSArray * smartLists = nil;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Export Selected Items"])
	{
		books = [delegate getSelectedBooks];
		lists = [NSArray array];
		smartLists = [NSArray array];
	}
	else
	{
		books = [delegate getAllBooks];
		lists = [delegate getAllLists];
		smartLists = [delegate getAllSmartLists];
	}
	
	if ([books count] == 0)
	{
		// Run alert & return;
	}
	else
	{
		NSError * error = nil;

		BOOL isDir;
		NSString * path = @"/tmp/books-export";

		NSFileManager * manager = [NSFileManager defaultManager];

		[[[NSApplication sharedApplication] delegate] startProgressWindow:NSLocalizedString (@"Exporting data to plugin...", nil)];

		if ([manager fileExistsAtPath:path isDirectory:&isDir])
			[manager removeFileAtPath:path handler:nil];

		[manager createDirectoryAtPath:path attributes:nil];
		
		NSXMLDocument * xml = [[NSXMLDocument alloc] initWithXMLString:@"<exportData />" options:NSXMLDocumentTidyXML error:&error];
		
		NSXMLElement * root = [xml rootElement];

		int i = 0;
		for (i = 0; i < [books count]; i++)
		{
			NSAutoreleasePool * loopPool = [[NSAutoreleasePool alloc] init];
			
			BookManagedObject * book = [books objectAtIndex:i];
			NSXMLElement * element = [[NSXMLElement alloc] initWithXMLString:@"<Book />" error:&error];

			[element addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[book valueForKey:@"id"]]];
	
			NSEntityDescription * desc = [book entity];
			NSMutableArray * keys = [NSMutableArray arrayWithArray:[[desc attributesByName] allKeys]];
			[keys addObject:@"coverImage"];
			
			int j = 0;
			for (j = 0; j < [keys count]; j++)
			{
				NSString * key = [keys objectAtIndex:j];
				
				NSObject * value = [book valueForKey:key];
				
				if (value != nil)
				{
					NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
					NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:key];

					[field addAttribute:nameAttribute];
					
					if ([value isKindOfClass:[NSData class]])
					{
						if ([exportImages isEqual:@"NO"])
						{
							// Don't export images
						}
						else
						{
							if ([key isEqualToString:@"coverImage"])
							{
								NSBitmapImageRep * rep = [NSBitmapImageRep imageRepWithData:(NSData *) value];
	
								NSData * pngData = [rep representationUsingType:NSPNGFileType properties:nil];

								NSString * imagePath = [NSString stringWithFormat:@"%@/cover-%d-%d.png", path, i, j, nil];

								[manager createFileAtPath:imagePath contents:(NSData *) pngData attributes:nil];
							
								[field setStringValue:[imagePath lastPathComponent]];
							}
						}
					}
					else if ([value isKindOfClass:[NSDate class]])
					{
						NSDate * date = (NSDate *) value;
						[field setStringValue:[date descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil]];
					}
					else
					{
						[field setStringValue:[value description]];
					}

					[element addChild:field];
				}
			}

			// Check for nil's beyond this point.
			
			NSArray * userFields = [[book valueForKey:@"userFields"] allObjects];
			
			for (j = 0; j < [userFields count]; j++)
			{
				NSManagedObject * fieldPair = [userFields objectAtIndex:j];
			
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
				NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:[[fieldPair valueForKey:@"key"] description]];
				[field addAttribute:nameAttribute];

				[field setStringValue:[[fieldPair valueForKey:@"value"] description]];

				[element addChild:field];
			}

			NSArray * checkouts = [[book valueForKey:@"copiesOut"] allObjects];
			
			for (j = 0; j < [checkouts count]; j++)
			{
				NSManagedObject * checkout = [checkouts objectAtIndex:j];
			
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<checkout />" error:&error];
				
				NSXMLNode * borrower = [NSXMLNode attributeWithName:@"borrower" stringValue:[[checkout valueForKey:@"borrower"] description]];
				[field addAttribute:borrower];

				NSXMLNode * copyLent = [NSXMLNode attributeWithName:@"copyLent" stringValue:[[checkout valueForKey:@"copyLent"] description]];
				[field addAttribute:copyLent];

				NSXMLNode * dateDue = [NSXMLNode attributeWithName:@"dateDue" stringValue:[[checkout valueForKey:@"dateDue"] description]];
				[field addAttribute:dateDue];

				NSXMLNode * dateLent = [NSXMLNode attributeWithName:@"dateLent" stringValue:[[checkout valueForKey:@"dateLent"] description]];
				[field addAttribute:dateLent];

				[element addChild:field];
			}

			NSArray * copies = [[book valueForKey:@"copies"] allObjects];
			
			for (j = 0; j < [copies count]; j++)
			{
				NSManagedObject * copy = [copies objectAtIndex:j];
			
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<copy />" error:&error];
				
				NSXMLNode * condition = [NSXMLNode attributeWithName:@"condition" stringValue:[[copy valueForKey:@"condition"] description]];
				[field addAttribute:condition];

				NSXMLNode * dateAcquired = [NSXMLNode attributeWithName:@"dateAcquired" stringValue:[[copy valueForKey:@"dateAcquired"] description]];
				[field addAttribute:dateAcquired];
				
				NSXMLNode * location = [NSXMLNode attributeWithName:@"location" stringValue:[[copy valueForKey:@"location"] description]];
				[field addAttribute:location];
				
				NSXMLNode * owner = [NSXMLNode attributeWithName:@"owner" stringValue:[[copy valueForKey:@"owner"] description]];
				[field addAttribute:owner];

				NSXMLNode * presentValue = [NSXMLNode attributeWithName:@"presentValue" stringValue:[[copy valueForKey:@"presentValue"] description]];
				[field addAttribute:presentValue];

				NSXMLNode * source = [NSXMLNode attributeWithName:@"source" stringValue:[[copy valueForKey:@"source"] description]];
				[field addAttribute:source];

				[field setStringValue:[[copy valueForKey:@"inscription"] description]];

				[element addChild:field];
			}

			NSArray * feedbacks = [[book valueForKey:@"feedback"] allObjects];
			
			for (j = 0; j < [feedbacks count]; j++)
			{
				NSManagedObject * feedback = [feedbacks objectAtIndex:j];
			
				NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<feedback />" error:&error];
				
				NSXMLNode * dateFinished = [NSXMLNode attributeWithName:@"dateFinished" stringValue:[[feedback valueForKey:@"dateFinished"] description]];
				[field addAttribute:dateFinished];

				NSXMLNode * dateStarted = [NSXMLNode attributeWithName:@"dateStarted" stringValue:[[feedback valueForKey:@"dateStarted"] description]];
				[field addAttribute:dateStarted];
				
				NSXMLNode * progress = [NSXMLNode attributeWithName:@"progress" stringValue:[[feedback valueForKey:@"progress"] description]];
				[field addAttribute:progress];
				
				NSXMLNode * rating = [NSXMLNode attributeWithName:@"rating" stringValue:[[feedback valueForKey:@"rating"] description]];
				[field addAttribute:rating];
				
				NSXMLNode * submitter = [NSXMLNode attributeWithName:@"submitter" stringValue:[[feedback valueForKey:@"submitter"] description]];
				[field addAttribute:submitter];

				[field setStringValue:[[feedback valueForKey:@"comments"] description]];

				[element addChild:field];
			}

			[root addChild:element];
			
			[loopPool release];
		}
	
		for (i = 0; i < [lists count]; i++)
		{
			ListManagedObject * list = [lists objectAtIndex:i];
			NSXMLElement * element = [[NSXMLElement alloc] initWithXMLString:@"<List />" error:&error];

			[element addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[list valueForKey:@"name"]]];

			NSArray * bookArray = [[list valueForKey:@"items"] allObjects];
			
			int j = 0;
			for (j = 0; j < [bookArray count]; j++)
			{
				BookManagedObject * book = [bookArray objectAtIndex:j];
				
				NSXMLElement * bookElement = [[NSXMLElement alloc] initWithXMLString:@"<Book />" error:&error];
				[bookElement addAttribute:[NSXMLNode attributeWithName:@"ref" stringValue:[book valueForKey:@"id"]]];
				
				[element addChild:bookElement];
			}
			
			[root addChild:element];
		}

		for (i = 0; i < [smartLists count]; i++)
		{
			SmartList * list = [smartLists objectAtIndex:i];
			NSXMLElement * element = [[NSXMLElement alloc] initWithXMLString:@"<SmartList />" error:&error];

			[element addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[list valueForKey:@"name"]]];
			[element addAttribute:[NSXMLNode attributeWithName:@"predicate" stringValue:[list valueForKey:@"predicateString"]]];

			NSArray * bookArray = [[list valueForKey:@"items"] allObjects];

			int j = 0;
			for (j = 0; j < [bookArray count]; j++)
			{
				BookManagedObject * book = [bookArray objectAtIndex:j];
				
				NSXMLElement * bookElement = [[NSXMLElement alloc] initWithXMLString:@"<Book />" error:&error];
				[bookElement addAttribute:[NSXMLNode attributeWithName:@"ref" stringValue:[book valueForKey:@"id"]]];
				
				[element addChild:bookElement];
			}

			[root addChild:element];
		}
		
		[xml setCharacterEncoding:@"UTF-8"];
		
		NSData * xmlData = [xml XMLData];

		NSString * exportPath = [NSString stringWithFormat:@"%@/books-export.xml", path, nil];

		[manager createFileAtPath:exportPath contents:xmlData attributes:nil];
							
		NSString * executablePath = [bundle executablePath];

		exportTask = [NSTask launchedTaskWithLaunchPath:executablePath arguments:[NSArray array]];

		[[[NSApplication sharedApplication] delegate] endProgressWindow];
	}
	
	[pool release];

	[noteCenter removeObserver:self];
} 

- (void) exitThread:(NSNotification *) note
{
	if (exportTask != nil && [exportTask isRunning])
	{
		[exportTask terminate];
	}
}

@end
