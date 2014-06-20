#import "AmazonResultsDataSource.h"

@implementation AmazonResultsDataSource

- (AmazonResultsDataSource *) init
{
	hits = [[NSMutableArray array] retain];
	
	return self;
}

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
	return [hits count];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) index;
{
	NSDictionary * hit = [self getHitAtIndex:index];

	return [hit objectForKey:[[aTableColumn identifier] lowercaseString]];
}

- (void) clearHits;
{
	[hits release];
	hits = [[NSMutableArray array] retain];
}

- (NSDictionary *) getHitAtIndex:(int) index;
{
	NSDictionary * hit = (NSDictionary *) [hits objectAtIndex:index];

	return hit;
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


			NSArray * fields = [book elementsForName:@"field"];
			
			for (k = 0; k < [fields count]; k++)
			{
				NSXMLElement * bookField = [fields objectAtIndex:k];

				NSXMLNode * nameAttribute = [bookField attributeForName:@"name"];
					
				[bookDict setValue:[bookField stringValue] forKey:[nameAttribute stringValue]];
			}

			[bookDict setValue:book forKey:@"xmldata"];

			[hits addObject:bookDict];
		}
	}
}

@end
