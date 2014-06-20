//
//  ListListArrayController.h
//  Books
//
//  Created by Chris Karr on 10/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ListListArrayController : NSArrayController 
{

}

- (NSDragOperation) tableView:(NSTableView*) tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row
	proposedDropOperation:(NSTableViewDropOperation) op;
- (BOOL) tableView:(NSTableView *) tableView acceptDrop:(id <NSDraggingInfo>) info row:(int) row 
	dropOperation:(NSTableViewDropOperation) operation;
- (int) numberOfRowsInTableView: (NSTableView *) aTableView;

@end
