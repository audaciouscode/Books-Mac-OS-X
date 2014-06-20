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


#import "BookManagedObject.h"
#import "SmartList.h"
#import "BooksAppDelegate.h"
#import "BookTitleString.h"
#import "BookAuthorString.h"

@implementation BookManagedObject

- (void) didChangeValueForKey: (NSString *) key
{
	[super didChangeValueForKey:key];
	
	[[NSApp delegate] updateMainPane];
}

- (void) setIsbn: (NSString *) isbn
{
    [self willChangeValueForKey:@"isbn"];

	if ([isbn length] > 10)
	{
		NSMutableString * isbnTemp = [NSMutableString stringWithString:isbn];

		[isbnTemp replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch 
				range:NSMakeRange (0, [isbnTemp length])];

		[isbnTemp replaceOccurrencesOfString:@"-" withString:@"" options:NSCaseInsensitiveSearch 
				range:NSMakeRange (0, [isbnTemp length])];

		if ([isbnTemp length] < 12)
			[self setPrimitiveValue:isbn forKey:@"isbn"];
		else
		{
			NSMutableString * translatedUpc = [NSMutableString stringWithString:@""];
	
			NSArray * upcPrefixes = [NSArray arrayWithObjects: @"014794", @"018926", @"027778", @"037145", 
										@"042799", @"043144", @"044903", @"045863", @"046594", @"047132",
										@"051487", @"051488", @"060771", @"065373", @"070992", @"070993",
										@"070999", @"071001", @"071009", @"071125", @"071136", @"071149",
										@"071152", @"071162", @"071268", @"071831", @"071842", @"072742", 
										@"076714", @"076783", @"076814", @"078021", @"079808", @"090129",
										@"099455", @"099769", nil];
									
			NSArray * isbnPrefixes = [NSArray arrayWithObjects: @"08041", @"0445", @"0449", @"0812", @"0785",
										@"0688", @"0312", @"0517", @"0064", @"0152", @"08167", @"0140", 
										@"0002", @"0373", @"0523", @"0446", @"0345", @"0380", @"0440",
										@"088677", @"0451", @"0451", @"0515", @"0451", @"08217", @"170425",
										@"08439", @"0441", @"0671", @"0553", @"0449", @"0872", @"0394",
										@"0679", @"0061", @"0451", nil];
		
			if ([isbnTemp length] > 10)
			{
				NSRange range = [isbnTemp rangeOfString:@"978"];
            
				if (range.location == 0)
					[translatedUpc appendString:[isbnTemp substringWithRange:NSMakeRange (3, 9)]];
				else
				{
					int i = 0;
					for (i = 0; i < [upcPrefixes count]; i++)
					{
						NSString * prefix = (NSString *) [upcPrefixes objectAtIndex:i];
				
						NSRange prefixRange = [isbnTemp rangeOfString:prefix];
				
						if (prefixRange.location == 0)
						{
							NSString * isbnPrefix = (NSString *) [isbnPrefixes objectAtIndex:i];
					
							[translatedUpc appendString:isbnPrefix];
						}
					}
			
					int prefixLength = [translatedUpc length];

					if (prefixLength > 0)
						[translatedUpc appendString:[isbnTemp substringFromIndex:([isbnTemp length] - 9 + prefixLength)]];
					else
					{
						[self setPrimitiveValue:isbn forKey:@"isbn"];
						[self didChangeValueForKey:@"isbn"];
					
						return;
					}
				}
			}
		
			int xsum = 0;
			int i = 0;
				
			for (i = 0; i < 9; i++)
			{
				int add = [[translatedUpc substringWithRange:NSMakeRange (i, 1)] intValue];
				xsum = xsum + ((10 - i) * add);
			}
                
			xsum = xsum % 11;
			xsum = 11 - xsum;
                
			if (xsum == 10)
				[translatedUpc appendString:@"X"];
			else if (xsum == 11)
				[translatedUpc appendString:@"0"];
			else
				[translatedUpc appendString:[[NSNumber numberWithInt:xsum] stringValue]];
	
			[self setPrimitiveValue:translatedUpc forKey:@"isbn"];
		}
	}
	else
		[self setPrimitiveValue:isbn forKey:@"isbn"];
	
    [self didChangeValueForKey:@"isbn"];
}

- (void) setList: (ListManagedObject *) newList
{
	if ([newList isKindOfClass:[SmartList class]] || newList == nil || [[self valueForKey:@"list"] isEqual:newList])
		return;
		
	[self willChangeValueForKey:@"list"];	
	[self setPrimitiveValue:newList forKey:@"list"];
	[self didChangeValueForKey:@"list"];
}

- (NSString *) getTitle
{
    [self willAccessValueForKey:@"title"];
	NSString * title = [self primitiveValueForKey:@"title"];
    [self didAccessValueForKey:@"title"];

//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Snappy"])
		return [BookTitleString stringWithString:title];
//	else
//		return title;
}

- (NSString *) getAuthors
{
	[self willAccessValueForKey:@"authors"];
	NSString * authorString = [self primitiveValueForKey:@"authors"];
	[self didAccessValueForKey:@"authors"];

//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Snappy"])
		 return [BookAuthorString stringWithString:authorString];
//	else
//		return authorString;
}

- (NSString *) getIllustrators
{
    [self willAccessValueForKey:@"illustrators"];
	NSString * illustrators = [self primitiveValueForKey:@"illustrators"];
    [self didAccessValueForKey:@"illustrators"];

//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Snappy"])
		return [BookAuthorString stringWithString:illustrators];
//	else
//		return illustrators;
}

- (NSString *) getTranslators
{
    [self willAccessValueForKey:@"translators"];
	NSString * translators = [self primitiveValueForKey:@"translators"];
    [self didAccessValueForKey:@"translators"];
	
//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Snappy"])
		return [BookAuthorString stringWithString:translators];
//	else
//		return translators;
}

- (NSString *) getEditors
{
    [self willAccessValueForKey:@"editors"];
	NSString * editors = [self primitiveValueForKey:@"editors"];
    [self didAccessValueForKey:@"editors"];

//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Snappy"])
		return [BookAuthorString stringWithString:editors];
//	else
//		return editors;
}

- (NSString *) getListName
{
	ListManagedObject * list = [self valueForKey:@"list"];

	NSString * listName = [list valueForKey:@"name"];
	
	return listName;
}

- (void) setListName: (NSString *) listName
{

}

- (NSString *) getId
{
	[self willAccessValueForKey:@"id"];
	if ([self primitiveValueForKey:@"id"] == nil)
		[self getObjectIdString];
	[self didAccessValueForKey:@"id"];
		
	return [self primitiveValueForKey:@"id"];
}

- (NSString *) getObjectIdString
{
	[self willAccessValueForKey:@"id"];
	NSString * objId = [self primitiveValueForKey:@"id"];
	[self didAccessValueForKey:@"id"];
	
	if (objId == nil || [objId isEqualToString:@""])
	{
		CFUUIDRef uuid = CFUUIDCreate (kCFAllocatorDefault);
		NSString * uuidString = (NSString *) CFUUIDCreateString (kCFAllocatorDefault, uuid);
		
		[self setValue:uuidString forKey:@"id"];
		
		return [self valueForKey:@"id"];
	}
	
	return objId;
}

- (NSData *) getCoverImage
{
//	if (imageData == nil)
//	{
		NSString * objId = [self valueForKey:@"id"];
		
		NSString * imagePath = [NSString stringWithFormat:@"%@%@%@.book-image", NSHomeDirectory (),
							@"/Library/Application Support/Books/Images/", objId];

		if (imagePath != nil)
			imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
//	}
	
	return [imageData retain];
}

- (void) setCoverImage: (NSData *) data
{
    [self willChangeValueForKey:@"coverImage"];
	
	NSString * objId = [self getObjectIdString];
		
	NSString * imagePath = [NSString stringWithFormat:@"%@%@%@.book-image", NSHomeDirectory (),
							@"/Library/Application Support/Books/Images/", objId];

	if (![[NSFileManager defaultManager] fileExistsAtPath:[imagePath stringByDeletingLastPathComponent]])
		[[NSFileManager defaultManager] createDirectoryAtPath:[imagePath stringByDeletingLastPathComponent] attributes:nil];
	
	if ([data length] > 0)
		[[NSFileManager defaultManager] createFileAtPath:imagePath contents:data attributes:nil];
	else
		[[NSFileManager defaultManager] removeFileAtPath:imagePath handler:nil];

	if (imageData != nil)
	 	[imageData release];
		
	imageData = nil;
	
    [self didChangeValueForKey:@"coverImage"];
}

- (NSScriptObjectSpecifier *) objectSpecifier
{
	ListManagedObject * list = [self valueForKey:@"list"];
	
	NSIndexSpecifier * specifier = [[NSIndexSpecifier alloc] initWithContainerClassDescription:
		(NSScriptClassDescription *) [list classDescription] containerSpecifier: [list objectSpecifier] key:@"items"];

   [specifier setIndex:[[list getBooks] indexOfObject:self]];

	return [specifier autorelease];
}

- (NSString *) description
{
	return [self valueForKey:@"title"];
}

- (NSArray *) getSecondaryFields:(NSString *) fieldName fromSet:(NSString *) setName
{
	NSSet * set = [super valueForKey:setName];

	if (set != nil)
	{
		NSMutableArray * fields = [[NSMutableArray alloc] init];
	
		NSArray * setArray = [set allObjects];
		
		int i = 0;
		for (i = 0; i < [setArray count]; i++)
		{
			NSManagedObject * item = [setArray objectAtIndex:i];
			
			NSObject * value = [item valueForKey:fieldName];

			if (value == nil)
				value = @"";

			[fields addObject:value];
		}
		
		return fields;
	}
	else
		return nil;
}


- (NSString *) getSecondaryField:(NSString *) fieldName fromSet:(NSString *) setName
{
	NSSet * set = [super valueForKey:setName];

	if (set != nil)
	{
		NSArray * setArray = [set allObjects];
		
		NSMutableString * valueString = [[NSMutableString alloc] initWithString:@""];
		
		int i = 0;
		for (i = 0; i < [setArray count]; i++)
		{
			NSManagedObject * item = [setArray objectAtIndex:i];
			
			NSString * value = [item valueForKey:fieldName];
			
			if ([value isKindOfClass:[NSDate class]])
				return value;

			if (value != nil)
			{
				if (![valueString isEqual:@""])
					[valueString appendString:@"; "];
				
				[valueString appendString:value];
			}
		}
		
		if ([valueString isEqualToString:@""])
			return nil;
		
		return valueString;
	}
	else
		return nil;
}

- (NSString *) getLocation
{
	return [self getSecondaryField:@"location" fromSet:@"copies"];
}

- (void) setLocation:(NSString *) value
{

}

- (NSString *) getRating
{
	return [self getSecondaryField:@"rating" fromSet:@"feedback"];
}

- (void) setRating:(NSString *) value
{

}

- (NSString *) getCondition
{
	return [self getSecondaryField:@"condition" fromSet:@"copies"];
}

- (void) setCondition:(NSString *) value
{

}

- (NSString *) getSource
{
	return [self getSecondaryField:@"source" fromSet:@"copies"];
}

- (void) setSource:(NSString *) value
{

}

- (NSString *) getOwner
{
	return [self getSecondaryField:@"owner" fromSet:@"copies"];
}

- (void) setOwner:(NSString *) value
{

}


- (NSString *) getCurrentValue
{
	return [self getSecondaryField:@"presentValue" fromSet:@"copies"];
}

- (void) setCurrentValue:(NSString *) value
{

}

- (NSArray *) getCheckOutsArray
{
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSString * dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:@"Custom Date Format"];

	if (dateFormat != nil)
		formatter = [[NSDateFormatter alloc] initWithDateFormat:dateFormat allowNaturalLanguage:NO];
	else
	{
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateStyle:NSDateFormatterLongStyle];
	}

	NSArray * borrowers = [self getSecondaryFields:@"borrower" fromSet:@"copiesOut"];
	NSArray * copies = [self getSecondaryFields:@"copyLent" fromSet:@"copiesOut"];
	NSArray * datesLent = [self getSecondaryFields:@"dateLent" fromSet:@"copiesOut"];
	NSArray * datesDue = [self getSecondaryFields:@"dateDue" fromSet:@"copiesOut"];

	NSMutableArray * records = [[NSMutableArray array] retain];

	int i = 0;
	for (i = 0; i < [borrowers count]; i++)
	{
		NSMutableDictionary * record = [NSMutableDictionary dictionary];
		
		[record setValue:[borrowers objectAtIndex:i] forKey:@"borrower"];
		[record setValue:[copies objectAtIndex:i] forKey:@"copy"];
		[record setValue:[datesLent objectAtIndex:i] forKey:@"dateLent"];
		[record setValue:[datesDue objectAtIndex:i] forKey:@"dateDue"];

		[records addObject:record];
	}

	NSSortDescriptor * lastNameDescriptor=[[[NSSortDescriptor alloc] initWithKey:@"dateLent" ascending:NO] autorelease];
	NSArray * sortDescriptors=[NSArray arrayWithObject:lastNameDescriptor];

	[records sortUsingDescriptors:sortDescriptors];
	
	return records;
}

- (NSString *) getBorrower
{
	NSArray * records = [self getCheckOutsArray];

	NSMutableString * string = [[NSMutableString alloc] init];
	
	int i = 0;
	for (i = 0; i < [records count]; i++)
	{
		NSDictionary * record = (NSDictionary *) [records objectAtIndex:i];
		[string appendString:[record valueForKey:@"borrower"]];
		[string appendString:@": "];
		[string appendString:[record valueForKey:@"copy"]];

		[string appendString:@" ("];

		if (![[record valueForKey:@"dateLent"] isEqual:@""])
			[string appendString:[formatter stringFromDate:[record valueForKey:@"dateLent"]]];
		else 
			[string appendString:@"Unknown Lent Date"];

		[string appendString:@" - "];
			
		if (![[record valueForKey:@"dateDue"] isEqual:@""])
			[string appendString:[formatter stringFromDate:[record valueForKey:@"dateDue"]]];
		else 
			[string appendString:@"Unknown Due Date"];

		[string appendString:@")"];

		[string appendString:@"; "];
	}

	[records release];
	
	return string;
}

- (void) setBorrower:(NSString *) value
{

}

- (NSString *) getLastBorrower
{
	NSArray * records = [self getCheckOutsArray];

	if ([records count] > 0)
		return ((NSString *) [[records objectAtIndex:0] valueForKey:@"borrower"]);
		
	return nil;
}

- (void) setLastBorrower: (NSString *) value
{

}

- (NSDate *) getLastDateLent
{
	NSArray * records = [self getCheckOutsArray];

	if ([records count] > 0)
		if (![[[records objectAtIndex:0] valueForKey:@"dateLent"] isEqual:@""])
			return ((NSDate *) [[records objectAtIndex:0] valueForKey:@"dateLent"]);
		
	return nil;
}

- (NSDate *) getLastDateDue
{
	NSMutableArray * records = (NSMutableArray *) [self getCheckOutsArray];

	if ([records count] > 0)
		if (![[[records objectAtIndex:0] valueForKey:@"dateDue"] isEqual:@""])
			return ((NSDate *) [[records objectAtIndex:0] valueForKey:@"dateDue"]);
		
	return nil;
}


- (void) writeSpotlightFile
{
	NSArray * keys = [[[self entity] attributesByName] allKeys];
	NSMutableDictionary * bookInfo = [NSMutableDictionary dictionary];
	
	int i = 0;
	for (i = 0; i < [keys count]; i++)
	{
		NSString * key = [keys objectAtIndex:i];
		
		[bookInfo setValue:[self valueForKey:key] forKey:key];
	}
	
	NSString * plistPath = [NSString stringWithFormat:@"%@%@%@.BooksItem", NSHomeDirectory (),
						@"/Library/Caches/Metadata/Books/", [self getObjectIdString]];

	if (![[NSFileManager defaultManager] fileExistsAtPath:[plistPath stringByDeletingLastPathComponent]])
		[[NSFileManager defaultManager] createDirectoryAtPath:[plistPath stringByDeletingLastPathComponent] attributes:nil];
		
	NSString * error = nil;
	
	NSData * plistData = [NSPropertyListSerialization dataFromPropertyList:bookInfo
		format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
	
	[[NSFileManager defaultManager] createFileAtPath:plistPath contents:plistData attributes:nil];
}

- (NSObject *) valueForKey:(NSString *) key
{
	NSObject * value = nil;
	
	NS_DURING
		value = [super valueForKey:key];
	NS_HANDLER
		value = [self customValueForKey:key];
	NS_ENDHANDLER

	return value;
}

- (NSDate *) getDateLent
{
	return [self getLastDateLent];
}

- (void) setDateLent
{

}

- (NSDate *) getDateDue
{
//	return (NSDate *) [self getSecondaryField:@"dateDue" fromSet:@"copiesOut"];
	return [self getLastDateDue];
}

- (void) setDateDue
{

}

- (NSDate *) getDateAcquired
{
	return (NSDate *) [self getSecondaryField:@"dateAcquired" fromSet:@"copies"];
}

- (void) setDateAcquired
{

}

- (NSDate *) getDateFinished
{
	return (NSDate *) [self getSecondaryField:@"dateFinished" fromSet:@"feedback"];
}

- (void) setDateFinished
{

}

- (NSDate *) getDateStarted
{
	return (NSDate *) [self getSecondaryField:@"dateStarted" fromSet:@"feedback"];
}

- (void) setDateStarted
{

}

- (NSObject *) customValueForKey:(NSString *) key
{
	if ([key isEqualToString:@"authors"] || [key isEqualToString:@"illustrators"] || [key isEqualToString:@"editors"] ||
		[key isEqualToString:@"publishers"] || [key isEqualToString:@"genre"])
		return nil;
		
	NSSet * userFieldSet = (NSSet *) [self valueForKey:@"userFields"];
	NSArray * userFieldArray = [userFieldSet allObjects];
	
	int j = 0;		
	for (j = 0; j < [userFieldArray count]; j++)
	{
		NSManagedObject * fieldPair = [userFieldArray objectAtIndex:j];
				
		NSString * name = [[fieldPair valueForKey:@"key"] description];
		
		if ([name isEqualToString:key])
		{
			NSObject * value = [fieldPair valueForKey:@"value"];

			return value;
		}
	}

	return nil;
}

- (void) archiveFileSet
{
	if (fileSet == nil)
		return;
		
	NSString * objId = [self getObjectIdString];

	NSString * filePath = [NSString stringWithFormat:@"%@%@%@/", NSHomeDirectory (),
								@"/Library/Application Support/Books/Files/", objId, nil];

	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
		[[NSFileManager defaultManager] createDirectoryAtPath:filePath attributes:nil];

	if (![NSArchiver archiveRootObject:fileSet toFile:[filePath stringByAppendingString:@"manifest"]])
	{
		// Error message
	}
}

- (void) addNewFile: (NSString *) location title: (NSString *) title description: (NSString *) description
{
    [self willChangeValueForKey:@"files"];

	if (fileSet == nil)
		[self getFiles];

	NSString * filePath = [NSString stringWithFormat:@"%@%@%@/", NSHomeDirectory (),
								@"/Library/Application Support/Books/Files/", [self getObjectIdString], nil];

	NSMutableDictionary * entry = [NSMutableDictionary dictionary];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Copy Files"])
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:location])
			[[NSFileManager defaultManager] copyPath:location 
				toPath:[filePath stringByAppendingPathComponent:[location lastPathComponent]] handler:nil];
		else
			return;

		[entry setValue:[location lastPathComponent] forKey:@"Location"];
	}
	else
		[entry setValue:location forKey:@"Location"];

	[entry setValue:title forKey:@"Title"];
	[entry setValue:description forKey:@"Description"];
	[entry setValue:[[NSWorkspace sharedWorkspace] 
		iconForFile:[filePath stringByAppendingPathComponent:[entry valueForKey:@"Location"]]] forKey:@"Icon"];

	[fileSet addObject:entry];

	[self archiveFileSet];

    [self didChangeValueForKey:@"files"];
}

- (void) removeFile: (NSDictionary *) entry
{
    [self willChangeValueForKey:@"files"];

	if (fileSet == nil)
		[self getFiles];

	NSString * filePath = [NSString stringWithFormat:@"%@%@%@/", NSHomeDirectory (),
								@"/Library/Application Support/Books/Files/", [self getObjectIdString], nil];

	int count = 0;
	
	NSArray * objects = [fileSet allObjects];
	
	NSObject * selectedItem = nil;
	
	int i = 0;
	for (i = 0; i < [objects count]; i++)
	{
		NSDictionary * fileEntry = [objects objectAtIndex:i];
		
		if ([[fileEntry valueForKey:@"Location"] isEqualTo:[entry valueForKey:@"Location"]])
		{
			count++;

			selectedItem = fileEntry;
		}
	}
	
	if (count <= 1)
		[[NSFileManager defaultManager] 
			removeFileAtPath:[filePath stringByAppendingPathComponent:[entry valueForKey:@"Location"]] handler:nil];
	
	if (selectedItem != nil)
		[fileSet removeObject:selectedItem];
	
	[self archiveFileSet];

    [self didChangeValueForKey:@"files"];
}

- (NSSet *) getFiles
{
	NSString * objId = [self getObjectIdString];

	NSString * filePath = [NSString stringWithFormat:@"%@%@%@/", NSHomeDirectory (),
							@"/Library/Application Support/Books/Files/", objId, nil];

	if (fileSet == nil)
	{
		if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
			[[NSFileManager defaultManager] createDirectoryAtPath:filePath attributes:nil];
		else
			fileSet = [[NSMutableSet setWithSet:[NSUnarchiver unarchiveObjectWithFile:[filePath stringByAppendingString:@"manifest"]]] retain];
		
		if (fileSet == nil)
			fileSet = [[NSMutableSet alloc] init];
	}
	
	NSArray * allObjects = [fileSet allObjects];
	
	int i = 0;
	for (i = 0; i < [allObjects count]; i++)
	{
		NSMutableDictionary * file = [allObjects objectAtIndex:i];

		NSImage * icon = [[NSWorkspace sharedWorkspace] iconForFile:[file valueForKey:@"Location"]];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:[file valueForKey:@"Location"]])
			icon = [[NSWorkspace sharedWorkspace] iconForFile:[filePath stringByAppendingPathComponent:[file valueForKey:@"Location"]]];
			
		[file setValue:icon forKey:@"Icon"];
	}
	
	return fileSet;
}

- (void) setFiles:(NSSet *) newFileSet
{
    [self willChangeValueForKey:@"files"];

	[fileSet release];

	fileSet = [NSMutableSet setWithSet:newFileSet];

	[self archiveFileSet];
	
    [self didChangeValueForKey:@"files"];
}

- (void) setValueFromString:(NSString *) valueString forKey:(NSString *) key replace:(BOOL) doReplace
{
	BookManagedObject * bookObject = self;
	
	NSObject * value = nil;

	NS_DURING
		value = [bookObject valueForKey:key];
	NS_HANDLER
		value = @"";
	NS_ENDHANDLER

	if ([[key lowercaseString] isEqual:@"isbn"])
		key = @"isbn";
	
	if ([key isEqual:@"title"])
	{
		if (!(value == nil || [value isEqual:NSLocalizedString (@"New Book", nil)] || [value isEqual:@""] || doReplace == YES))
			return;
	}
	else if (value != nil && ![value isEqual:@""] && doReplace == NO) 
		return;

	NSManagedObjectContext * context = [bookObject managedObjectContext];
	
	if ([key isEqual:@"CoverImageURL"] || [key isEqual:@"coverImage"])
	{
		NSMutableString * mutableString = [NSMutableString stringWithString:valueString];

		if ([[valueString substringToIndex:1] isEqualToString:@"/"])
			mutableString = [NSMutableString stringWithFormat:@"file://%@", valueString, nil];
		
		[mutableString replaceOccurrencesOfString:@" " withString:@"%20" options:nil range:NSMakeRange (0, [mutableString length])];
		
		key = @"coverImage";

		value = (NSData *) [[NSData dataWithContentsOfURL:[NSURL URLWithString:mutableString]] retain];		
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
		value = [NSMutableString stringWithString:valueString];
		[(NSMutableString *) value replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch 
			range:NSMakeRange(0, [(NSMutableString *) value length])];
	}
	else
	{
		value = valueString;
	}
					
	if (value == nil || key == nil)
	{
		return;
	}
	
	[context lock];

	NS_DURING
		[bookObject setValue:value forKey:key];
	NS_HANDLER
		NS_DURING
			BooksAppDelegate * delegate = [[NSApplication sharedApplication] delegate];
			
			NSMutableSet * userFields = [bookObject mutableSetValueForKey:@"userFields"];

			BOOL hasField = NO;
			
			NSArray * objects = [userFields allObjects];
			
			int i = 0;
			
			for (i = 0; i < [objects count] && hasField == NO; i++)
			{
				NSManagedObject * field = [objects objectAtIndex:i];
				
				if ([((NSString *) [field valueForKey:@"key"]) isEqualToString:key])
					hasField = YES;
			}

			if (hasField == NO)
			{
				NSManagedObjectModel * model = [delegate managedObjectModel];
				NSEntityDescription * fieldDesc = [[model entitiesByName] objectForKey:@"UserDefinedField"];
				NSManagedObject * fieldObject = [[NSManagedObject alloc] initWithEntity:fieldDesc insertIntoManagedObjectContext:context];

				[fieldObject setValue:key forKey:@"key"];
				[fieldObject setValue:value forKey:@"value"];
			
				[userFields addObject:fieldObject];
			}
			
		NS_HANDLER
			NSLog (@"%@", [localException reason]);
		NS_ENDHANDLER
	NS_ENDHANDLER
	
	[context unlock];
}


@end
