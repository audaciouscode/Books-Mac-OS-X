//
//  QuickFillPluginInterface.m
//  Books
//
//  Created by Chris Karr on 10/23/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QuickfillPluginInterface.h"
#import "BooksAppDelegate.h"
#import <CoreData/CoreData.h>

@implementation QuickfillPluginInterface

- (void) batchImportFromBundle: (NSBundle *) bundle forBook: (BookManagedObject *) bookObject replace:(BOOL) doReplace
{
	book = bookObject;
	
	replace = doReplace;

	if (executablePath == nil)
	{
		NSString * scriptName = [bundle objectForInfoDictionaryKey:@"BooksScriptName"];
		executablePath = [bundle pathForResource:[scriptName stringByDeletingPathExtension] ofType:[scriptName pathExtension]];
	}
	
	NSPipe * stdoutPipe = [NSPipe pipe];

	if (stdoutPipe == nil)
		return;

	importTask = [[NSTask alloc] init];

	[importTask setStandardOutput:stdoutPipe];

	[importTask setLaunchPath:executablePath];

	NSFileHandle * out = [[stdoutPipe fileHandleForReading] retain];

	NSXMLDocument * document = [self getXmlDocumentForBook:book];

	NSData * xmlData = [document XMLData];
	[xmlData writeToFile:@"/tmp/books-quickfill.xml" atomically:YES];
	
	[document release];
	document = nil;

	[importTask launch];
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithData:[out readDataToEndOfFile] options:NSXMLDocumentTidyXML error:nil];

	[out closeFile];
	[out release];
	out = nil;
	
	[importTask release];
	importTask = nil;

	[self setDataForBook:book fromXml:xml];

	[xml release];
	xml = nil;
}

- (NSXMLDocument *) getXmlDocumentForBook:(BookManagedObject *) bookObject
{
	NSEntityDescription * bookDesc = [bookObject entity];
	NSMutableArray * keys = [NSMutableArray arrayWithArray:[[bookDesc attributesByName] allKeys]];

	NSError * error = nil;
	NSXMLElement * element = [[NSXMLElement alloc] initWithXMLString:@"<Book />" error:&error];

	int i = 0;
	for (i = 0; i < [keys count]; i++)
	{
		NSString * key = [keys objectAtIndex:i];
				
		NSObject * value = [bookObject valueForKey:key];
		
		if (value != nil)
		{
			NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
			NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:key];

			[field addAttribute:nameAttribute];

			if ([value isKindOfClass:[NSDate class]])
			{
				NSDate * date = (NSDate *) value;
				[field setStringValue:[date descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil]];
			}
			else
				[field setStringValue:[value description]];
			
			if (!([key isEqualToString:@"title"] && [value isEqual:NSLocalizedString (@"New Book", nil)]))
				[element addChild:field];
		}
	}

	NSArray * userFields = [[bookObject valueForKey:@"userFields"] allObjects];
			
	for (i = 0; i < [userFields count]; i++)
	{
		NSManagedObject * fieldPair = [userFields objectAtIndex:i];

		NSString * valueString = [[fieldPair valueForKey:@"value"] description];

		if (valueString != nil)
		{
			NSXMLElement * field = [[NSXMLElement alloc] initWithXMLString:@"<field />" error:&error];
			NSXMLNode * nameAttribute = [NSXMLNode attributeWithName:@"name" stringValue:[[fieldPair valueForKey:@"key"] description]];

			[field addAttribute:nameAttribute];
			[field setStringValue:valueString];

			[element addChild:field];
		}
	}

	NSXMLDocument * document = [[NSXMLDocument alloc] initWithRootElement:element];

	return document;
}

- (void) importFromBundle: (NSBundle *) bundle forBook: (BookManagedObject *) bookObject replace:(BOOL) doReplace
{
	book = bookObject;
	replace = doReplace;
	
	if (executablePath == nil)
	{
		NSString * scriptName = [bundle objectForInfoDictionaryKey:@"BooksScriptName"];
		executablePath = [bundle pathForResource:[scriptName stringByDeletingPathExtension] ofType:[scriptName pathExtension]];

		QuickfillSearchWindow * quickfillWindow = [[NSApp delegate] getQuickfillResultsWindow];
		[quickfillWindow setPluginName:[bundle objectForInfoDictionaryKey:@"BooksPluginName"]];
	}
	
	importTask = [[NSTask alloc] init];

	NSPipe * stdoutPipe = [NSPipe pipe];

	[importTask setStandardOutput:stdoutPipe];
	[importTask setLaunchPath:executablePath];
	
	NSFileHandle * out = [[stdoutPipe fileHandleForReading] retain];

	NSXMLDocument * document = [self getXmlDocumentForBook:book];

	NSData * xmlData = [document XMLData];
	[xmlData writeToFile:@"/tmp/books-quickfill.xml" atomically:YES];

	[document release];
	document = nil;
	
	[importTask launch];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishImport:) 
		name:NSFileHandleReadToEndOfFileCompletionNotification object:nil];

	[out readToEndOfFileInBackgroundAndNotify];
}

- (void) finishImport: (NSNotification *) notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	NSDictionary * userInfo = [notification userInfo];
	
	NSData * importData = [userInfo valueForKey:NSFileHandleNotificationDataItem];

	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithData:importData options:NSXMLDocumentTidyXML error:nil];

	QuickfillSearchWindow * quickfillWindow = [[NSApp delegate] getQuickfillResultsWindow];

	NSArrayController * quickfillArray = [quickfillWindow getArrayController];
	[quickfillArray removeObjects:[quickfillArray arrangedObjects]];
	
	if (xml != nil)
	{
		NSXMLElement * root = (NSXMLElement *) [[xml rootElement] childAtIndex:0];

		NSArray * bookList = [root elementsForName:@"Book"];

		if ([bookList count] > 0)
		{
			int i = 0;
			for (i = 0; i < [bookList count]; i++)
			{
				NSXMLElement * bookElement = [bookList objectAtIndex:i];
				
				NSMutableDictionary * dict = [NSMutableDictionary dictionary];
		
				NSArray * fields = [bookElement elementsForName:@"field"];
				
				int j = 0;
				for (j = 0; j < [fields count]; j++)
				{
					NSXMLElement * bookField = [fields objectAtIndex:j];

					NSXMLNode * nameAttribute = [bookField attributeForName:@"name"];

					if ([[nameAttribute stringValue] isEqualToString:@"CoverImageURL"])
						[nameAttribute setStringValue:@"coverImage"];
						
					[dict setValue:[bookField stringValue] forKey:[nameAttribute stringValue]];
				}
				
				[quickfillArray addObject:dict];
			}
			
			[quickfillArray setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
		}

		[xml release];
		xml = nil;
	}

	[((BooksAppDelegate *) [NSApp delegate]) stopQuickfill];

	[quickfillWindow showResults];
}

- (void) killTask
{
	if (importTask != nil)
		[importTask terminate];
}

- (void) setDataForBook: (BookManagedObject *) bookObject fromXml:(NSXMLDocument *) xml
{
	if (xml != nil)
	{
		NSXMLElement * root = (NSXMLElement *) [[xml rootElement] childAtIndex:0];

		NSArray * bookList = [root elementsForName:@"Book"];

		if ([bookList count] > 0)
		{
			NSXMLElement * bookElement = [bookList objectAtIndex:0];

			NSArray * bookAttributes = [bookElement attributes];
			
			int k = 0;
			
			for (k = 0; k < [bookAttributes count]; k++)
			{
				NSXMLNode * bookAttribute = [bookAttributes objectAtIndex:k];

				[bookObject setValueFromString:[bookAttribute stringValue] forKey:[bookAttribute name] replace:replace];
			}

			NSArray * fields = [bookElement elementsForName:@"field"];
			
			for (k = 0; k < [fields count]; k++)
			{
				NSXMLElement * bookField = [fields objectAtIndex:k];

				NSXMLNode * nameAttribute = [bookField attributeForName:@"name"];

				[bookObject setValueFromString:[bookField stringValue] forKey:[nameAttribute stringValue] replace:replace];
			}
		}
	}
}

@end
