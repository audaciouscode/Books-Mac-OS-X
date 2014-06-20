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

- (void) addXMLContents:(NSXMLDocument *) xml
{
	NSXMLElement * root = [xml rootElement];

	NSArray * collectionList = [root elementsForName:@"List"];
	
	int i = 0;

	for (i = 0; i < [collectionList count]; i++)
	{
		NSXMLElement * list = [collectionList objectAtIndex:i];

		NSArray * bookList = [list elementsForName:@"Book"];

		int j = 0;
		
		for (j = 0; j < [bookList count]; j++)
		{
			NSXMLElement * book = [bookList objectAtIndex:j];
			NSMutableDictionary * bookDict = [NSMutableDictionary dictionary];
			
			NSArray * bookAttributes = [book attributes];

			int k = 0;
			
			for (k = 0; k < [bookAttributes count]; k++)
			{
				NSXMLNode * bookAttribute = [bookAttributes objectAtIndex:k];
				[bookDict setValue:[bookAttribute stringValue] forKey:[bookAttribute name]];
			}

			NSArray * fieldList = [book elementsForName:@"field"];

			for (k = 0; k < [fieldList count]; k++)
			{
				NSXMLElement * field = [fieldList objectAtIndex:k];
				NSString * name = [[field attributeForName:@"name"] stringValue];
				[bookDict setValue:[field stringValue] forKey:name];
			}

			[bookDict setValue:book forKey:@"xmldata"];

			[hits addObject:bookDict];
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
