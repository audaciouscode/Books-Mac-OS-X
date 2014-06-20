//
//  TableDataSource.m
//  Tab-Delimited Text Importer
//
//  Created by Chris Karr on 3/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "TableDataSource.h"

@implementation TableDataSource

- (void) setStringContents: (NSString *) contents
{
	count = 0;
	
	rows = [[NSMutableArray alloc] init];
	
	NSMutableString * tabString = [NSMutableString stringWithString:contents];
	
	[tabString replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [tabString length])];
	[tabString replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [tabString length])];

	NSArray * lines = [tabString componentsSeparatedByString:@"\n"];
	
	int i = 0;
	for (i = 0; i < [lines count]; i++)
	{
		NSString * line = [lines objectAtIndex:i];
		
		NSMutableDictionary * row = [NSMutableDictionary dictionary];
		
		NSArray * columns = [line componentsSeparatedByString:@"\t"];
		
		int j = 0;
		for (j = 0; j < [columns count]; j++)
		{
			NSNumber * index = [NSNumber numberWithInt:j];

			NSString * column = (NSString *) [columns objectAtIndex:j];

			if (column != nil && ![column isEqualToString:@""])
				[row setObject:[columns objectAtIndex:j] forKey:[index description]];
			
			if (count < (j + 1))
				count = j + 1;
		}
		
		if ([[row allKeys] count] > 0)
			[rows addObject:row];
	}
	
	mapping = [[NSMutableDictionary alloc] init];
	
	[mapping setValue:@"title" forKey:@"Title"];
	[mapping setValue:@"series" forKey:@"Series"];
	[mapping setValue:@"genre" forKey:@"Genre"];
	[mapping setValue:@"authors" forKey:@"Authors"];
	[mapping setValue:@"editors" forKey:@"Editors"];
	[mapping setValue:@"illustrators" forKey:@"Illustrators"];
	[mapping setValue:@"translators" forKey:@"Translators"];
	[mapping setValue:@"publisher" forKey:@"Publisher"];
	[mapping setValue:@"publishDate" forKey:@"Publish Date"];
	[mapping setValue:@"isbn" forKey:@"ISBN"];
	[mapping setValue:@"keywords" forKey:@"Keywords"];
	[mapping setValue:@"format" forKey:@"Format"];
	[mapping setValue:@"edition" forKey:@"Edition"];
	[mapping setValue:@"publishPlace" forKey:@"Publish Place"];
	[mapping setValue:@"length" forKey:@"Length"];
}

- (int) getColumnCount
{
	return count;
}

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
	return [rows count];
}

- (id) tableView: (NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) aTableColumn row: (int) rowIndex
{
	NSDictionary * entry = [rows objectAtIndex:rowIndex];
	
	NSString * column = [[aTableColumn identifier] description];

	NSString * mapKey = [mapping objectForKey:column];
	
	if (mapKey != nil)
		column = mapKey;
	
	return [entry objectForKey:column];
}

- (void) replaceKey: (NSObject *) oldKey withKey:(NSObject *) newKey
{
	if ([oldKey isEqual:newKey])
		return;
		
	int i = 0;

	NSString * mapKey = [mapping objectForKey:newKey];
	
	if (mapKey != nil)
		newKey = mapKey;

	for (i = 0; i < [rows count]; i++)
	{
		NSMutableDictionary * entry = [rows objectAtIndex:i];

		NSObject * value = [entry objectForKey:oldKey];
		
		if (value != nil)
		{
			[entry setObject:value forKey:newKey];
			[entry removeObjectForKey:oldKey];
		}
	}
}

- (NSArray *) getRows
{
	return rows;
}

@end
