//
//  TableDataSource.h
//  Tab-Delimited Text Importer
//
//  Created by Chris Karr on 3/22/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TableDataSource : NSObject 
{
	NSMutableArray * rows;
	NSMutableDictionary * mapping;
	
	int count;
}

- (void) setStringContents: (NSString *) contents;
- (int) getColumnCount;

- (int) numberOfRowsInTableView: (NSTableView *) aTableView;
- (id) tableView: (NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *) aTableColumn row: (int) rowIndex;

- (void) replaceKey: (NSObject *) oldKey withKey:(NSObject *) newKey;
- (NSArray *) getRows;

@end
