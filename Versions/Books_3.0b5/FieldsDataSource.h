//
//  PrefsFieldsTableDataSource.h
//  Books
//
//  Created by Chris Karr on 9/27/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FieldsDataSource : NSObject 
{
	NSMutableArray * fields;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

- (NSMutableArray *) getFields;

@end
