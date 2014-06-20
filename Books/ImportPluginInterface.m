/*
   Copyright (c) 2006 Chris J. Karr

   Permission is hereby granted, free of charge, to any person 
   obtaining a copy of this software and associated documentation 
   files (the "Software"), to deal in the Software without restriction, 
   including without limitation the rights to use, copy, modify, merge, 
   publish, distribute, sublicense, and/or sell copies of the Software, 
   and to permit persons to whom the Software is furnished to do so, 
   subject to the following conditions:

   The above copyright notice and this permission notice shall be 
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
   SOFTWARE.
*/


#import "ImportPluginInterface.h"
#import "BooksAppDelegate.h"
#import "CheckOutManagedObject.h"
#import "CopyManagedObject.h"
#import "NotificationInterface.h"

@implementation ImportPluginInterface

- (void) dealloc
{
	[super dealloc];
}

- (void) importFromBundle: (NSBundle *) bundle
{
	NSNotificationCenter * noteCenter = [NSNotificationCenter defaultCenter];
	[noteCenter addObserver:self selector:NSSelectorFromString(@"exitThread:") name:NSApplicationWillTerminateNotification object:nil];
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	BooksAppDelegate * delegate = [[NSApplication sharedApplication] delegate];
	NSManagedObjectContext * context = [delegate managedObjectContext];

	NSManagedObjectModel * model = [delegate managedObjectModel];
	NSEntityDescription * collectionDesc = [[model entitiesByName] objectForKey:@"List"];
	NSEntityDescription * bookDesc = [[model entitiesByName] objectForKey:@"Book"];
	NSEntityDescription * copyDesc = [[model entitiesByName] objectForKey:@"Copy"];
	NSEntityDescription * feedbackDesc = [[model entitiesByName] objectForKey:@"Feedback"];
	NSEntityDescription * checkoutDesc = [[model entitiesByName] objectForKey:@"CheckOut"];

	NSMutableDictionary * bookIdMap = [NSMutableDictionary dictionary];
	
	NSString * executablePath = [bundle executablePath];
	
	importTask = [[NSTask alloc] init];

	NSPipe * stdinPipe = [NSPipe pipe];
	NSPipe * stdoutPipe = [NSPipe pipe];
	NSPipe * stderrPipe = [NSPipe pipe];

	[importTask setStandardError:stderrPipe];
	[importTask setStandardOutput:stdoutPipe];
	[importTask setStandardInput:stdinPipe];
	
	[importTask setLaunchPath:executablePath];
	
	NSFileHandle * out = [stdoutPipe fileHandleForReading];

	[importTask launch];

	int bookCount = 0;
	while ([importTask isRunning])
	{
		NSMutableData * importData = [NSMutableData data];
	
		NSData * data = nil;
		
		NSXMLDocument * xml = nil;
		
//		NSRange stringRange;
		
		do
		{
//			data = [out availableData];
			
			data = [out readDataOfLength:16384];
				
			[importData appendData:data];
			
/*			NSString * string = [[NSString alloc] initWithData:importData encoding:NSUTF8StringEncoding];
			stringRange = [string rangeOfString:@"</importedData>" options:NSBackwardsSearch];
			
			[string release];
			
			if (stringRange.location != NSNotFound)
				data = [NSData data];
*/		}
		while ([data length] > 0);
		
		NSError * error = nil;
			
		// xml = [[NSXMLDocument alloc] initWithData:importData options:NSXMLDocumentTidyXML|NSXMLDocumentValidate error:nil];
		xml = [[NSXMLDocument alloc] initWithData:importData options:NSXMLDocumentTidyXML error:&error];
		
		NSLog (@"error = %@", error);
		
		if (xml != nil)
		{
			[[[NSApplication sharedApplication] delegate] startProgressWindow:@"Importing data from plugin..."];

			[context lock];
			ListManagedObject * listObject = [[ListManagedObject alloc] initWithEntity:collectionDesc insertIntoManagedObjectContext:context];
			[context unlock];

			NSXMLElement * root = [xml rootElement];

			NSArray * collectionList = nil;
		
			if ([[root name] isEqual:@"List"])
				collectionList = [NSArray arrayWithObject:root];
			else
				collectionList = [root elementsForName:@"List"];
	
			int i = 0;
	
			for (i = 0; i < [collectionList count]; i++)
			{
				NSXMLElement * list = [collectionList objectAtIndex:i];
		
				NSArray * attributes = [list attributes];
		
				int j = 0;
			
				for (j = 0; j < [attributes count]; j++)
				{
					NSXMLNode * attribute = [attributes objectAtIndex:j];

					[context lock];
					[listObject setValue:[attribute stringValue] forKey:[attribute name]];
					[context unlock];
				}
		
				[context lock];
				NSMutableSet * items = [listObject mutableSetValueForKey:@"items"];
				[context unlock];
				
				NSArray * bookList = [list elementsForName:@"Book"];

				for (j = 0; j < [bookList count]; j++)
				{
					NSXMLElement * book = [bookList objectAtIndex:j];

					[context lock];
					BookManagedObject * bookObject = [[BookManagedObject alloc] initWithEntity:bookDesc insertIntoManagedObjectContext:context];
					[context unlock];

					NSArray * bookAttributes = [book attributes];
			
					int k = 0;
			
					for (k = 0; k < [bookAttributes count]; k++)
					{
						NSXMLNode * bookAttribute = [bookAttributes objectAtIndex:k];

						if ([[bookAttribute name] isEqualToString:@"id"])
						{
							[bookIdMap setValue:bookObject forKey:[bookAttribute stringValue]];
						}

						[self book:bookObject setValueFromString:[bookAttribute stringValue] forKey:[bookAttribute name]];
					}
			
					NSArray * fields = [book elementsForName:@"field"];
			
					for (k = 0; k < [fields count]; k++)
					{
						NSXMLElement * bookField = [fields objectAtIndex:k];

						NSXMLNode * nameAttribute = [bookField attributeForName:@"name"];

						[self book:bookObject setValueFromString:[bookField stringValue] forKey:[nameAttribute stringValue]];
					}

					NSArray * checkouts = [book elementsForName:@"checkout"];
			
					NSMutableSet * checkoutSet = [bookObject mutableSetValueForKey:@"copiesOut"];
					
					for (k = 0; k < [checkouts count]; k++)
					{
						NSXMLElement * checkout = [checkouts objectAtIndex:k];

						CheckOutManagedObject * object = [[CheckOutManagedObject alloc] initWithEntity:checkoutDesc insertIntoManagedObjectContext:context];

						[object setValue:[[checkout attributeForName:@"borrower"] stringValue] forKey:@"borrower"];
						[object setValue:[[checkout attributeForName:@"copyLent"] stringValue] forKey:@"copyLent"];
						[object setValue:[NSDate dateWithNaturalLanguageString:[[checkout attributeForName:@"dateLent"] stringValue]] forKey:@"dateLent"];
						[object setValue:[NSDate dateWithNaturalLanguageString:[[checkout attributeForName:@"dateDue"] stringValue]] forKey:@"dateDue"];

						[checkoutSet addObject:object];
						
						[object release];
					}

					NSArray * copies = [book elementsForName:@"copy"];
			
					NSMutableSet * copiesSet = [bookObject mutableSetValueForKey:@"copies"];
					
					for (k = 0; k < [copies count]; k++)
					{
						NSXMLElement * copy = [copies objectAtIndex:k];

						CopyManagedObject * object = [[CopyManagedObject alloc] initWithEntity:copyDesc insertIntoManagedObjectContext:context];

						[object setValue:[[copy attributeForName:@"condition"] stringValue] forKey:@"condition"];
						[object setValue:[[copy attributeForName:@"location"] stringValue] forKey:@"location"];
						[object setValue:[[copy attributeForName:@"owner"] stringValue] forKey:@"owner"];
						[object setValue:[[copy attributeForName:@"presentValue"] stringValue] forKey:@"presentValue"];
						[object setValue:[[copy attributeForName:@"source"] stringValue] forKey:@"source"];
						[object setValue:[NSDate dateWithNaturalLanguageString:[[copy attributeForName:@"dateAcquired"] stringValue]] forKey:@"dateAcquired"];

						[object setValue:[copy stringValue] forKey:@"inscription"];

						[copiesSet addObject:object];
						[object release];
					}

					NSArray * feedbacks = [book elementsForName:@"feedback"];
			
					NSMutableSet * feedbackSet = [bookObject mutableSetValueForKey:@"feedback"];
					
					for (k = 0; k < [feedbacks count]; k++)
					{
						NSXMLElement * feedback = [feedbacks objectAtIndex:k];

						NSManagedObject * object = [[NSManagedObject alloc] initWithEntity:feedbackDesc insertIntoManagedObjectContext:context];

						[object setValue:[[feedback attributeForName:@"progress"] stringValue] forKey:@"progress"];
						[object setValue:[[feedback attributeForName:@"rating"] stringValue] forKey:@"rating"];
						[object setValue:[[feedback attributeForName:@"submitter"] stringValue] forKey:@"submitter"];
						
						if ([feedback attributeForName:@"dateFinished"] != nil)
							[object setValue:[NSDate dateWithNaturalLanguageString:[[feedback attributeForName:@"dateFinished"] stringValue]] forKey:@"dateFinished"];

						if ([feedback attributeForName:@"dateStarted"] != nil)
							[object setValue:[NSDate dateWithNaturalLanguageString:[[feedback attributeForName:@"dateStarted"] stringValue]] forKey:@"dateStarted"];

						[object setValue:[feedback stringValue] forKey:@"comments"];

						[feedbackSet addObject:object];
						[object release];
					}

					[context lock];
					[items addObject:bookObject];
					[context unlock];

					bookCount++;

					NSEnumerator * files = [[book elementsForName:@"file"] objectEnumerator];
					NSXMLElement * file = nil;
					
					while ((file = [files nextObject]) != nil)
					{
						NSString * location = [[file attributeForName:@"location"] stringValue];
						NSString * title = [[file attributeForName:@"name"] stringValue];
						NSString * desc = [[file attributeForName:@"description"] stringValue];
					
						[bookObject addNewFile:location title:title description:desc];
					}
					
					[bookObject release];
				}

				NSArray * refList = [list elementsForName:@"Reference"];
		
				for (j = 0; j < [refList count]; j++)
				{
					NSXMLElement * ref = [refList objectAtIndex:j];
			
					NSXMLNode * refId = [ref attributeForLocalName:@"id" URI:nil];
			
					if (refId != nil)
					{
						NSString * refIdValue = [refId stringValue];
				
						NSManagedObject * refObject = [bookIdMap objectForKey:refIdValue];

						[context lock];
						[items addObject:refObject];
						[context unlock];
					}
				}
			}

			[listObject release];
			
			[[[NSApplication sharedApplication] delegate] saveAction:self];

			[[NSApplication sharedApplication] deactivate];
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
			
			[[[NSApplication sharedApplication] delegate] endProgressWindow];
		}
		
		[xml release];
		xml = nil;
	}

	NSString * desc = [NSString stringWithFormat:
		NSLocalizedString (@"Books has finished importing %d records.", nil), bookCount, nil];
	[NotificationInterface sendMessage:desc withTitle:NSLocalizedString (@"Import Complete", nil)];

	[pool release];

	[noteCenter removeObserver:self];
} 

- (void) exitThread:(NSNotification *) note
{
	if (importTask != nil && [importTask isRunning])
	{
		[importTask terminate];
	}
}

- (void) book:(BookManagedObject *) bookObject setValueFromString:(NSString *) valueString forKey:(NSString *) key
{
	NSManagedObjectContext * context = [bookObject managedObjectContext];

	if ([[key lowercaseString] isEqual:@"isbn"])
		key = @"isbn";

	NSObject * value = nil;
	
	if (([key isEqual:@"CoverImageURL"] || [key isEqual:@"coverImage"]) && ![valueString isEqualToString:@""]) 
	{
		if (valueString == nil)
			valueString = @"";
			
		NSMutableString * mutableString = [NSMutableString stringWithString:valueString];
		
		if ([[valueString substringToIndex:1] isEqualToString:@"/"])
			mutableString = [NSMutableString stringWithFormat:@"file://%@", valueString, nil];

		[mutableString replaceOccurrencesOfString:@" " withString:@"%20" options:nil range:NSMakeRange (0, [mutableString length])];
		
		key = @"coverImage";

		value = (NSData *) [NSData dataWithContentsOfURL:[NSURL URLWithString:mutableString]];		
	}
	else if ([key isEqualToString:@"publishDate"] || 
			 [key isEqualToString:@"dateLent"] ||
			 [key isEqualToString:@"dateDue"] ||
			 [key isEqualToString:@"dateFinished"] ||
			 [key isEqualToString:@"dateAcquired"] ||
			 [key isEqualToString:@"dateStarted"] )
	{
		value = [NSDate dateWithNaturalLanguageString:valueString];
	}
	else if ([key isEqual:@"title"])
	{
		if (valueString == nil)
			valueString = @"";

		value = [NSMutableString stringWithString:valueString];
		[(NSMutableString *) value replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch 
			range:NSMakeRange(0, [(NSMutableString *) value length])];
	}
	else
	{
		value = valueString;
	}
					
	[context lock];

	NS_DURING
		[bookObject setValue:[value retain] forKey:key];
	NS_HANDLER
		NS_DURING
			BooksAppDelegate * delegate = [[NSApplication sharedApplication] delegate];
			
			NSMutableSet * userFields = [bookObject mutableSetValueForKey:@"userFields"];
	
			NSManagedObjectModel * model = [delegate managedObjectModel];
			NSEntityDescription * fieldDesc = [[model entitiesByName] objectForKey:@"UserDefinedField"];
			NSManagedObject * fieldObject = [[NSManagedObject alloc] initWithEntity:fieldDesc insertIntoManagedObjectContext:context];

			[fieldObject setValue:key forKey:@"key"];
			[fieldObject setValue:value forKey:@"value"];
	
			[userFields addObject:fieldObject];
			
			[fieldObject release];
		NS_HANDLER
			NSLog (@"%@", [localException reason]);
		NS_ENDHANDLER
	NS_ENDHANDLER
	
	[context unlock];
}

@end
