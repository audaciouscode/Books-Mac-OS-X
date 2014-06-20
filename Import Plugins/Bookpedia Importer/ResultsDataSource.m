#import "ResultsDataSource.h"

@implementation ResultsDataSource

- (ResultsDataSource *) init
{
	hits = [[NSMutableArray alloc] init];
	
	return self;
}

- (void) clearHits
{
	[hits release];
	hits = [[NSMutableArray array] retain];
}

- (void) addContents:(NSDictionary *) contents
{
	NSMutableDictionary * mapping = [NSMutableDictionary dictionary];
	
	[mapping setValue:@"format" forKey:@"Format"];
	[mapping setValue:@"authors" forKey:@"Author"];
	[mapping setValue:@"title" forKey:@"Title"];
	[mapping setValue:@"genre" forKey:@"Genre"];
	[mapping setValue:@"edition" forKey:@"Edition"];
	[mapping setValue:@"editors" forKey:@"Editor"];
	[mapping setValue:@"illustrators" forKey:@"Illustrator"];
	[mapping setValue:@"translators" forKey:@"Translator"];
	[mapping setValue:@"length" forKey:@"Pages"];
	[mapping setValue:@"publishDate" forKey:@"Release"];
	[mapping setValue:@"publisher" forKey:@"Publisher"];
	[mapping setValue:@"keywords" forKey:@"Subjects"];
	[mapping setValue:@"summary" forKey:@"Summary"];
	[mapping setValue:@"publishPlace" forKey:@"PlacePublished"];
	[mapping setValue:@"isbn" forKey:@"ISBN"];
	
	NSDictionary * books = [contents valueForKey:@"Tracks"];

	if (books != nil)
	{
		NSArray * bookKeys = [books allKeys];
		
		int i = 0;
		
		for (i = 0; i < [bookKeys count]; i++)
		{
			NSDictionary * book = [books valueForKey:[bookKeys objectAtIndex:i]];
			
			if (book != nil)
			{
				NSMutableDictionary * bookDict = [NSMutableDictionary dictionary];

				NSArray * keys = [book allKeys];
				
				int j = 0;
				
				for (j = 0; j < [keys count]; j++)
				{
					NSString * key = [keys objectAtIndex:j];
					NSString * value = [[book valueForKey:key] description];
					
					NSString * realKey = [mapping valueForKey:key];
					
					if (realKey == nil)
						realKey = key;
						
					if (![realKey isEqualToString:@"SimiliarProducts"])
						[bookDict setValue:value forKey:realKey];
				}
				
				[hits addObject:bookDict];
			}
		}
	}
}

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
	return [hits count];
}

- (NSDictionary *) getHitAtIndex:(int) index
{
	return [hits objectAtIndex:index];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
{
	NSDictionary * hit = [self getHitAtIndex:rowIndex];
	
	NSString * fieldName = [[aTableColumn identifier] lowercaseString];

	return [NSString stringWithFormat:@"%d. %@", (rowIndex + 1), [hit objectForKey:fieldName]];
}

@end