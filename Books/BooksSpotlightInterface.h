//
//  BooksSpotlightInterface.h
//  Books
//
//  Created by Chris Karr on 7/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BooksSpotlightInterface : NSObject 
{
	IBOutlet NSObject * booksAppDelegate;
	
	IBOutlet NSArrayController * collectionArrayController;
	IBOutlet NSArrayController * bookArrayController;
}

- (void) loadDataFromOutside:(NSData *) data;
- (IBAction) updateSpotlightIndex: (id) sender;
- (IBAction) clearSpotlightIndex: (id) sender;
- (BOOL) openFile:(NSString *) filename;

@end
