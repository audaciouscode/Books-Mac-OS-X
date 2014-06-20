//
//  BookListArrayController.h
//  Books
//
//  Created by Chris Karr on 10/7/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BookListArrayController : NSArrayController 
{
	NSIndexSet * selectedRows;
	IBOutlet NSArrayController * listController;
}

// - (BOOL)tableView:(NSTableView *) tv writeRows:(NSArray*) rows toPasteboard:(NSPasteboard*) pboard;
// - (void) pasteboard:(NSPasteboard *) pboard provideDataForType:(NSString *) type;

@end
