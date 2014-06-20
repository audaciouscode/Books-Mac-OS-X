//
//  GalleryView.h
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BookManagedObject.h"
#import "GalleryViewControls.h"

@interface GalleryView : NSView 
{
	IBOutlet NSArrayController * bookList;
	IBOutlet NSArrayController * listList;
	IBOutlet GalleryViewControls * controls;

	int rowCount;
	int colCount;
	
	float gallerySize;
	
	NSArray * arrangedBooks;
	
	BOOL inited;
}

- (BOOL) isSelected:(BookManagedObject *) book;
- (void) setSelectedView:(NSView *) v;
- (NSArrayController *) listController;
@end
