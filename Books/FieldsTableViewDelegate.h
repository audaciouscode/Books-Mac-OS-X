//
//  FieldsTableViewDelegate.h
//  Books
//
//  Created by Chris Karr on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BooksTableViewDelegate.h"

@interface FieldsTableViewDelegate : NSObject 
{
	NSMutableArray * listFields;
	NSMutableArray * bookFields;

	IBOutlet NSTableView * listFieldsTable;
	IBOutlet NSTableView * bookFieldsTable;

	IBOutlet BooksTableViewDelegate * tableViewDelegate;

	BOOL inited;
}

- (void) setup;

@end
