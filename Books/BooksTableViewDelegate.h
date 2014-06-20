//
//  BooksTableViewDelegate.h
//  Books
//
//  Created by Chris Karr on 7/6/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BooksToolbarDelegate.h"
#import "BooksSpotlightInterface.h"
#import "GalleryView.h"

#define BOOKS_EDIT_LIST_NAME @"Books - Edit List Name"

@interface BooksTableViewDelegate : NSObject 
{
	IBOutlet NSTableView * booksTable;
	IBOutlet NSTableView * listsTable;

	IBOutlet GalleryView * gallery;
	IBOutlet NSScrollView * booksScroll;
	
	IBOutlet NSObject * booksAppDelegate;
	IBOutlet BooksToolbarDelegate * toolbarDelegate;
	IBOutlet BooksSpotlightInterface * spotlightInterface;

	IBOutlet NSArrayController * collectionArrayController;
	IBOutlet NSArrayController * bookArrayController;

	IBOutlet NSTabView * box;
	
	NSString * openFilename;

	NSArray * fieldKeys;
	NSArray * fieldTitles;
	
	IBOutlet NSMenu * booksColumnMenu;
}

- (void) save;
- (void) restore;
- (void) updateBooksTable;
- (void) reloadListsTable;
- (void) reloadBooksTable;

- (NSTableView *) getListsTable;
- (NSTableView *) getBooksTable;

- (void) setOpenFilename:(NSString *) filename;
- (IBAction) toggleColumns: (id) sender;

@end
